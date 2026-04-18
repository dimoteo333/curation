import 'package:flutter/material.dart';

ThemeData buildCuratorTheme(
  Brightness brightness, {
  CuratorMood mood = CuratorMood.cream,
}) {
  final isDark = brightness == Brightness.dark;
  final palette = isDark
      ? CuratorPalette.dark(mood: mood)
      : CuratorPalette.light(mood: mood);
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: palette.terra,
    onPrimary: const Color(0xFFFDF6EC),
    secondary: palette.ochre,
    onSecondary: palette.ink,
    tertiary: palette.sage,
    onTertiary: palette.ink,
    error: const Color(0xFFB45A49),
    onError: Colors.white,
    surface: palette.paper,
    onSurface: palette.ink,
    surfaceContainerHighest: palette.paper2,
    onSurfaceVariant: palette.ink2,
    outline: palette.line2,
    outlineVariant: palette.line,
    shadow: palette.shadowCardColor,
    scrim: Colors.black,
    inverseSurface: isDark ? const Color(0xFFF5EDE0) : const Color(0xFF241C18),
    onInverseSurface: isDark
        ? const Color(0xFF241C18)
        : const Color(0xFFF5EDE0),
    inversePrimary: palette.terraSoft,
  );
  final textTheme = _buildTextTheme(
    ThemeData(brightness: brightness).textTheme,
    palette,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'GowunBatang',
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: textTheme,
    extensions: <ThemeExtension<dynamic>>[palette],
    splashFactory: InkRipple.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: _EditorialFadeTransitionsBuilder(),
        TargetPlatform.iOS: _EditorialFadeTransitionsBuilder(),
        TargetPlatform.macOS: _EditorialFadeTransitionsBuilder(),
        TargetPlatform.windows: _EditorialFadeTransitionsBuilder(),
        TargetPlatform.linux: _EditorialFadeTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineSmall,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      color: palette.surfaceStrong,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: palette.line),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: palette.terra,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.terraDeep,
        textStyle: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: palette.line2),
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        backgroundColor: palette.surfaceStrong,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    switchTheme: SwitchThemeData(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFFDF6EC);
        }
        return palette.surfaceStrong;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return palette.terra;
        }
        return palette.paper3;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      trackOutlineWidth: WidgetStateProperty.all(0),
    ),
    checkboxTheme: CheckboxThemeData(
      side: BorderSide(color: palette.line2, width: 1.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return palette.terra;
        }
        return palette.surfaceStrong;
      }),
      checkColor: WidgetStateProperty.all(const Color(0xFFFDF6EC)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: palette.surfaceStrong.withValues(alpha: isDark ? 0.92 : 0.94),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: palette.ink3,
        fontFamily: 'IBMPlexSansKR',
      ),
      labelStyle: textTheme.bodySmall?.copyWith(color: palette.ink3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: _inputBorder(palette.line2),
      enabledBorder: _inputBorder(palette.line2),
      focusedBorder: _inputBorder(palette.terra),
      errorBorder: _inputBorder(colorScheme.error),
      focusedErrorBorder: _inputBorder(colorScheme.error),
    ),
    dividerTheme: DividerThemeData(
      color: palette.line,
      space: 1,
      thickness: 0.8,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark
          ? const Color(0xFF2C231F)
          : const Color(0xFF3A332E),
      contentTextStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.paper,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: palette.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}

