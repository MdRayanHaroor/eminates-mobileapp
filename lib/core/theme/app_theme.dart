import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Fintech Palette (Light) - Enhanced
  static const Color _primaryLight = Color(0xFF1565C0); // Rich Blue
  static const Color _primaryContainerLight = Color(0xFFE3F2FD); // Light Blue
  static const Color _secondaryLight = Color(0xFF00695C); // Teal
  static const Color _secondaryContainerLight = Color(0xFFE0F2F1); // Soft Teal
  static const Color _tertiaryLight = Color(0xFFEF6C00); // Orange
  static const Color _tertiaryContainerLight = Color(0xFFFFF3E0); // Soft Orange
  static const Color _scaffoldBackgroundLight = Color(0xFFF0F4F8); // Blue-ish Grey (More colorful than slate)

  // Premium Fintech Palette (Dark)
  static const Color _primaryDark = Color(0xFF90CAF9); // Light Blue
  static const Color _primaryContainerDark = Color(0xFF0D47A1);
  static const Color _secondaryDark = Color(0xFF80CBC4); // Light Teal
  static const Color _secondaryContainerDark = Color(0xFF004D40);
  static const Color _scaffoldBackgroundDark = Color(0xFF0A1929); // Deep Navy

  static ThemeData get lightTheme {
    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: _primaryLight,
        primaryContainer: _primaryContainerLight,
        secondary: _secondaryLight,
        secondaryContainer: _secondaryContainerLight,
        tertiary: _tertiaryLight,
        tertiaryContainer: _tertiaryContainerLight,
        appBarColor: Colors.white, 
        error: Color(0xFFB00020),
      ),
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 10, // Increased blend for more color
      subThemesData: FlexSubThemesData(
        blendOnLevel: 20,
        blendOnColors: true, // Blend colors into surfaces
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        defaultRadius: 16.0,
        inputDecoratorIsFilled: true,
        inputDecoratorFillColor: Colors.white,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorUnfocusedBorderIsColored: false,
        inputDecoratorUnfocusedHasBorder: true,
        inputDecoratorSchemeColor: SchemeColor.primary,
        fabUseShape: true,
        fabAlwaysCircular: true,
        chipSchemeColor: SchemeColor.primary,
        cardElevation: 3, // Higher elevation
      ),
      keyColors: const FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
        keepPrimary: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.outfit().fontFamily ?? GoogleFonts.inter().fontFamily,
      scaffoldBackground: _scaffoldBackgroundLight,
    ).copyWith(
      cardColor: Colors.white, 
      scaffoldBackgroundColor: _scaffoldBackgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: _scaffoldBackgroundLight,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1E293B)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
          borderSide: BorderSide(color: _primaryLight, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        floatingLabelStyle: const TextStyle(color: _primaryLight, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: _primaryDark,
        primaryContainer: _primaryContainerDark,
        secondary: _secondaryDark,
        secondaryContainer: _secondaryContainerDark,
        tertiary: _tertiaryLight, 
        tertiaryContainer: _tertiaryContainerLight,
        appBarColor: _scaffoldBackgroundDark,
        error: Color(0xFFCF6679),
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 10,
      subThemesData: FlexSubThemesData(
        blendOnLevel: 20,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        defaultRadius: 16.0,
        inputDecoratorIsFilled: true,
        inputDecoratorFillColor: const Color(0xFF1E293B),
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorUnfocusedHasBorder: false,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.outfit().fontFamily ?? GoogleFonts.inter().fontFamily,
      scaffoldBackground: _scaffoldBackgroundDark,
    ).copyWith(
      cardColor: const Color(0xFF1E293B), // Explicitly set card color
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
          borderSide: BorderSide(color: _primaryDark, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}
