import 'package:flutter/material.dart';

import '../app/settings.dart';

/// Extra look of a theme beyond Material colours: the background gradient,
/// the XP colour, card borders and the emblem on the character card.
class GameStyle extends ThemeExtension<GameStyle> {
  const GameStyle({
    required this.gradient,
    required this.xp,
    required this.cardBorder,
    required this.emblem,
    required this.glow,
    this.headlineFamily,
  });

  final List<Color> gradient;
  final Color xp;
  final Color cardBorder;
  final IconData emblem;

  /// Soft coloured shadow around cards (game-like themes).
  final bool glow;

  /// Font family for titles (falls back to the system font if missing).
  final String? headlineFamily;

  static GameStyle of(BuildContext context) =>
      Theme.of(context).extension<GameStyle>()!;

  @override
  GameStyle copyWith() => this;

  @override
  GameStyle lerp(GameStyle? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

class AppThemeSpec {
  const AppThemeSpec({
    required this.id,
    required this.name,
    required this.tagline,
    required this.brightness,
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.gradient,
    required this.xp,
    required this.emblem,
    this.glow = false,
    this.serifTitles = false,
    this.radius = 14,
  });

  final String id;
  final String name;
  final String tagline;
  final Brightness brightness;
  final Color primary;
  final Color secondary;
  final Color surface;
  final List<Color> gradient;
  final Color xp;
  final IconData emblem;
  final bool glow;
  final bool serifTitles;
  final double radius;
}

const String defaultThemeId = 'bahce';

const List<AppThemeSpec> appThemes = [
  AppThemeSpec(
    id: 'bahce',
    name: 'Sakin Bahçe',
    tagline: 'Küçük adımların yeşerdiği yer',
    brightness: Brightness.light,
    primary: Color(0xFF527B62),
    secondary: Color(0xFFBA9762),
    surface: Color(0xFFFFFEFA),
    gradient: [Color(0xFFF7F8F2), Color(0xFFF7F8F2)],
    xp: Color(0xFF709478),
    emblem: Icons.eco_rounded,
    radius: 20,
  ),
  AppThemeSpec(
    id: 'diyar',
    name: 'Fantastik Diyar',
    tagline: 'Altın, parşömen ve gece göğü: bir MMORPG kalesinde görev tahtası',
    brightness: Brightness.dark,
    primary: Color(0xFFE0B24F),
    secondary: Color(0xFFC0574C),
    surface: Color(0xFF231B30),
    gradient: [Color(0xFF120E22), Color(0xFF221832), Color(0xFF2C1F16)],
    xp: Color(0xFFF2C14E),
    emblem: Icons.shield,
    glow: true,
    serifTitles: true,
  ),
  AppThemeSpec(
    id: 'neon',
    name: 'Neon Şehir',
    tagline: 'Siberpunk sokakları, camgöbeği ışıklar',
    brightness: Brightness.dark,
    primary: Color(0xFF25E2F2),
    secondary: Color(0xFFFF3DCB),
    surface: Color(0xFF13132B),
    gradient: [Color(0xFF07071A), Color(0xFF140A2E), Color(0xFF1E0730)],
    xp: Color(0xFFFF3DCB),
    emblem: Icons.bolt,
    glow: true,
  ),
  AppThemeSpec(
    id: 'orman',
    name: 'Orman Ruhu',
    tagline: 'Yosun, toprak ve sabah ışığı',
    brightness: Brightness.light,
    primary: Color(0xFF3E7B3A),
    secondary: Color(0xFFA0682B),
    surface: Color(0xFFF8FBF3),
    gradient: [Color(0xFFEFF6E7), Color(0xFFDCEBD0)],
    xp: Color(0xFF7BA23F),
    emblem: Icons.park,
  ),
  AppThemeSpec(
    id: 'pastel',
    name: 'Pastel Rüya',
    tagline: 'Yumuşak pembe ve lavanta, bol yuvarlak köşe',
    brightness: Brightness.light,
    primary: Color(0xFFCF4F92),
    secondary: Color(0xFF7C6BD6),
    surface: Color(0xFFFFFAFD),
    gradient: [Color(0xFFFFF0F6), Color(0xFFEDE7FF)],
    xp: Color(0xFFE478B5),
    emblem: Icons.favorite,
    radius: 22,
  ),
  AppThemeSpec(
    id: 'gece',
    name: 'Gece Yarısı',
    tagline: 'Koyu ve sade, göz yormayan',
    brightness: Brightness.dark,
    primary: Color(0xFF7AA2F7),
    secondary: Color(0xFFBB9AF7),
    surface: Color(0xFF171C26),
    gradient: [Color(0xFF0F131A), Color(0xFF151B25)],
    xp: Color(0xFF7AA2F7),
    emblem: Icons.nightlight_round,
  ),
  AppThemeSpec(
    id: 'sade',
    name: 'Sade',
    tagline: 'Açık renk, sakin ve düz',
    brightness: Brightness.light,
    primary: Color(0xFF2F7D6D),
    secondary: Color(0xFF5B6C8F),
    surface: Color(0xFFFFFFFF),
    gradient: [Color(0xFFF6F8F7), Color(0xFFF6F8F7)],
    xp: Color(0xFF2F7D6D),
    emblem: Icons.emoji_events,
  ),
];

AppThemeSpec themeById(String id) => appThemes.firstWhere(
  (t) => t.id == id,
  orElse: () => appThemes.firstWhere((t) => t.id == defaultThemeId),
);

AppThemeSpec customizedTheme(AppThemeSpec base, Appearance a) {
  final bg = a.background == null ? base.gradient.first : Color(a.background!);
  return AppThemeSpec(
    id: base.id,
    name: base.name,
    tagline: base.tagline,
    brightness: a.background == null
        ? base.brightness
        : (bg.computeLuminance() > .35 ? Brightness.light : Brightness.dark),
    primary: a.primary == null ? base.primary : Color(a.primary!),
    secondary: a.secondary == null ? base.secondary : Color(a.secondary!),
    surface: a.surface == null
        ? (a.background == null
              ? base.surface
              : Color.alphaBlend(
                  (bg.computeLuminance() > .35 ? Colors.white : Colors.black)
                      .withValues(alpha: .10),
                  bg,
                ))
        : Color(a.surface!),
    gradient: a.background == null ? base.gradient : [bg, bg],
    xp: a.primary == null ? base.xp : Color(a.primary!),
    emblem: base.emblem,
    glow: base.glow,
    serifTitles: a.font == 'serif' || (a.font == 'system' && base.serifTitles),
    radius: a.radius ?? base.radius,
  );
}

Color readableOn(Color background) => background.computeLuminance() > .179
    ? const Color(0xFF171C19)
    : const Color(0xFFFFFEFA);

ThemeData buildTheme(
  AppThemeSpec spec, {
  Appearance appearance = const Appearance(),
  bool highContrast = false,
}) {
  final base = ColorScheme.fromSeed(
    seedColor: spec.primary,
    brightness: spec.brightness,
  );
  final dark = spec.brightness == Brightness.dark;
  final scheme = highContrast
      ? (spec.brightness == Brightness.dark
            ? const ColorScheme.highContrastDark()
            : const ColorScheme.highContrastLight())
      : base.copyWith(
          primary: spec.primary,
          onPrimary: readableOn(spec.primary),
          onSecondary: readableOn(spec.secondary),
          onSurface: readableOn(spec.gradient.first),
          secondary: spec.secondary,
          surface: spec.surface,
          surfaceContainerLow: Color.alphaBlend(
            spec.primary.withValues(alpha: dark ? 0.06 : 0.04),
            spec.surface,
          ),
        );
  final border = spec.primary.withValues(alpha: dark ? 0.35 : 0.12);
  final titles = spec.serifTitles ? 'Georgia' : null;
  const serifFallback = [
    'Georgia',
    'Cambria',
    'DejaVu Serif',
    'Times New Roman',
  ];
  final text = ThemeData(
    brightness: spec.brightness,
    fontFamily: appearance.font == 'dyslexic'
        ? 'OpenDyslexic'
        : appearance.font == 'mono'
        ? 'monospace'
        : appearance.font == 'serif'
        ? 'Georgia'
        : null,
  ).textTheme;
  TextStyle? t(TextStyle? s) => titles == null
      ? s
      : s?.copyWith(fontFamily: titles, fontFamilyFallback: serifFallback);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: appearance.font == 'dyslexic'
        ? 'OpenDyslexic'
        : appearance.font == 'mono'
        ? 'monospace'
        : appearance.font == 'serif'
        ? 'Georgia'
        : null,
    visualDensity: appearance.compact
        ? VisualDensity.compact
        : VisualDensity.standard,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: text
        .apply(
          heightFactor: appearance.lineHeight,
          letterSpacingDelta: appearance.letterSpacing,
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
          fontFamily: appearance.font == 'dyslexic'
              ? 'OpenDyslexic'
              : appearance.font == 'mono'
              ? 'monospace'
              : appearance.font == 'serif'
              ? 'Georgia'
              : null,
        )
        .copyWith(
          headlineSmall: t(text.headlineSmall),
          headlineMedium: t(text.headlineMedium),
          titleLarge: t(text.titleLarge),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        fontFamily: titles,
        fontFamilyFallback: titles == null ? null : serifFallback,
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface.withValues(alpha: 0.9),
    ),
    dividerTheme: DividerThemeData(color: border),
    cardTheme: CardThemeData(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spec.radius),
        side: BorderSide(color: border),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    extensions: [
      GameStyle(
        gradient: spec.gradient,
        xp: spec.xp,
        cardBorder: border,
        emblem: spec.emblem,
        glow: spec.glow,
        headlineFamily: titles,
      ),
    ],
  );
}