TextTheme _buildTextTheme(TextTheme base, CuratorPalette palette) {
  TextStyle? serif(
    TextStyle? style, {
    FontWeight weight = FontWeight.w400,
    double? size,
    double? letterSpacing,
    double height = 1.5,
    Color? color,
  }) {
    return style?.copyWith(
      fontFamily: 'GowunBatang',
      fontWeight: weight,
      fontSize: size,
      letterSpacing: letterSpacing,
      color: color ?? palette.ink,
      height: height,
    );
  }

  TextStyle? sans(
    TextStyle? style, {
    FontWeight weight = FontWeight.w400,
    double? size,
    double? letterSpacing,
    Color? color,
    double height = 1.45,
  }) {
    return style?.copyWith(
      fontFamily: 'IBMPlexSansKR',
      fontWeight: weight,
      fontSize: size,
      letterSpacing: letterSpacing,
      color: color ?? palette.ink,
      height: height,
    );
  }

  return base.copyWith(
    displayLarge: serif(
      base.displayLarge,
      weight: FontWeight.w700,
      size: 72,
      letterSpacing: -2.8,
      height: 1.05,
    ),
    displayMedium: serif(
      base.displayMedium,
      weight: FontWeight.w700,
      size: 40,
      letterSpacing: -1.2,
      height: 1.12,
    ),
    displaySmall: serif(
      base.displaySmall,
      weight: FontWeight.w700,
      size: 32,
      letterSpacing: -0.8,
      height: 1.16,
    ),
    headlineLarge: serif(
      base.headlineLarge,
      weight: FontWeight.w700,
      size: 30,
      letterSpacing: -0.6,
      height: 1.24,
    ),
    headlineMedium: serif(
      base.headlineMedium,
      weight: FontWeight.w700,
      size: 24,
      letterSpacing: -0.4,
      height: 1.28,
    ),
    headlineSmall: serif(
      base.headlineSmall,
      weight: FontWeight.w700,
      size: 19,
      letterSpacing: -0.18,
      height: 1.28,
    ),
    titleLarge: serif(
      base.titleLarge,
      weight: FontWeight.w700,
      size: 20,
      letterSpacing: -0.12,
      height: 1.28,
    ),
    titleMedium: sans(
      base.titleMedium,
      weight: FontWeight.w500,
      size: 15,
      letterSpacing: -0.14,
      height: 1.4,
    ),
    titleSmall: sans(
      base.titleSmall,
      weight: FontWeight.w600,
      size: 12.5,
      letterSpacing: 0.35,
      color: palette.ink3,
      height: 1.32,
    ),
    bodyLarge: serif(
      base.bodyLarge,
      size: 17,
      letterSpacing: -0.05,
      height: 1.72,
    ),
    bodyMedium: serif(
      base.bodyMedium,
      size: 15.5,
      letterSpacing: -0.03,
      height: 1.68,
    ),
    bodySmall: sans(
      base.bodySmall,
      size: 12.5,
      color: palette.ink3,
      letterSpacing: 0.06,
      height: 1.48,
    ),
    labelLarge: sans(
      base.labelLarge,
      weight: FontWeight.w600,
      size: 13,
      letterSpacing: 0.28,
      height: 1.26,
    ),
    labelMedium: sans(
      base.labelMedium,
      weight: FontWeight.w500,
      size: 12,
      color: palette.ink3,
      letterSpacing: 0.45,
      height: 1.28,
    ),
    labelSmall: sans(
      base.labelSmall,
      weight: FontWeight.w500,
      size: 11,
      color: palette.ink3,
      letterSpacing: 0.7,
      height: 1.2,
    ),
  );
}

OutlineInputBorder _inputBorder(Color color) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide(color: color, width: 1),
  );
}

class _EditorialFadeTransitionsBuilder extends PageTransitionsBuilder {
  const _EditorialFadeTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(fade);
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

enum CuratorMood { cream, peach, beige, dusty }

extension CuratorMoodId on CuratorMood {
  String get id => switch (this) {
    CuratorMood.cream => 'cream',
    CuratorMood.peach => 'peach',
    CuratorMood.beige => 'beige',
    CuratorMood.dusty => 'dusty',
  };

  String get label => switch (this) {
    CuratorMood.cream => '크림 + 테라코타',
    CuratorMood.peach => '피치 + 로즈',
    CuratorMood.beige => '베이지 + 오커',
    CuratorMood.dusty => '더스티 핑크 + 세이지',
  };
}

@immutable
class CuratorPalette extends ThemeExtension<CuratorPalette> {
  const CuratorPalette({
    required this.mood,
    required this.isDark,
    required this.backdropTop,
    required this.backdropBottom,
    required this.backdropAccent,
    required this.ambientGlow,
    required this.paper,
    required this.paper2,
    required this.paper3,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.terra,
    required this.terraDeep,
    required this.terraSoft,
    required this.ochre,
    required this.sage,
    required this.line,
    required this.line2,
    required this.shadowSoftColor,
    required this.shadowCardColor,
  });

