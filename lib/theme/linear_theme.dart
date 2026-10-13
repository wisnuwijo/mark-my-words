import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LinearColors {
  // Linear Dark (Obsidian)
  static const Color darkBgApp = Color(0xFF08090A);
  static const Color darkBgSidebar = Color(0xFF0D0E12);
  static const Color darkBgSurface = Color(0xFF12141A);
  static const Color darkBgSurfaceElevated = Color(0xFF181A22);
  static const Color darkBgCode = Color(0xFF0B0D11);
  static const Color darkBgKbd = Color(0xFF16181F);
  
  static Color darkBorderSubtle = Colors.white.withValues(alpha: 0.07);
  static Color darkBorderDefault = Colors.white.withValues(alpha: 0.12);
  static Color darkBorderHighlight = Colors.white.withValues(alpha: 0.18);
  static Color darkSurfaceHover = Colors.white.withValues(alpha: 0.05);
  static Color darkSurfaceActive = Colors.white.withValues(alpha: 0.09);

  static const Color darkTextPrimary = Color(0xFFF7F8F8);
  static const Color darkTextSecondary = Color(0xFF8A8F98);
  static const Color darkTextTertiary = Color(0xFF626772);
  static const Color darkTextMuted = Color(0xFF434651);

  // Linear Light
  static const Color lightBgApp = Color(0xFFF7F8F9);
  static const Color lightBgSidebar = Color(0xFFF0F2F5);
  static const Color lightBgSurface = Color(0xFFFFFFFF);
  static const Color lightBgSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightBgCode = Color(0xFFF3F4F6);
  static const Color lightBgKbd = Color(0xFFEAEDF1);

  static Color lightBorderSubtle = Colors.black.withValues(alpha: 0.06);
  static Color lightBorderDefault = Colors.black.withValues(alpha: 0.10);
  static Color lightBorderHighlight = Colors.black.withValues(alpha: 0.15);
  static Color lightSurfaceHover = Colors.black.withValues(alpha: 0.04);
  static Color lightSurfaceActive = Colors.black.withValues(alpha: 0.08);

  static const Color lightTextPrimary = Color(0xFF111418);
  static const Color lightTextSecondary = Color(0xFF575E6B);
  static const Color lightTextTertiary = Color(0xFF838A96);
  static const Color lightTextMuted = Color(0xFFA6ADB8);

  // Signature Accents
  static const Color accent = Color(0xFF5E6AD2);
  static const Color accentHover = Color(0xFF6F7DE3);
  static Color accentSubtle = const Color(0xFF5E6AD2).withValues(alpha: 0.15);
  static Color accentBorder = const Color(0xFF5E6AD2).withValues(alpha: 0.35);

  static const Color cyan = Color(0xFF2EE0D3);
  static const Color blue = Color(0xFF00A3FF);
  static const Color green = Color(0xFF27C93F);
  static const Color amber = Color(0xFFF2994A);
  static const Color red = Color(0xFFFF5F56);
  static const Color purple = Color(0xFF9D5BD2);

  // macOS Traffic Lights
  static const Color trafficClose = Color(0xFFFF5F56);
  static const Color trafficMin = Color(0xFFFFBD2E);
  static const Color trafficMax = Color(0xFF27C93F);
}

enum ContentWidthMode {
  compact(640),
  standard(760),
  wide(960);

  final double maxWidth;
  const ContentWidthMode(this.maxWidth);
}

enum FontSizeScale {
  small(13.5),
  medium(15.0),
  large(16.5);

  final double baseSize;
  const FontSizeScale(this.baseSize);
}

class LinearTheme {
  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: LinearColors.darkBgApp,
      cardColor: LinearColors.darkBgSurface,
      dividerColor: LinearColors.darkBorderSubtle,
      colorScheme: const ColorScheme.dark(
        primary: LinearColors.accent,
        surface: LinearColors.darkBgSurface,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.apply(
          bodyColor: LinearColors.darkTextPrimary,
          displayColor: LinearColors.darkTextPrimary,
        ),
      ),
    );
  }

  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: LinearColors.lightBgApp,
      cardColor: LinearColors.lightBgSurface,
      dividerColor: LinearColors.lightBorderSubtle,
      colorScheme: const ColorScheme.light(
        primary: LinearColors.accent,
        surface: LinearColors.lightBgSurface,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme.apply(
          bodyColor: LinearColors.lightTextPrimary,
          displayColor: LinearColors.lightTextPrimary,
        ),
      ),
    );
  }
}
