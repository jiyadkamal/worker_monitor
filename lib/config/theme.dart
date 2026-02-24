import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _seed = Color(0xFF1565C0);

  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.light,
  );

  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.dark,
  );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightScheme,
      textTheme: GoogleFonts.interTextTheme(),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: lightScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: lightScheme.surface,
        foregroundColor: lightScheme.onSurface,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkScheme,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: darkScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: darkScheme.surface,
        foregroundColor: darkScheme.onSurface,
      ),
    );
  }
}