  factory CuratorPalette.light({CuratorMood mood = CuratorMood.cream}) {
    return _paletteFromSeed(_lightSeeds[mood]!, mood: mood, isDark: false);
  }

  factory CuratorPalette.dark({CuratorMood mood = CuratorMood.cream}) {
    return _paletteFromSeed(_darkSeeds[mood]!, mood: mood, isDark: true);
  }

  static CuratorPalette _paletteFromSeed(
    _CuratorPaletteSeed seed, {
    required CuratorMood mood,
    required bool isDark,
  }) {
    return CuratorPalette(
      mood: mood,
      isDark: isDark,
      backdropTop: seed.backdropTop,
      backdropBottom: seed.backdropBottom,
      backdropAccent: seed.backdropAccent,
      ambientGlow: seed.ambientGlow,
      paper: seed.paper,
      paper2: seed.paper2,
      paper3: seed.paper3,
      ink: seed.ink,
      ink2: seed.ink2,
      ink3: seed.ink3,
      ink4: seed.ink4,
      terra: seed.terra,
      terraDeep: seed.terraDeep,
      terraSoft: seed.terraSoft,
      ochre: seed.ochre,
      sage: seed.sage,
      line: seed.line,
      line2: seed.line2,
      shadowSoftColor: seed.shadowSoftColor,
      shadowCardColor: seed.shadowCardColor,
    );
  }

