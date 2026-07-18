import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ColorScheme light = ColorScheme.light(
    brightness: Brightness.light,

    // Brand / primary actions
    primary: Color.fromARGB(255, 216, 42, 59),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color.fromARGB(255, 221, 102, 116),
    onPrimaryContainer: Color.fromARGB(255, 216, 42, 59),

    // Informational actions and secondary controls
    secondary: Color(0xFF1769AA),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDCEAF6),
    onSecondaryContainer: Color(0xFF062F50),

    // Positive operational accent
    tertiary: Color(0xFF16854B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD8F2E3),
    onTertiaryContainer: Color(0xFF06351E),

    // Errors and critical alerts
    error: Color(0xFFC81E2A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD9),
    onErrorContainer: Color(0xFF68000A),

    // Main surfaces
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF171A1F),
    surfaceDim: Color(0xFFE1E5E9),
    surfaceBright: Color(0xFFFFFFFF),

    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8F9FA),
    surfaceContainer: Color(0xFFF4F6F8),
    surfaceContainerHigh: Color(0xFFEEF1F4),
    surfaceContainerHighest: Color(0xFFE8EBEF),

    onSurfaceVariant: Color(0xFF56606D),

    // Borders and dividers
    outline: Color(0xFF7D8793),
    outlineVariant: Color(0xFFD9DEE5),

    // Elevation and overlays
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    // Inverse components
    inverseSurface: Color(0xFF2C3036),
    onInverseSurface: Color(0xFFF3F5F7),
    inversePrimary: Color(0xFFFF6B73),

    surfaceTint: Color(0xFFE30613),
  );

  static const ColorScheme dark = ColorScheme.dark(
    brightness: Brightness.dark,

    // Slightly brighter red for dark backgrounds
    primary: Color.fromARGB(255, 216, 42, 59),
    onPrimary: Color(0xFF3D0005),
    primaryContainer: Color(0xFF5D1017),
    onPrimaryContainer: Color(0xFFFFDADB),

    // Informational actions and secondary controls
    secondary: Color(0xFF55A7E0),
    onSecondary: Color(0xFF002F4D),
    secondaryContainer: Color(0xFF123F5C),
    onSecondaryContainer: Color(0xFFD1EBFF),

    // Positive operational accent
    tertiary: Color(0xFF40C77A),
    onTertiary: Color(0xFF00391D),
    tertiaryContainer: Color(0xFF0D4D2C),
    onTertiaryContainer: Color(0xFFC5F6D8),

    // Errors and critical alerts
    error: Color(0xFFFF5964),
    onError: Color(0xFF520008),
    errorContainer: Color(0xFF72151D),
    onErrorContainer: Color(0xFFFFDADB),

    // Main surfaces
    surface: Color(0xFF161B22),
    onSurface: Color(0xFFF3F5F7),
    surfaceDim: Color(0xFF0D1117),
    surfaceBright: Color(0xFF303946),

    surfaceContainerLowest: Color(0xFF090D12),
    surfaceContainerLow: Color(0xFF11161D),
    surfaceContainer: Color(0xFF161B22),
    surfaceContainerHigh: Color(0xFF1C222B),
    surfaceContainerHighest: Color(0xFF252D38),

    onSurfaceVariant: Color(0xFFB2BAC5),

    // Borders and dividers
    outline: Color(0xFF818B98),
    outlineVariant: Color(0xFF303946),

    // Elevation and overlays
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    // Inverse components
    inverseSurface: Color(0xFFE8EBEF),
    onInverseSurface: Color(0xFF20252B),
    inversePrimary: Color(0xFFC9000C),

    surfaceTint: Color(0xFFFF3944),
  );
}