import 'package:flutter/material.dart';

import '../features/accounts/presentation/screens/accounts_screen.dart';
import '../features/auth/presentation/screens/lock_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/bills/presentation/screens/bills_screen.dart';
import '../features/budgets/presentation/screens/budgets_screen.dart';
import '../features/shell/presentation/main_shell.dart';
import '../features/transactions/controllers/finance_controller.dart';
import '../features/transactions/presentation/screens/transaction_detail_screen.dart';
import '../features/transactions/presentation/screens/transaction_form_screen.dart';
import '../features/transactions/presentation/screens/transaction_history_screen.dart';
import 'app_theme.dart';
import 'router.dart';

class FinPilotApp extends StatefulWidget {
  const FinPilotApp({super.key, this.financeController});

  final FinanceController? financeController;

  @override
  State<FinPilotApp> createState() => _FinPilotAppState();
}

class _FinPilotAppState extends State<FinPilotApp>
    with WidgetsBindingObserver {
  late final FinanceController _controller =
      widget.financeController ?? FinanceController();
  DateTime? _backgroundedAt;
  static const _relockAfter = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `inactive` also fires while the Face ID sheet is showing, so ignore it.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final at = _backgroundedAt;
      _backgroundedAt = null;
      if (at != null && DateTime.now().difference(at) >= _relockAfter) {
        _controller.lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return MaterialApp(
      title: 'FinPilotAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: controller.localSessionActive
          ? AppRoutes.home
          : AppRoutes.login,
      builder: (context, child) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (controller.isLocked && controller.localSessionActive)
              Positioned.fill(child: LockScreen(controller: controller)),
          ],
        ),
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.transactions:
            return MaterialPageRoute<void>(
              builder: (_) => TransactionHistoryScreen(controller: controller),
            );
          case AppRoutes.newTransaction:
            return MaterialPageRoute<void>(
              builder: (_) => TransactionFormScreen(controller: controller),
            );
          case AppRoutes.editTransaction:
            final id = settings.arguments as String;
            return MaterialPageRoute<void>(
              builder: (_) => TransactionFormScreen(
                controller: controller,
                transactionId: id,
              ),
            );
          case AppRoutes.transactionDetails:
            final id = settings.arguments as String;
            return MaterialPageRoute<void>(
              builder: (_) => TransactionDetailScreen(
                controller: controller,
                transactionId: id,
              ),
            );
          case AppRoutes.accounts:
            return MaterialPageRoute<void>(
              builder: (_) => AccountsScreen(controller: controller),
            );
          case AppRoutes.budgets:
            final month = settings.arguments as DateTime?;
            return MaterialPageRoute<void>(
              builder: (_) =>
                  BudgetsScreen(controller: controller, initialMonth: month),
            );
          case AppRoutes.bills:
            return MaterialPageRoute<void>(
              builder: (_) => BillsScreen(controller: controller),
            );
        }
        return null;
      },
      routes: {
        AppRoutes.login: (_) => LoginScreen(controller: controller),
        AppRoutes.register: (_) => RegisterScreen(controller: controller),
        AppRoutes.home: (_) => MainShell(controller: controller),
      },
    );
  }
}