import 'package:flutter/material.dart';

ThemeData buildCuratorTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final palette = isDark ? CuratorPalette.dark() : CuratorPalette.light();
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: palette.accent,
    onPrimary: isDark ? const Color(0xFF1D150D) : Colors.white,
    secondary: palette.accentStrong,
    onSecondary: isDark ? const Color(0xFF1D150D) : Colors.white,
    tertiary: palette.accentSoft,
    onTertiary: const Color(0xFF2A1D0E),
    error: const Color(0xFFB54A3A),
    onError: Colors.white,
    surface: palette.surface,
    onSurface: isDark ? const Color(0xFFF8EEDF) : const Color(0xFF2E261D),
    surfaceContainerHighest: palette.surfaceStrong,
    onSurfaceVariant: palette.label,
    outline: palette.outline,
    outlineVariant: palette.outline.withValues(alpha: 0.45),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: isDark ? const Color(0xFFF4E8D6) : const Color(0xFF241D17),
    onInverseSurface: isDark
        ? const Color(0xFF241D17)
        : const Color(0xFFF4E8D6),
    inversePrimary: isDark ? const Color(0xFFFBE1B2) : const Color(0xFFA57337),
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
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: palette.surfaceStrong.withValues(alpha: isDark ? 0.92 : 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: palette.outline.withValues(alpha: 0.55)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surfaceMuted,
      selectedColor: palette.accentSoft,
      side: BorderSide(color: palette.outline.withValues(alpha: 0.35)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelStyle: textTheme.labelLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        minimumSize: const Size.fromHeight(58),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceStrong.withValues(alpha: isDark ? 0.8 : 0.92),
      hintStyle: textTheme.bodyMedium?.copyWith(color: palette.label),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: _inputBorder(palette.outline),
      enabledBorder: _inputBorder(palette.outline.withValues(alpha: 0.85)),
      focusedBorder: _inputBorder(palette.accent),
      errorBorder: _inputBorder(colorScheme.error),
      focusedErrorBorder: _inputBorder(colorScheme.error),
    ),
    dividerTheme: DividerThemeData(
      color: palette.outline.withValues(alpha: 0.28),
      space: 28,
      thickness: 1,
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
  }) {
    return style?.copyWith(
      fontFamily: 'GowunBatang',
      fontWeight: weight,
      fontSize: size,
      letterSpacing: letterSpacing,
      color: onSurface,
      height: 1.18,
    );
  }

  TextStyle? sans(
    TextStyle? style, {
    FontWeight weight = FontWeight.w400,
    double? size,
    double? letterSpacing,
    Color? color,
  }) {
    return style?.copyWith(
      fontFamily: 'IBMPlexSansKR',
      fontWeight: weight,
      fontSize: size,
      letterSpacing: letterSpacing,
      color: color ?? onSurface,
      height: 1.5,
    );
  }

  return base.copyWith(
    displayLarge: serif(base.displayLarge, size: 54, letterSpacing: -1.6),
    displayMedium: serif(base.displayMedium, size: 44, letterSpacing: -1.2),
    displaySmall: serif(base.displaySmall, size: 36, letterSpacing: -0.8),
    headlineLarge: serif(base.headlineLarge, size: 32, letterSpacing: -0.8),
    headlineMedium: serif(base.headlineMedium, size: 28, letterSpacing: -0.5),
    headlineSmall: serif(base.headlineSmall, size: 24),
    titleLarge: serif(base.titleLarge, size: 21),
    titleMedium: sans(base.titleMedium, weight: FontWeight.w700, size: 17),
    titleSmall: sans(base.titleSmall, weight: FontWeight.w700, size: 15),
    bodyLarge: sans(base.bodyLarge, size: 16),
    bodyMedium: sans(base.bodyMedium, size: 15),
    bodySmall: sans(base.bodySmall, size: 13, color: label),
    labelLarge: sans(base.labelLarge, weight: FontWeight.w700, size: 13),
    labelMedium: sans(base.labelMedium, weight: FontWeight.w600, size: 12),
    labelSmall: sans(
      base.labelSmall,
      weight: FontWeight.w600,
      size: 11,
      color: label,
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
  });

  factory CuratorPalette.light() {
    return const CuratorPalette(
      backdropTop: Color(0xFFF7EBD9),
      backdropBottom: Color(0xFFE4D1B6),
      backdropAccent: Color(0xFFFCEFD8),
      ambientGlow: Color(0xFFF6D8A5),
      surface: Color(0xFFF8F0E3),
      surfaceStrong: Color(0xFFFFFAF3),
      surfaceMuted: Color(0xFFF1E1C9),
      outline: Color(0xFFCFB79A),
      label: Color(0xFF7C6957),
      accent: Color(0xFFBF8B49),
      accentStrong: Color(0xFFA47235),
      accentSoft: Color(0xFFF2D6A6),
    );
  }

  factory CuratorPalette.dark() {
    return const CuratorPalette(
      backdropTop: Color(0xFF191512),
      backdropBottom: Color(0xFF0F0C0A),
      backdropAccent: Color(0xFF2C241D),
      ambientGlow: Color(0xFFB78549),
      surface: Color(0xFF1B1714),
      surfaceStrong: Color(0xFF26201B),
      surfaceMuted: Color(0xFF312821),
      outline: Color(0xFF61503E),
      label: Color(0xFFC5B39E),
      accent: Color(0xFFE1BA84),
      accentStrong: Color(0xFFF2D0A4),
      accentSoft: Color(0xFF9F7A4E),
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
    );
  }

  @override
  CuratorPalette lerp(ThemeExtension<CuratorPalette>? other, double t) {
    if (other is! CuratorPalette) {
      return this;
    }

    return CuratorPalette(
      backdropTop: Color.lerp(backdropTop, other.backdropTop, t) ?? backdropTop,
      backdropBottom:
          Color.lerp(backdropBottom, other.backdropBottom, t) ?? backdropBottom,
      backdropAccent:
          Color.lerp(backdropAccent, other.backdropAccent, t) ?? backdropAccent,
      ambientGlow: Color.lerp(ambientGlow, other.ambientGlow, t) ?? ambientGlow,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceStrong:
          Color.lerp(surfaceStrong, other.surfaceStrong, t) ?? surfaceStrong,
      surfaceMuted:
          Color.lerp(surfaceMuted, other.surfaceMuted, t) ?? surfaceMuted,
      outline: Color.lerp(outline, other.outline, t) ?? outline,
      label: Color.lerp(label, other.label, t) ?? label,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentStrong:
          Color.lerp(accentStrong, other.accentStrong, t) ?? accentStrong,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t) ?? accentSoft,
    );
  }
}
