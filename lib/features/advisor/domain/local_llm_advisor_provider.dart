import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai/genai.dart';

import '../services/advisor_model_manager.dart';
import 'advisor_financial_context.dart';
import 'advisor_provider.dart';

class LocalLlmAdvisorProvider implements AdvisorProvider {
  LocalLlmAdvisorProvider({
    required AdvisorModelManager modelManager,
    required this._isEnabled,
    this._fallback = const DeterministicAdvisorProvider(),
  }) : _manager = modelManager;

  final AdvisorModelManager _manager;
  final bool Function() _isEnabled;
  final AdvisorProvider _fallback;

  InferenceModel? _model;

  @override
  String get name => 'Gemma 4 E2B (on-device)';

  @override
  bool get modelAvailable => _manager.isReady;

  @override
  bool get modelEnabled => _isEnabled();

  @override
  Future<String> answer(
    String question,
    AdvisorFinancialContext context,
  ) async {
    if (DeterministicAdvisorProvider.isOutOfScope(question) ||
        !modelAvailable ||
        !modelEnabled) {
      return _fallback.answer(question, context);
    }

    try {
      final response = await _generate(
        question,
        context,
      ).timeout(const Duration(seconds: 90));

      final cleaned = response.trim();

      if (cleaned.isEmpty) {
        return await _fallback.answer(question, context);
      }

      return '$cleaned\n\n'
          'General budgeting guidance, not professional financial advice.';
    } catch (_) {
      return _fallback.answer(question, context);
    }
  }

  Future<String> _generate(
    String question,
    AdvisorFinancialContext context,
  ) async {
    _model ??= await FlutterEdgeAi.getActiveModel(maxTokens: 4096);

    final chat = await _model!.createChat(
      systemInstruction: _systemPrompt(context),
      modelType: ModelType.gemma4,
      temperature: 0.3,
      topK: 40,
      topP: 0.9,
      maxOutputTokens: 300,
    );

    try {
      final reply = await chat.sendMessage(ChatMessage.user(question));
      return reply.text;
    } finally {
      await chat.close();
    }
  }

  static String _systemPrompt(AdvisorFinancialContext c) {
    final b = StringBuffer()
      ..writeln(
        'You are the budgeting assistant inside FinPilotAI, a '
        'personal finance app. Answer only from the facts below. '
        'Never invent figures or claim to have data that is not '
        'provided. If the facts do not cover the question, say '
        'you do not have that data. Do not give investment, loan, '
        'tax, or credit advice. Be friendly and keep the answer '
        'under 120 words. Amounts are in Indian rupees.',
      )
      ..writeln()
      ..writeln('FACTS (${c.periodLabel}):');

    if (c.hasFinancialData) {
      b.writeln('- Current balance: ${_money(c.currentBalancePaise)}');
    }

    if (c.hasCurrentMonthTransactionData) {
      b
        ..writeln('- Income this month: ${_money(c.incomePaise)}')
        ..writeln('- Expenses this month: ${_money(c.expensesPaise)}')
        ..writeln('- Net cash flow: ${_money(c.netCashFlowPaise)}');
    } else {
      b.writeln('- No transactions recorded this month.');
    }

    if (c.hasPreviousMonthExpenseData) {
      b.writeln(
        '- Expenses last month: '
        '${_money(c.previousMonthExpensesPaise)}',
      );
    }

    final categories = c.categoryExpensesPaise.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in categories.take(6)) {
      b.writeln('- Category ${entry.key}: ${_money(entry.value)}');
    }

    for (final budget in c.budgets) {
      b.writeln(
        '- Budget ${budget.category ?? 'Overall'}: spent '
        '${_money(budget.spentPaise)} of '
        '${_money(budget.limitPaise)} '
        '(${budget.isOverLimit ? 'over the limit' : 'within the limit'})',
      );
    }

    for (final bill in c.overdueBills) {
      b.writeln(
        '- Overdue bill: ${bill.title} '
        '${_money(bill.amountPaise)}',
      );
    }

    for (final bill in c.upcomingBills) {
      b.writeln(
        '- Upcoming bill: ${bill.title} '
        '${_money(bill.amountPaise)}',
      );
    }

    if (c.budgets.isEmpty) {
      b.writeln('- No budgets set this month.');
    }

    return b.toString();
  }

  static String _money(int paise) {
    final absolute = paise.abs();
    final sign = paise < 0 ? '-' : '';
    final rupees = absolute ~/ 100;
    final cents = (absolute % 100).toString().padLeft(2, '0');

    return '$sign₹$rupees.$cents';
  }
}
