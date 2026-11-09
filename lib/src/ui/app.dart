import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../app/task_controller.dart';
import 'home_shell.dart';
import 'interface_scale.dart';
import 'themes.dart';

class RealLifeRPGApp extends StatelessWidget {
  const RealLifeRPGApp({
    super.key,
    required this.controller,
    this.version = '',
    this.initialPage = 'gun',
  });

  final TaskController controller;
  final String version;
  final String initialPage;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final appearance = controller.settings.appearance;
      final spec = customizedTheme(
        themeById(controller.settings.themeId),
        appearance,
      );
      return MaterialApp(
        title: 'RealLife RPG',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(spec, appearance: appearance),
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [Locale('tr', 'TR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: spec.gradient.length == 1
                  ? [spec.gradient.first, spec.gradient.first]
                  : spec.gradient,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations:
                  appearance.reduceMotion ||
                  MediaQuery.disableAnimationsOf(context),
            ),
            child: InterfaceScale(
              scale: controller.settings.safeScale,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
        home: HomeShell(
          controller: controller,
          version: version,
          initialPage: initialPage,
        ),
      );
    },
  );
}
