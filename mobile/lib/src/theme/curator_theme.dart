import 'package:flutter/material.dart';

ThemeData buildCuratorTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final palette = isDark ? CuratorPalette.dark() : CuratorPalette.light();
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: palette.accent,
    onPrimary: isDark ? const Color(0xFF261612) : Colors.white,
    secondary: palette.surfaceMuted,
    onSecondary: isDark ? const Color(0xFFF9E6DB) : const Color(0xFF3D2D28),
    tertiary: palette.highlight,
    onTertiary: const Color(0xFF3E2414),
    error: const Color(0xFFBB5543),
    onError: Colors.white,
    surface: palette.surface,
    onSurface: isDark ? const Color(0xFFF7EAE2) : const Color(0xFF2C201C),
    surfaceContainerHighest: palette.surfaceStrong,
    onSurfaceVariant: palette.label,
    outline: palette.outline,
    outlineVariant: palette.outline.withValues(alpha: 0.36),
    shadow: palette.shadowColor,
    scrim: Colors.black,
    inverseSurface: isDark ? const Color(0xFFF8ECE3) : const Color(0xFF261B18),
    onInverseSurface: isDark
        ? const Color(0xFF261B18)
        : const Color(0xFFF8ECE3),
    inversePrimary: isDark ? const Color(0xFFFFDFC7) : const Color(0xFFC96A4B),
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
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineSmall,
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      color: palette.surfaceStrong.withValues(alpha: isDark ? 0.94 : 0.92),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: palette.outline.withValues(alpha: 0.28)),
      ),
      shadowColor: palette.shadowColor.withValues(alpha: 0.08),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surfaceMuted.withValues(alpha: 0.88),
      selectedColor: palette.accentSoft.withValues(alpha: 0.62),
      side: BorderSide(color: palette.outline.withValues(alpha: 0.24)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      labelStyle: textTheme.labelLarge,
      secondaryLabelStyle: textTheme.labelLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size(0, 56),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: palette.outline.withValues(alpha: 0.42)),
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: textTheme.titleSmall,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.accentStrong,
        textStyle: textTheme.titleSmall,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.accentSoft.withValues(alpha: isDark ? 0.42 : 0.56);
          }
          return palette.surface.withValues(alpha: 0.72);
        }),
        foregroundColor: WidgetStateProperty.all(colorScheme.onSurface),
        side: WidgetStateProperty.all(
          BorderSide(color: palette.outline.withValues(alpha: 0.3)),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        textStyle: WidgetStateProperty.all(textTheme.titleSmall),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.onPrimary;
        }
        return palette.surfaceStrong;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return palette.accent;
        }
        return palette.surfaceMuted;
      }),
      trackOutlineColor: WidgetStateProperty.all(
        palette.outline.withValues(alpha: 0.18),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceStrong.withValues(alpha: isDark ? 0.88 : 0.95),
      hintStyle: textTheme.bodyMedium?.copyWith(color: palette.label),
      labelStyle: textTheme.bodyMedium?.copyWith(color: palette.label),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: _inputBorder(palette.outline),
      enabledBorder: _inputBorder(palette.outline.withValues(alpha: 0.64)),
      focusedBorder: _inputBorder(palette.accent),
      errorBorder: _inputBorder(colorScheme.error),
      focusedErrorBorder: _inputBorder(colorScheme.error),
    ),
    dividerTheme: DividerThemeData(
      color: palette.outline.withValues(alpha: 0.18),
      space: 1,
      thickness: 1,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: textTheme.titleMedium,
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: palette.label),
      iconColor: palette.accentStrong,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark
          ? const Color(0xFF332622)
          : const Color(0xFF3A2B25),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}

TextTheme _buildTextTheme(TextTheme base, Color onSurface, Color label) {
  TextStyle? serif(
    TextStyle? style, {
    FontWeight weight = FontWeight.w700,
    double? size,
    double? letterSpacing,
    double height = 1.14,
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
    double height = 1.48,
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
    displayLarge: serif(base.displayLarge, size: 56, letterSpacing: -1.8),
    displayMedium: serif(base.displayMedium, size: 46, letterSpacing: -1.3),
    displaySmall: serif(base.displaySmall, size: 38, letterSpacing: -1.0),
    headlineLarge: serif(base.headlineLarge, size: 34, letterSpacing: -0.9),
    headlineMedium: serif(base.headlineMedium, size: 30, letterSpacing: -0.7),
    headlineSmall: serif(base.headlineSmall, size: 24, letterSpacing: -0.3),
    titleLarge: serif(base.titleLarge, size: 22, letterSpacing: -0.2),
    titleMedium: sans(base.titleMedium, weight: FontWeight.w700, size: 17),
    titleSmall: sans(base.titleSmall, weight: FontWeight.w700, size: 14),
    bodyLarge: sans(base.bodyLarge, size: 16),
    bodyMedium: sans(base.bodyMedium, size: 15),
    bodySmall: sans(base.bodySmall, size: 13, color: label, height: 1.42),
    labelLarge: sans(base.labelLarge, weight: FontWeight.w700, size: 13),
    labelMedium: sans(base.labelMedium, weight: FontWeight.w600, size: 12),
    labelSmall: sans(
      base.labelSmall,
      weight: FontWeight.w600,
      size: 11,
      color: label,
      height: 1.28,
    ),
  );
}

OutlineInputBorder _inputBorder(Color color) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: BorderSide(color: color, width: 1.1),
  );
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
      backdropTop: Color(0xFFFBEFE9),
      backdropBottom: Color(0xFFE6D3C7),
      backdropAccent: Color(0xFFF5DDD2),
      ambientGlow: Color(0xFFF3B289),
      surface: Color(0xFFFAF3EE),
      surfaceStrong: Color(0xFFFFFBF8),
      surfaceMuted: Color(0xFFF4E4DA),
      outline: Color(0xFFD8C0B6),
      label: Color(0xFF8D756C),
      accent: Color(0xFFE6886D),
      accentStrong: Color(0xFFCB694B),
      accentSoft: Color(0xFFF5C2AE),
      highlight: Color(0xFFF2C46E),
      highlightStrong: Color(0xFFE39A4A),
      shadowColor: Color(0xFF50342D),
    );
  }

  factory CuratorPalette.dark() {
    return const CuratorPalette(
      backdropTop: Color(0xFF1B1413),
      backdropBottom: Color(0xFF0F0B0A),
      backdropAccent: Color(0xFF33211D),
      ambientGlow: Color(0xFFE18E6E),
      surface: Color(0xFF201816),
      surfaceStrong: Color(0xFF2C221F),
      surfaceMuted: Color(0xFF3B2B27),
      outline: Color(0xFF6A5148),
      label: Color(0xFFD2B6AB),
      accent: Color(0xFFF0A088),
      accentStrong: Color(0xFFF2B56D),
      accentSoft: Color(0xFF82493E),
      highlight: Color(0xFFF2C77B),
      highlightStrong: Color(0xFFE69A48),
      shadowColor: Colors.black,
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
