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
    this.lineHeight = 1,
    this.letterSpacing = 0,
  });
  final int? primary, secondary, background, surface;
  final double? radius;
  final String font;
  final bool compact, reduceMotion;
  final double lineHeight, letterSpacing;
  Appearance withColor(String slot, int? value) => Appearance(
    primary: slot == 'primary' ? value : primary,
    secondary: slot == 'secondary' ? value : secondary,
    background: slot == 'background' ? value : background,
    surface: slot == 'surface' ? value : surface,
    radius: radius,
    font: font,
    compact: compact,
    reduceMotion: reduceMotion,
    lineHeight: lineHeight,
    letterSpacing: letterSpacing,
  );
  Appearance copyWith({
    double? radius,
    String? font,
    bool? compact,
    bool? reduceMotion,
    double? lineHeight,
    double? letterSpacing,
  }) => Appearance(
    primary: primary,
    secondary: secondary,
    background: background,
    surface: surface,
    radius: radius ?? this.radius,
    font: font ?? this.font,
    compact: compact ?? this.compact,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    lineHeight: lineHeight ?? this.lineHeight,
    letterSpacing: letterSpacing ?? this.letterSpacing,
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
    'line_height': lineHeight,
    'letter_spacing': letterSpacing,
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
      font: ['system', 'serif', 'mono', 'dyslexic'].contains(raw['font'])
          ? raw['font']! as String
          : 'system',
      compact: raw['compact'] == true,
      reduceMotion: raw['reduce_motion'] == true,
      lineHeight:
          raw['line_height'] is num && (raw['line_height'] as num).isFinite
          ? (raw['line_height'] as num).toDouble().clamp(1, 1.6)
          : 1,
      letterSpacing:
          raw['letter_spacing'] is num &&
              (raw['letter_spacing'] as num).isFinite
          ? (raw['letter_spacing'] as num).toDouble().clamp(0, 3)
          : 0,
    );
  }
}

/// Choices that belong to this device, kept apart from the tasks.
class AppSettings {
  const AppSettings({
    this.themeId = 'aion',
    this.logoId = 'aion',
    this.languageCode = '',
    this.textScale = 1,
    this.displayMode = 'preset',
    this.gameMode = true,
    this.charClass = 'savasci',
    this.uiScale = 1.0,
    this.appearance = const Appearance(),
    this.navigationOrder = const [],
  });

  /// One of the ids in `appThemes` (unknown ids fall back to the default).
  final String themeId;
  final String logoId;
  final String languageCode;
  final double textScale;
  final String displayMode;

  /// XP, levels, stats and badges on screen. Off shows a plain list.
  final bool gameMode;

  /// Cosmetic character class (emblem and motto only; no rule changes).
  final String charClass;

  /// Whole-interface zoom, independent of the operating system's text size.
  final double uiScale;
  final Appearance appearance;
  final List<String> navigationOrder;

  static const defaultNavigationOrder = [
    'maceram',
    'gun',
    'gorevler',
    'kontrol',
    'daily_summary',
    'weekly_review',
    'projeler',
    'yetenekler',
    'courses',
    'skill_tree',
    'karakter',
    'saglik',
    'fitness',
    'nutrition',
    'companions',
  ];

  /// Ignore duplicates, removed pages and Settings. New pages append safely.
  List<String> get effectiveNavigationOrder => List.unmodifiable({
    ...navigationOrder.where(defaultNavigationOrder.contains),
    ...defaultNavigationOrder,
  });

  static const minScale = 0.8;
  static const maxScale = 2.0;

  double get safeScale =>
      uiScale.isFinite ? uiScale.clamp(minScale, maxScale) : 1.0;

  AppSettings copyWith({
    String? themeId,
    String? logoId,
    String? languageCode,
    double? textScale,
    String? displayMode,
    bool? gameMode,
    String? charClass,
    double? uiScale,
    Appearance? appearance,
    List<String>? navigationOrder,
  }) => AppSettings(
    themeId: themeId ?? this.themeId,
    logoId: logoId ?? this.logoId,
    languageCode: languageCode ?? this.languageCode,
    textScale: textScale ?? this.textScale,
    displayMode: displayMode ?? this.displayMode,
    gameMode: gameMode ?? this.gameMode,
    charClass: charClass ?? this.charClass,
    uiScale: uiScale ?? this.uiScale,
    appearance: appearance ?? this.appearance,
    navigationOrder: navigationOrder ?? this.navigationOrder,
  );

  String encode() => const JsonEncoder.withIndent('  ').convert({
    'theme': themeId,
    'logo': logoId,
    'language': languageCode,
    'text_scale': textScale,
    'display_mode': displayMode,
    'game_mode': gameMode,
    'class': charClass,
    'ui_scale': safeScale,
    'appearance': appearance.toJson(),
    'navigation_order': effectiveNavigationOrder,
  });

  /// Reads settings; anything missing or malformed falls back to defaults
  /// (settings are a convenience, never a reason to refuse to start).
  static AppSettings decode(String text) {
    try {
      final j = jsonDecode(text);
      if (j is! Map<String, Object?>) return const AppSettings();
      return AppSettings(
        logoId: ['aion', 'sheep', 'wolf', 'owl'].contains(j['logo'])
            ? j['logo'] as String
            : 'aion',
        textScale: j['text_scale'] is num && (j['text_scale'] as num).isFinite
            ? (j['text_scale'] as num).toDouble().clamp(.8, 2)
            : 1,
        displayMode:
            [
              'preset',
              'system',
              'light',
              'dark',
              'contrast',
            ].contains(j['display_mode'])
            ? j['display_mode'] as String
            : 'preset',
        languageCode: ['tr', 'en'].contains(j['language'])
            ? j['language']! as String
            : '',
        themeId: j['theme'] is String ? j['theme']! as String : 'aion',
        gameMode: j['game_mode'] is bool ? j['game_mode']! as bool : true,
        charClass: j['class'] is String ? j['class']! as String : 'savasci',
        appearance: Appearance.decode(j['appearance']),
        navigationOrder: j['navigation_order'] is List
            ? (j['navigation_order'] as List).whereType<String>().toList()
            : const [],
        uiScale: j['ui_scale'] is num && (j['ui_scale']! as num).isFinite
            ? (j['ui_scale']! as num).toDouble().clamp(minScale, maxScale)
            : 1.0,
      );
    } on FormatException {
      return const AppSettings();
    }
  }
}