  static const Map<CuratorMood, _CuratorPaletteSeed> _lightSeeds =
      <CuratorMood, _CuratorPaletteSeed>{
        CuratorMood.cream: _CuratorPaletteSeed(
          backdropTop: Color(0xFFF5EDE0),
          backdropBottom: Color(0xFFE9DDCE),
          backdropAccent: Color(0xFFF1E6D8),
          ambientGlow: Color(0x33C87456),
          paper: Color(0xFFF5EDE0),
          paper2: Color(0xFFEDE4D6),
          paper3: Color(0xFFE6D8C8),
          ink: Color(0xFF3A332E),
          ink2: Color(0xFF6B625A),
          ink3: Color(0xFF9A8F86),
          ink4: Color(0xFFC4BAB2),
          terra: Color(0xFFC87456),
          terraDeep: Color(0xFFA35A3F),
          terraSoft: Color(0xFFE8B8A4),
          ochre: Color(0xFFB89368),
          sage: Color(0xFF96A78A),
          line: Color(0xFFE8DDD0),
          line2: Color(0xFFD4C5B5),
          shadowSoftColor: Color(0x144A2F1C),
          shadowCardColor: Color(0x1B4A2F1C),
        ),
        CuratorMood.peach: _CuratorPaletteSeed(
          backdropTop: Color(0xFFFBEDE6),
          backdropBottom: Color(0xFFEED9D1),
          backdropAccent: Color(0xFFF5E3DB),
          ambientGlow: Color(0x33D88172),
          paper: Color(0xFFFBEDE6),
          paper2: Color(0xFFF4E3D9),
          paper3: Color(0xFFEED3C9),
          ink: Color(0xFF3A332E),
          ink2: Color(0xFF6B625A),
          ink3: Color(0xFFA08981),
          ink4: Color(0xFFC6B2AA),
          terra: Color(0xFFD88172),
          terraDeep: Color(0xFFB85D4E),
          terraSoft: Color(0xFFF0C4B8),
          ochre: Color(0xFFC29A8A),
          sage: Color(0xFF96A78A),
          line: Color(0xFFECE0D7),
          line2: Color(0xFFD8C5BC),
          shadowSoftColor: Color(0x144A2F1C),
          shadowCardColor: Color(0x1B4A2F1C),
        ),
        CuratorMood.beige: _CuratorPaletteSeed(
          backdropTop: Color(0xFFF2E9D8),
          backdropBottom: Color(0xFFE7D8BE),
          backdropAccent: Color(0xFFEEDFC8),
          ambientGlow: Color(0x33B8894A),
          paper: Color(0xFFF2E9D8),
          paper2: Color(0xFFEBDEC5),
          paper3: Color(0xFFE4D1AE),
          ink: Color(0xFF332E27),
          ink2: Color(0xFF655A4B),
          ink3: Color(0xFF958571),
          ink4: Color(0xFFC3B3A0),
          terra: Color(0xFFB8894A),
          terraDeep: Color(0xFF8F6830),
          terraSoft: Color(0xFFDCBB85),
          ochre: Color(0xFFA87E3F),
          sage: Color(0xFF96A78A),
          line: Color(0xFFE5D7BF),
          line2: Color(0xFFD2C09F),
          shadowSoftColor: Color(0x144A2F1C),
          shadowCardColor: Color(0x1B4A2F1C),
        ),
        CuratorMood.dusty: _CuratorPaletteSeed(
          backdropTop: Color(0xFFF4E8E6),
          backdropBottom: Color(0xFFE8D6D3),
          backdropAccent: Color(0xFFEEDCD9),
          ambientGlow: Color(0x33C68A93),
          paper: Color(0xFFF4E8E6),
          paper2: Color(0xFFEADBD7),
          paper3: Color(0xFFE3CBC8),
          ink: Color(0xFF3B3134),
          ink2: Color(0xFF6A5C60),
          ink3: Color(0xFF9A8A8E),
          ink4: Color(0xFFC4B4B8),
          terra: Color(0xFFC68A93),
          terraDeep: Color(0xFFA06A72),
          terraSoft: Color(0xFFE5C0C5),
          ochre: Color(0xFFB89368),
          sage: Color(0xFF96A78A),
          line: Color(0xFFE7DAD8),
          line2: Color(0xFFD2C1BE),
          shadowSoftColor: Color(0x144A2F1C),
          shadowCardColor: Color(0x1B4A2F1C),
        ),
      };

