import 'package:flutter/material.dart';

ThemeData buildCuratorTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final palette = isDark ? CuratorPalette.dark() : CuratorPalette.light();
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: palette.accent,
    onPrimary: isDark ? const Color(0xFF161519) : Colors.white,
    secondary: palette.accentSoft,
    onSecondary: isDark ? const Color(0xFFEFE7DA) : const Color(0xFF3A3228),
    tertiary: palette.highlight,
    onTertiary: isDark ? const Color(0xFF18171B) : const Color(0xFF3A3228),
    error: const Color(0xFFB45746),
    onError: Colors.white,
    surface: palette.surface,
    onSurface: isDark ? const Color(0xFFE8E8E8) : const Color(0xFF2C2C2E),
    surfaceContainerHighest: palette.surfaceStrong,
    onSurfaceVariant: palette.label,
    outline: palette.outline,
    outlineVariant: palette.outline.withValues(alpha: 0.4),
    shadow: palette.shadowColor,
    scrim: Colors.black,
    inverseSurface: isDark ? const Color(0xFFF5F1EA) : const Color(0xFF1E1E22),
    onInverseSurface: isDark
        ? const Color(0xFF1E1E22)
        : const Color(0xFFF5F1EA),
    inversePrimary: palette.accent,
  );
  final textTheme = _buildTextTheme(
    ThemeData(brightness: brightness).textTheme,
    colorScheme.onSurface,
    palette.label,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'IBMPlexSansKR',
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide.none,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: palette.accent,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.accentStrong,
        textStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: palette.outline.withValues(alpha: 0.8)),
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    switchTheme: SwitchThemeData(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.surface;
        }
        return palette.surfaceStrong;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return palette.accent;
        }
        return palette.surfaceMuted;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      trackOutlineWidth: WidgetStateProperty.all(0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: palette.surfaceStrong.withValues(alpha: isDark ? 0.86 : 0.94),
      hintStyle: textTheme.bodyMedium?.copyWith(color: palette.label),
      labelStyle: textTheme.bodyMedium?.copyWith(color: palette.label),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: _inputBorder(palette.outline),
      enabledBorder: _inputBorder(palette.outline.withValues(alpha: 0.78)),
      focusedBorder: _inputBorder(palette.accentStrong),
      errorBorder: _inputBorder(colorScheme.error),
      focusedErrorBorder: _inputBorder(colorScheme.error),
    ),
    dividerTheme: DividerThemeData(
      color: palette.outline.withValues(alpha: 0.46),
      space: 1,
      thickness: 0.8,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark
          ? const Color(0xFF29292E)
          : const Color(0xFF2F2E31),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

TextTheme _buildTextTheme(TextTheme base, Color onSurface, Color label) {
  TextStyle? serif(
    TextStyle? style, {
    FontWeight weight = FontWeight.w400,
    double? size,
    double? letterSpacing,
    double height = 1.12,
  }) {
    return style?.copyWith(
      fontFamily: 'GowunBatang',
      fontWeight: weight,
      fontSize: size,
      letterSpacing: letterSpacing,
      color: onSurface,
      height: height,
    );
  }

  TextStyle? sans(
    TextStyle? style, {
    FontWeight weight = FontWeight.w400,
    double? size,
    double? letterSpacing,
    Color? color,
    double height = 1.5,
  }) {
    return style?.copyWith(
      fontFamily: 'IBMPlexSansKR',
      fontWeight: weight,
      fontSize: size,
      letterSpacing: letterSpacing,
      color: color ?? onSurface,
      height: height,
    );
  }

  return base.copyWith(
    displayLarge: serif(
      base.displayLarge,
      weight: FontWeight.w700,
      size: 88,
      letterSpacing: -4.2,
      height: 0.96,
    ),
    displayMedium: serif(
      base.displayMedium,
      weight: FontWeight.w700,
      size: 42,
      letterSpacing: -1.6,
      height: 1.04,
    ),
    displaySmall: serif(
      base.displaySmall,
      weight: FontWeight.w700,
      size: 34,
      letterSpacing: -1.2,
      height: 1.08,
    ),
    headlineLarge: serif(
      base.headlineLarge,
      weight: FontWeight.w700,
      size: 28,
      letterSpacing: -0.7,
      height: 1.18,
    ),
    headlineMedium: serif(
      base.headlineMedium,
      weight: FontWeight.w400,
      size: 22,
      letterSpacing: -0.3,
      height: 1.18,
    ),
    headlineSmall: serif(
      base.headlineSmall,
      weight: FontWeight.w400,
      size: 18,
      letterSpacing: -0.1,
      height: 1.2,
    ),
    titleLarge: serif(
      base.titleLarge,
      weight: FontWeight.w400,
      size: 20,
      letterSpacing: -0.2,
      height: 1.2,
    ),
    titleMedium: sans(
      base.titleMedium,
      weight: FontWeight.w500,
      size: 15,
      letterSpacing: -0.1,
      height: 1.38,
    ),
    titleSmall: sans(
      base.titleSmall,
      weight: FontWeight.w500,
      size: 13,
      letterSpacing: 0.2,
      height: 1.36,
    ),
    bodyLarge: sans(base.bodyLarge, size: 16, height: 1.58),
    bodyMedium: sans(base.bodyMedium, size: 15, height: 1.56),
    bodySmall: sans(
      base.bodySmall,
      size: 13,
      color: label,
      letterSpacing: 0.1,
      height: 1.5,
    ),
    labelLarge: sans(
      base.labelLarge,
      weight: FontWeight.w600,
      size: 13,
      letterSpacing: 0.4,
      height: 1.28,
    ),
    labelMedium: sans(
      base.labelMedium,
      weight: FontWeight.w500,
      size: 12,
      color: label,
      letterSpacing: 0.8,
      height: 1.28,
    ),
    labelSmall: sans(
      base.labelSmall,
      weight: FontWeight.w500,
      size: 11,
      color: label,
      letterSpacing: 1.2,
      height: 1.2,
    ),
  );
}

OutlineInputBorder _inputBorder(Color color) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
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
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
      child: child,
    );
  }
}

