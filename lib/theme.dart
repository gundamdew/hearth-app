// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color cream = Color(0xFFF7F5F0);
  static const Color mossGreen = Color(0xFF374936);
  static const Color terracotta = Color(0xFFE4A99B);
  static const Color sage = Color(0xFFB3C5B8);
  static const Color amber = Color(0xFFE5A93D);
  static const Color red = Color(0xFFD95D5D);
  
  static const Color textDark = Color(0xFF2C2A28);
  static const Color textLight = Color(0xFF7A756D);
  static const Color cardBackground = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final textTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.libreBaskerville(color: textDark, fontWeight: FontWeight.w400),
      displayMedium: GoogleFonts.libreBaskerville(color: textDark, fontWeight: FontWeight.w400),
      headlineLarge: GoogleFonts.libreBaskerville(color: textDark, fontWeight: FontWeight.w400),
      headlineMedium: GoogleFonts.libreBaskerville(color: textDark, fontWeight: FontWeight.w400),
      displaySmall: GoogleFonts.dmMono(color: textDark),
    ).apply(bodyColor: textDark, displayColor: textDark);

    return ThemeData(
      scaffoldBackgroundColor: cream,
      primaryColor: mossGreen,
      colorScheme: const ColorScheme.light(
        primary: mossGreen,
        surface: cardBackground,
        error: red,
        onPrimary: Colors.white,
        onSurface: textDark,
      ),
      textTheme: textTheme,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textDark,
          textStyle: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mossGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 4,
        shadowColor: textDark.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: textLight.withValues(alpha: 0.05)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        hintStyle: TextStyle(color: textLight.withValues(alpha: 0.6), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textLight.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: mossGreen, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}