import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: Color(0xFF1565C0), // Deep Blue
        primaryContainer: Color(0xFF90CAF9),
        secondary: Color(0xFF1565C0),
        secondaryContainer: Color(0xFF90CAF9),
        tertiary: Color(0xFF1565C0),
        tertiaryContainer: Color(0xFF90CAF9),
        appBarColor: Color(0xFF90CAF9),
        error: Color(0xFFB00020),
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 2, // Reduced blend level
      subThemesData: FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        defaultRadius: 12.0, // Global radius
        inputDecoratorIsFilled: true,
        inputDecoratorFillColor: Colors.white,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorUnfocusedBorderIsColored: false,
        inputDecoratorUnfocusedHasBorder: true,
        inputDecoratorSchemeColor: SchemeColor.primary,
        inputDecoratorBackgroundAlpha: 255, // Opaque
      ),
      keyColors: const FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackground: const Color(0xFFF5F7FA), // Ghost White
    ).copyWith(
      // Subtle grey border for inputs in light mode
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          borderSide: BorderSide(color: Color(0xFFEEEEEE)), // Colors.grey.shade200
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          borderSide: BorderSide(color: Color(0xFFEEEEEE)), // Colors.grey.shade200
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: Color(0xFF5E81AC), // Muted Blue
        primaryContainer: Color(0xFF2E3440),
        secondary: Color(0xFF5E81AC),
        secondaryContainer: Color(0xFF2E3440),
        tertiary: Color(0xFF5E81AC),
        tertiaryContainer: Color(0xFF2E3440),
        appBarColor: Color(0xFF2E3440),
        error: Color(0xFFCF6679),
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 5, // Reduced blend level
      subThemesData: FlexSubThemesData(
        blendOnLevel: 20,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        defaultRadius: 12.0, // Global radius
        inputDecoratorIsFilled: true,
        inputDecoratorFillColor: const Color(0xFF1E2329), // Gunmetal
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorUnfocusedHasBorder: false, // No visible border
      ),
      keyColors: const FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackground: const Color(0xFF121418), // Deep Midnight Slate
    ).copyWith(
      cardColor: const Color(0xFF1E2329), // Gunmetal
      // No visible border for inputs in dark mode
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1E2329),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          borderSide: BorderSide(color: Color(0xFF5E81AC), width: 2),
        ),
      ),
    );
  }
}
