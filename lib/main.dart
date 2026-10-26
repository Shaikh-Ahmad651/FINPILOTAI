
import 'package:flutter/material.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';

import 'app/app.dart';
import 'features/transactions/controllers/finance_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the on-device AI inference engine.
  try {
    await FlutterEdgeAi.initialize(
      inferenceEngines: const [LiteRtLmEngine()],
    );
  } catch (error) {
    debugPrint('Local AI engine initialization failed: $error');
  }

  // Initialize the finance database.
  final controller = FinanceController();
  try {
    await controller.initializeDatabase();
  } catch (error) {
    controller.setStartupError(error);
  }

  // Launch the app even if local AI initialization fails.
  runApp(FinPilotApp(financeController: controller));
}
