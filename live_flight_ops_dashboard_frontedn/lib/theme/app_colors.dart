import 'package:flutter/material.dart';

/// The semantic color palette used by the flight operations dashboard.
///
/// Use [AppColors.light] or [AppColors.dark] based on the application's
/// current brightness rather than referencing raw color values in widgets.
@immutable
class AppColors {
  const AppColors._({
    required this.brandPrimary,
    required this.brandPrimaryHover,
    required this.brandPrimarySoft,
    required this.background,
    required this.surface,
    required this.surfaceSecondary,
    required this.surfaceElevated,
    required this.surfaceHover,
    required this.surfaceSelected,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.textOnPrimary,
    required this.statusNormal,
    required this.statusInfo,
    required this.statusWarning,
    required this.statusCritical,
    required this.statusDiverted,
    required this.statusUnknown,
    required this.mapBackground,
    required this.mapLand,
    required this.mapWater,
    required this.mapBorder,
    required this.mapRoute,
    required this.mapAircraft,
    required this.mapAircraftSelected,
  });

  static const AppColors light = AppColors._(
    brandPrimary: Color(0xFFE30613),
    brandPrimaryHover: Color(0xFFC9000C),
    brandPrimarySoft: Color(0xFFFDEBED),
    background: Color(0xFFF4F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFF8F9FA),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceHover: Color(0xFFEEF1F4),
    surfaceSelected: Color(0xFFFDEBED),
    border: Color(0xFFD9DEE5),
    borderSubtle: Color(0xFFE8EBEF),
    textPrimary: Color(0xFF171A1F),
    textSecondary: Color(0xFF56606D),
    textMuted: Color(0xFF7D8793),
    textDisabled: Color(0xFFAAB1BA),
    textOnPrimary: Color(0xFFFFFFFF),
    statusNormal: Color(0xFF16854B),
    statusInfo: Color(0xFF1769AA),
    statusWarning: Color(0xFFD97706),
    statusCritical: Color(0xFFC81E2A),
    statusDiverted: Color(0xFF7C3AED),
    statusUnknown: Color(0xFF8B95A1),
    mapBackground: Color(0xFFE8EDF2),
    mapLand: Color(0xFFF7F8FA),
    mapWater: Color(0xFFDCEAF3),
    mapBorder: Color(0xFFC8D0D8),
    mapRoute: Color(0xFFE30613),
    mapAircraft: Color(0xFF20252B),
    mapAircraftSelected: Color(0xFFE30613),
  );

  static const AppColors dark = AppColors._(
    brandPrimary: Color(0xFFFF3944),
    brandPrimaryHover: Color(0xFFFF5964),
    brandPrimarySoft: Color(0xFF3A171C),
    background: Color(0xFF0D1117),
    surface: Color(0xFF161B22),
    surfaceSecondary: Color(0xFF1C222B),
    surfaceElevated: Color(0xFF232A34),
    surfaceHover: Color(0xFF252D38),
    surfaceSelected: Color(0xFF3A171C),
    border: Color(0xFF303946),
    borderSubtle: Color(0xFF252D37),
    textPrimary: Color(0xFFF3F5F7),
    textSecondary: Color(0xFFB2BAC5),
    textMuted: Color(0xFF818B98),
    textDisabled: Color(0xFF596270),
    textOnPrimary: Color(0xFFFFFFFF),
    statusNormal: Color(0xFF40C77A),
    statusInfo: Color(0xFF55A7E0),
    statusWarning: Color(0xFFF3A83B),
    statusCritical: Color(0xFFFF5964),
    statusDiverted: Color(0xFFA986FF),
    statusUnknown: Color(0xFF76818E),
    mapBackground: Color(0xFF101820),
    mapLand: Color(0xFF18232C),
    mapWater: Color(0xFF0B202C),
    mapBorder: Color(0xFF35434E),
    mapRoute: Color(0xFFFF3944),
    mapAircraft: Color(0xFFE5E9ED),
    mapAircraftSelected: Color(0xFFFF3944),
  );

  final Color brandPrimary;
  final Color brandPrimaryHover;
  final Color brandPrimarySoft;

  final Color background;
  final Color surface;
  final Color surfaceSecondary;
  final Color surfaceElevated;
  final Color surfaceHover;
  final Color surfaceSelected;

  final Color border;
  final Color borderSubtle;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color textOnPrimary;

  final Color statusNormal;
  final Color statusInfo;
  final Color statusWarning;
  final Color statusCritical;
  final Color statusDiverted;
  final Color statusUnknown;

  final Color mapBackground;
  final Color mapLand;
  final Color mapWater;
  final Color mapBorder;
  final Color mapRoute;
  final Color mapAircraft;
  final Color mapAircraftSelected;
}
