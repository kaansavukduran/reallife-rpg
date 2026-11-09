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
      final mode = controller.settings.displayMode;
      final dark =
          mode == 'dark' ||
          ((mode == 'system' || mode == 'contrast') &&
              (MediaQuery.maybePlatformBrightnessOf(context) ??
                      WidgetsBinding
                          .instance
                          .platformDispatcher
                          .platformBrightness) ==
                  Brightness.dark);
      final spec = customizedTheme(
        themeById(
          mode == 'preset'
              ? controller.settings.themeId
              : dark
              ? 'gece'
              : 'sade',
        ),
        mode == 'preset'
            ? appearance
            : appearance
                  .withColor('background', null)
                  .withColor('surface', null),
      );
      return MaterialApp(
        title: 'RealLife RPG',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(
          spec,
          appearance: appearance,
          highContrast: mode == 'contrast',
        ),
        locale: controller.settings.languageCode.isEmpty
            ? null
            : Locale(
                controller.settings.languageCode,
                controller.settings.languageCode == 'en' ? 'US' : 'TR',
              ),
        supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
        localeResolutionCallback: (locale, _) => locale?.languageCode == 'en'
            ? const Locale('en', 'US')
            : const Locale('tr', 'TR'),
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
              textScaler: ReadingTextScaler(
                MediaQuery.textScalerOf(context),
                controller.settings.textScale,
              ),
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

/// Compose the reader preference with the OS scaler, preserving nonlinear OS scaling.
class ReadingTextScaler extends TextScaler {
  const ReadingTextScaler(this.system, this.factor);
  final TextScaler system;
  final double factor;
  @override
  double scale(double fontSize) => system.scale(fontSize) * factor;
  @override
  double get textScaleFactor => scale(14) / 14;
}