  static const Map<CuratorMood, _CuratorPaletteSeed> _darkSeeds =
      <CuratorMood, _CuratorPaletteSeed>{
        CuratorMood.cream: _CuratorPaletteSeed(
          backdropTop: Color(0xFF1E1713),
          backdropBottom: Color(0xFF120D0A),
          backdropAccent: Color(0xFF281F1A),
          ambientGlow: Color(0x44C87456),
          paper: Color(0xFF241C18),
          paper2: Color(0xFF2D241F),
          paper3: Color(0xFF362B25),
          ink: Color(0xFFF5EDE0),
          ink2: Color(0xFFE1D4C6),
          ink3: Color(0xFFB9A99A),
          ink4: Color(0xFF837668),
          terra: Color(0xFFD98C71),
          terraDeep: Color(0xFFEAB19D),
          terraSoft: Color(0xFF73493B),
          ochre: Color(0xFFC7A37D),
          sage: Color(0xFFA4B69A),
          line: Color(0x33E8DDD0),
          line2: Color(0x4DD4C5B5),
          shadowSoftColor: Color(0x22000000),
          shadowCardColor: Color(0x38000000),
        ),
        CuratorMood.peach: _CuratorPaletteSeed(
          backdropTop: Color(0xFF201715),
          backdropBottom: Color(0xFF140D0B),
          backdropAccent: Color(0xFF2B201D),
          ambientGlow: Color(0x44D88172),
          paper: Color(0xFF261C1A),
          paper2: Color(0xFF302522),
          paper3: Color(0xFF3A2D2A),
          ink: Color(0xFFF9ECE6),
          ink2: Color(0xFFE3D0C9),
          ink3: Color(0xFFBDA7A0),
          ink4: Color(0xFF87726D),
          terra: Color(0xFFE08D7F),
          terraDeep: Color(0xFFF0B7AC),
          terraSoft: Color(0xFF764841),
          ochre: Color(0xFFD1A597),
          sage: Color(0xFFA4B69A),
          line: Color(0x33ECE0D7),
          line2: Color(0x4DD8C5BC),
          shadowSoftColor: Color(0x22000000),
          shadowCardColor: Color(0x38000000),
        ),
        CuratorMood.beige: _CuratorPaletteSeed(
          backdropTop: Color(0xFF1D1810),
          backdropBottom: Color(0xFF110D08),
          backdropAccent: Color(0xFF271F15),
          ambientGlow: Color(0x44B8894A),
          paper: Color(0xFF231D15),
          paper2: Color(0xFF2D261C),
          paper3: Color(0xFF382F22),
          ink: Color(0xFFF2E9D8),
          ink2: Color(0xFFDECFB5),
          ink3: Color(0xFFB3A083),
          ink4: Color(0xFF7B6A54),
          terra: Color(0xFFC99858),
          terraDeep: Color(0xFFE0BE89),
          terraSoft: Color(0xFF6C5332),
          ochre: Color(0xFFC09556),
          sage: Color(0xFFA4B69A),
          line: Color(0x33E5D7BF),
          line2: Color(0x4DD2C09F),
          shadowSoftColor: Color(0x22000000),
          shadowCardColor: Color(0x38000000),
        ),
        CuratorMood.dusty: _CuratorPaletteSeed(
          backdropTop: Color(0xFF1D1516),
          backdropBottom: Color(0xFF120A0C),
          backdropAccent: Color(0xFF271D1F),
          ambientGlow: Color(0x44C68A93),
          paper: Color(0xFF241B1D),
          paper2: Color(0xFF2E2426),
          paper3: Color(0xFF382D30),
          ink: Color(0xFFF4E8E6),
          ink2: Color(0xFFDFD0CD),
          ink3: Color(0xFFB7A4A8),
          ink4: Color(0xFF817075),
          terra: Color(0xFFD79AA4),
          terraDeep: Color(0xFFE8BCC2),
          terraSoft: Color(0xFF704C52),
          ochre: Color(0xFFC7A37D),
          sage: Color(0xFFA7B79F),
          line: Color(0x33E7DAD8),
          line2: Color(0x4DD2C1BE),
          shadowSoftColor: Color(0x22000000),
          shadowCardColor: Color(0x38000000),
        ),
      };

  final CuratorMood mood;
  final bool isDark;
  final Color backdropTop;
  final Color backdropBottom;
  final Color backdropAccent;
  final Color ambientGlow;
  final Color paper;
  final Color paper2;
  final Color paper3;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color ink4;
  final Color terra;
  final Color terraDeep;
  final Color terraSoft;
  final Color ochre;
  final Color sage;
  final Color line;
  final Color line2;
  final Color shadowSoftColor;
  final Color shadowCardColor;

  Color get surface => paper;
  Color get surfaceStrong => isDark
      ? Color.alphaBlend(Colors.white.withValues(alpha: 0.04), paper2)
      : Colors.white.withValues(alpha: 0.62);
  Color get surfaceMuted => paper2;
  Color get outline => line2;
  Color get label => ink3;
  Color get accent => terra;
  Color get accentStrong => terraDeep;
  Color get accentSoft => terraSoft;
  Color get highlight => paper3;
  Color get highlightStrong => ochre;
  Color get shadowColor => shadowCardColor;

