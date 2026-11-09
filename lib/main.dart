import 'package:flutter/material.dart';

import 'src/app/task_controller.dart';
import 'src/storage/default_store.dart';
import 'src/ui/app.dart';

const String appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '0.1.0',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = TaskController(store: await createDefaultStore());
  runApp(
    RealLifeRPGApp(
      controller: controller,
      version: appVersion,
      initialPage: 'maceram',
    ),
  );
  await controller.load();
}