@immutable
class CuratorPalette extends ThemeExtension<CuratorPalette> {
  const CuratorPalette({
    required this.backdropTop,
    required this.backdropBottom,
    required this.backdropAccent,
    required this.ambientGlow,
    required this.surface,
    required this.surfaceStrong,
    required this.surfaceMuted,
    required this.outline,
    required this.label,
    required this.accent,
    required this.accentStrong,
    required this.accentSoft,
    required this.highlight,
    required this.highlightStrong,
    required this.shadowColor,
  });

  factory CuratorPalette.light() {
    return const CuratorPalette(
      backdropTop: Color(0xFFFAFAF7),
      backdropBottom: Color(0xFFF2EEE6),
      backdropAccent: Color(0xFFF7F4ED),
      ambientGlow: Color(0xFFE0BE91),
      surface: Color(0xFFFFFFFF),
      surfaceStrong: Color(0xFFFFFFFF),
      surfaceMuted: Color(0xFFF3EEE4),
      outline: Color(0xFFD8D2C7),
      label: Color(0xFF76726B),
      accent: Color(0xFFE0BE91),
      accentStrong: Color(0xFFB48A57),
      accentSoft: Color(0xFFF2E2C9),
      highlight: Color(0xFFF7EFE0),
      highlightStrong: Color(0xFFCB9D63),
      shadowColor: Color(0x330F0F11),
    );
  }

  factory CuratorPalette.dark() {
    return const CuratorPalette(
      backdropTop: Color(0xFF1A1A1E),
      backdropBottom: Color(0xFF111116),
      backdropAccent: Color(0xFF202026),
      ambientGlow: Color(0xFFE0BE91),
      surface: Color(0xFF242428),
      surfaceStrong: Color(0xFF2A2A2F),
      surfaceMuted: Color(0xFF313138),
      outline: Color(0xFF45454B),
      label: Color(0xFFA9A7A2),
      accent: Color(0xFFE0BE91),
      accentStrong: Color(0xFFF0CD9A),
      accentSoft: Color(0xFF4A4032),
      highlight: Color(0xFF322C24),
      highlightStrong: Color(0xFFE0BE91),
      shadowColor: Colors.black54,
    );
  }

  final Color backdropTop;
  final Color backdropBottom;
  final Color backdropAccent;
  final Color ambientGlow;
  final Color surface;
  final Color surfaceStrong;
  final Color surfaceMuted;
  final Color outline;
  final Color label;
  final Color accent;
  final Color accentStrong;
  final Color accentSoft;
  final Color highlight;
  final Color highlightStrong;
  final Color shadowColor;

  @override
  CuratorPalette copyWith({
    Color? backdropTop,
    Color? backdropBottom,
    Color? backdropAccent,
    Color? ambientGlow,
    Color? surface,
    Color? surfaceStrong,
    Color? surfaceMuted,
    Color? outline,
    Color? label,
    Color? accent,
    Color? accentStrong,
    Color? accentSoft,
    Color? highlight,
    Color? highlightStrong,
    Color? shadowColor,
  }) {
    return CuratorPalette(
      backdropTop: backdropTop ?? this.backdropTop,
      backdropBottom: backdropBottom ?? this.backdropBottom,
      backdropAccent: backdropAccent ?? this.backdropAccent,
      ambientGlow: ambientGlow ?? this.ambientGlow,
      surface: surface ?? this.surface,
      surfaceStrong: surfaceStrong ?? this.surfaceStrong,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      outline: outline ?? this.outline,
      label: label ?? this.label,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      accentSoft: accentSoft ?? this.accentSoft,
      highlight: highlight ?? this.highlight,
      highlightStrong: highlightStrong ?? this.highlightStrong,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  CuratorPalette lerp(ThemeExtension<CuratorPalette>? other, double t) {
    if (other is! CuratorPalette) {
      return this;
    }

    return CuratorPalette(
      backdropTop: Color.lerp(backdropTop, other.backdropTop, t)!,
      backdropBottom: Color.lerp(backdropBottom, other.backdropBottom, t)!,
      backdropAccent: Color.lerp(backdropAccent, other.backdropAccent, t)!,
      ambientGlow: Color.lerp(ambientGlow, other.ambientGlow, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceStrong: Color.lerp(surfaceStrong, other.surfaceStrong, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      label: Color.lerp(label, other.label, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      highlightStrong: Color.lerp(highlightStrong, other.highlightStrong, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}