  List<BoxShadow> get shadowSoft => <BoxShadow>[
    BoxShadow(
      color: shadowSoftColor.withValues(alpha: isDark ? 0.45 : 0.08),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: shadowSoftColor.withValues(alpha: isDark ? 0.22 : 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  List<BoxShadow> get shadowCard => <BoxShadow>[
    BoxShadow(
      color: shadowCardColor.withValues(alpha: isDark ? 0.52 : 0.11),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: shadowCardColor.withValues(alpha: isDark ? 0.28 : 0.06),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  @override
  CuratorPalette copyWith({
    CuratorMood? mood,
    bool? isDark,
    Color? backdropTop,
    Color? backdropBottom,
    Color? backdropAccent,
    Color? ambientGlow,
    Color? paper,
    Color? paper2,
    Color? paper3,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? ink4,
    Color? terra,
    Color? terraDeep,
    Color? terraSoft,
    Color? ochre,
    Color? sage,
    Color? line,
    Color? line2,
    Color? shadowSoftColor,
    Color? shadowCardColor,
  }) {
    return CuratorPalette(
      mood: mood ?? this.mood,
      isDark: isDark ?? this.isDark,
      backdropTop: backdropTop ?? this.backdropTop,
      backdropBottom: backdropBottom ?? this.backdropBottom,
      backdropAccent: backdropAccent ?? this.backdropAccent,
      ambientGlow: ambientGlow ?? this.ambientGlow,
      paper: paper ?? this.paper,
      paper2: paper2 ?? this.paper2,
      paper3: paper3 ?? this.paper3,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      ink4: ink4 ?? this.ink4,
      terra: terra ?? this.terra,
      terraDeep: terraDeep ?? this.terraDeep,
      terraSoft: terraSoft ?? this.terraSoft,
      ochre: ochre ?? this.ochre,
      sage: sage ?? this.sage,
      line: line ?? this.line,
      line2: line2 ?? this.line2,
      shadowSoftColor: shadowSoftColor ?? this.shadowSoftColor,
      shadowCardColor: shadowCardColor ?? this.shadowCardColor,
    );
  }

  @override
  CuratorPalette lerp(ThemeExtension<CuratorPalette>? other, double t) {
    if (other is! CuratorPalette) {
      return this;
    }

    return CuratorPalette(
      mood: t < 0.5 ? mood : other.mood,
      isDark: t < 0.5 ? isDark : other.isDark,
      backdropTop: Color.lerp(backdropTop, other.backdropTop, t)!,
      backdropBottom: Color.lerp(backdropBottom, other.backdropBottom, t)!,
      backdropAccent: Color.lerp(backdropAccent, other.backdropAccent, t)!,
      ambientGlow: Color.lerp(ambientGlow, other.ambientGlow, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      paper2: Color.lerp(paper2, other.paper2, t)!,
      paper3: Color.lerp(paper3, other.paper3, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      ink4: Color.lerp(ink4, other.ink4, t)!,
      terra: Color.lerp(terra, other.terra, t)!,
      terraDeep: Color.lerp(terraDeep, other.terraDeep, t)!,
      terraSoft: Color.lerp(terraSoft, other.terraSoft, t)!,
      ochre: Color.lerp(ochre, other.ochre, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      line: Color.lerp(line, other.line, t)!,
      line2: Color.lerp(line2, other.line2, t)!,
      shadowSoftColor: Color.lerp(shadowSoftColor, other.shadowSoftColor, t)!,
      shadowCardColor: Color.lerp(shadowCardColor, other.shadowCardColor, t)!,
    );
  }
}

@immutable
class _CuratorPaletteSeed {
  const _CuratorPaletteSeed({
    required this.backdropTop,
    required this.backdropBottom,
    required this.backdropAccent,
    required this.ambientGlow,
    required this.paper,
    required this.paper2,
    required this.paper3,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.terra,
    required this.terraDeep,
    required this.terraSoft,
    required this.ochre,
    required this.sage,
    required this.line,
    required this.line2,
    required this.shadowSoftColor,
    required this.shadowCardColor,
  });

  final Color backdropTop;
  final Color backdropBottom;
  final Color backdropAccent;
  final Color ambientGlow;
  final Color paper;
  final Color paper2;
  final Color paper3;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color ink4;
  final Color terra;
  final Color terraDeep;
  final Color terraSoft;
  final Color ochre;
  final Color sage;
  final Color line;
  final Color line2;
  final Color shadowSoftColor;
  final Color shadowCardColor;
}
