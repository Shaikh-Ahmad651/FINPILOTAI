import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../transactions/controllers/finance_controller.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({required this.controller, super.key});

  final FinanceController controller;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.controller.unlock();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandMark(),
          const SizedBox(height: 28),
          const Icon(Icons.lock_outline, color: AppColors.mint, size: 36),
          const SizedBox(height: 12),
          const Text('FinPilotAI is locked'),
          if (widget.controller.authError != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.controller.authError!,
              style: const TextStyle(color: AppColors.coral),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _unlock,
            child: const Text('Unlock'),
          ),
        ],
      ),
    ),
  );
}