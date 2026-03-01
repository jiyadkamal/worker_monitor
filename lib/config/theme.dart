import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _sapphireBlue = Color(0xFF004E92);
  static const _slateGray = Color(0xFF2C3E50);

  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: _sapphireBlue,
    secondary: _slateGray,
    brightness: Brightness.light,
    surface: const Color(0xFFF8FAFC),
  );

  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: _sapphireBlue,
    secondary: _slateGray,
    brightness: Brightness.dark,
    surface: const Color(0xFF0F172A),
  );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightScheme,
      textTheme: GoogleFonts.outfitTextTheme(),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: TextStyle(color: lightScheme.onSurfaceVariant),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightScheme.primary,
          foregroundColor: lightScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: lightScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: lightScheme.onSurface,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: lightScheme.onSurface,
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkScheme,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkScheme.primary,
          foregroundColor: darkScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: darkScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: darkScheme.onSurface,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkScheme.onSurface,
        ),
      ),
    );
  }
}
