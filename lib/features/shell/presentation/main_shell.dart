import 'package:flutter/material.dart';

import '../../../core/widgets/home_action_button.dart';

import '../../../app/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../advisor/domain/advisor_conversation_store.dart';
import '../../advisor/domain/local_llm_advisor_provider.dart';
import '../../advisor/presentation/screens/advisor_screen.dart';
import '../../advisor/services/advisor_model_manager.dart';
import '../../analysis/presentation/screens/analysis_screen.dart';
import '../../home/presentation/screens/home_screen.dart';
import '../../money/presentation/screens/money_screen.dart';
import '../../settings/presentation/screens/settings_screen.dart';
import '../../transactions/controllers/finance_controller.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.controller, super.key});

  final FinanceController controller;

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  static final GlobalKey<MainShellState> globalKey = GlobalKey<MainShellState>();
  int _selectedIndex = 0;

  final AdvisorConversationStore _advisorConversation =
      AdvisorConversationStore();

  late final AdvisorModelManager _advisorModelManager;
  late final LocalLlmAdvisorProvider _advisorProvider;

  void setTab(int index) => setState(() => _selectedIndex = index);

  @override
  void initState() {
    super.initState();

    _advisorModelManager = AdvisorModelManager();

    _advisorProvider = LocalLlmAdvisorProvider(
      modelManager: _advisorModelManager,
      isEnabled: () => true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.controller.isLoading) {
        widget.controller.load();
      }
    });
  }

  @override
  void dispose() {
    _advisorModelManager.dispose();
    _advisorConversation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _selectedIndex,
      children: [
        HomeScreen(controller: widget.controller),
        MoneyScreen(controller: widget.controller),
        AnalysisScreen(controller: widget.controller),
        AdvisorScreen(
          controller: widget.controller,
          conversationStore: _advisorConversation,
          provider: _advisorProvider,
          modelManager: _advisorModelManager,
        ),
        SettingsScreen(
          controller: widget.controller,
          conversationStore: _advisorConversation,
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: setTab,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Money',
        ),
        NavigationDestination(
          icon: Icon(Icons.pie_chart_outline),
          selectedIcon: Icon(Icons.pie_chart),
          label: 'Analysis',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: 'Advisor',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    ),
  );
}

class FeaturePage extends StatelessWidget {
  const FeaturePage({
    required this.title,
    required this.icon,
    required this.description,
    super.key,
  });

  final String title;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: const [HomeActionButton()],title: Text(title)),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.mint, size: 30),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Foundation screen · no financial data stored yet',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
