import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../features/shell/presentation/main_shell.dart';

/// A consistent shortcut back to the Home tab from any authenticated page.
class HomeActionButton extends StatelessWidget {
  const HomeActionButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Go to Home',
    icon: const Icon(Icons.home_outlined),
    onPressed: () {
      FocusManager.instance.primaryFocus?.unfocus();

      final navigator = Navigator.of(context);
      navigator.popUntil((route) => route.settings.name == AppRoutes.home);
      MainShellState.globalKey.currentState?.setTab(0);
    },
  );
}
