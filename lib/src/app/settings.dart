import 'dart:convert';

/// Optional overrides keep a preset as the starting point. Null means the
/// preset's own value; reset never needs to overwrite the seven presets.
class Appearance {
  const Appearance({
    this.primary,
    this.secondary,
    this.background,
    this.surface,
    this.radius,
    this.font = 'system',
    this.compact = false,
    this.reduceMotion = false,
  });
  final int? primary, secondary, background, surface;
  final double? radius;
  final String font;
  final bool compact, reduceMotion;
  Appearance withColor(String slot, int? value) => Appearance(
    primary: slot == 'primary' ? value : primary,
    secondary: slot == 'secondary' ? value : secondary,
    background: slot == 'background' ? value : background,
    surface: slot == 'surface' ? value : surface,
    radius: radius,
    font: font,
    compact: compact,
    reduceMotion: reduceMotion,
  );
  Appearance copyWith({
    double? radius,
    String? font,
    bool? compact,
    bool? reduceMotion,
  }) => Appearance(
    primary: primary,
    secondary: secondary,
    background: background,
    surface: surface,
    radius: radius ?? this.radius,
    font: font ?? this.font,
    compact: compact ?? this.compact,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );
  Map<String, Object?> toJson() => {
    'primary': primary,
    'secondary': secondary,
    'background': background,
    'surface': surface,
    'radius': radius,
    'font': font,
    'compact': compact,
    'reduce_motion': reduceMotion,
  };
  static Appearance decode(Object? raw) {
    if (raw is! Map<String, Object?>) return const Appearance();
    int? color(String key) {
      final value = raw[key];
      return value is int && value >= 0 && value <= 0xffffffff
          ? 0xff000000 | (value & 0xffffff)
          : null;
    }

    final r = raw['radius'];
    return Appearance(
      primary: color('primary'),
      secondary: color('secondary'),
      background: color('background'),
      surface: color('surface'),
      radius: r is num && r.isFinite ? r.toDouble().clamp(4, 32) : null,
      font: ['system', 'serif', 'mono'].contains(raw['font'])
          ? raw['font']! as String
          : 'system',
      compact: raw['compact'] == true,
      reduceMotion: raw['reduce_motion'] == true,
    );
  }
}

/// Choices that belong to this device, kept apart from the tasks.
class AppSettings {
  const AppSettings({
    this.themeId = 'bahce',
    this.gameMode = true,
    this.charClass = 'savasci',
    this.uiScale = 1.0,
    this.appearance = const Appearance(),
  });

  /// One of the ids in `appThemes` (unknown ids fall back to the default).
  final String themeId;

  /// XP, levels, stats and badges on screen. Off shows a plain list.
  final bool gameMode;

  /// Cosmetic character class (emblem and motto only; no rule changes).
  final String charClass;

  /// Whole-interface zoom, independent of the operating system's text size.
  final double uiScale;
  final Appearance appearance;

  static const minScale = 0.8;
  static const maxScale = 2.0;

  double get safeScale =>
      uiScale.isFinite ? uiScale.clamp(minScale, maxScale) : 1.0;

  AppSettings copyWith({
    String? themeId,
    bool? gameMode,
    String? charClass,
    double? uiScale,
    Appearance? appearance,
  }) => AppSettings(
    themeId: themeId ?? this.themeId,
    gameMode: gameMode ?? this.gameMode,
    charClass: charClass ?? this.charClass,
    uiScale: uiScale ?? this.uiScale,
    appearance: appearance ?? this.appearance,
  );

  String encode() => const JsonEncoder.withIndent('  ').convert({
    'theme': themeId,
    'game_mode': gameMode,
    'class': charClass,
    'ui_scale': safeScale,
    'appearance': appearance.toJson(),
  });

  /// Reads settings; anything missing or malformed falls back to defaults
  /// (settings are a convenience, never a reason to refuse to start).
  static AppSettings decode(String text) {
    try {
      final j = jsonDecode(text);
      if (j is! Map<String, Object?>) return const AppSettings();
      return AppSettings(
        themeId: j['theme'] is String ? j['theme']! as String : 'bahce',
        gameMode: j['game_mode'] is bool ? j['game_mode']! as bool : true,
        charClass: j['class'] is String ? j['class']! as String : 'savasci',
        appearance: Appearance.decode(j['appearance']),
        uiScale: j['ui_scale'] is num && (j['ui_scale']! as num).isFinite
            ? (j['ui_scale']! as num).toDouble().clamp(minScale, maxScale)
            : 1.0,
      );
    } on FormatException {
      return const AppSettings();
    }
  }
}
