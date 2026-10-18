// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // CSS Design Tokens
  static const Color canvas = Color(0xFFF7F5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color stone = Color(0xFFEFECE6);
  static const Color moss = Color(0xFF354A39);
  static const Color mossHover = Color(0xFF2B3D2F);
  static const Color sage = Color(0xFFB3C5B8);
  static const Color terra = Color(0xFFD07A5F);
  static const Color amber = Color(0xFFD99B4E);
  static const Color indigo = Color(0xFF5B6B82);
  static const Color teal = Color(0xFF528078);
  static const Color danger = Color(0xFFC85A53);
  static const Color ink = Color(0xFF1E201D);
  static const Color muted = Color(0xFF787A74);
  static const Color line = Color.fromRGBO(120, 122, 116, 0.14);

  // Backwards compatibility aliases
  static const Color cream = canvas;
  static const Color cardBackground = surface;
  static const Color mossGreen = moss;
  static const Color terracotta = terra;
  static const Color red = danger;
  static const Color textDark = ink;
  static const Color textLight = muted;

  static const List<Color> residentColors = [
    Color(0xFFD07A5F),
    Color(0xFF528078),
    Color(0xFFD99B4E),
    Color(0xFF5B6B82),
  ];

  // Box Model Tokens
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: line),
    boxShadow: const [
      BoxShadow(
        color: Color.fromRGBO(30, 32, 29, 0.03),
        blurRadius: 20,
        offset: Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get canvasGradientDecoration => const BoxDecoration(
    color: canvas,
    gradient: RadialGradient(
      center: Alignment(1.0, -1.0),
      radius: 1.2,
      colors: [
        Colors.white,
        canvas,
      ],
      stops: [0.0, 0.7],
    ),
  );

  // Cached Typography Styles (Prevents garbage collection thrashing in build methods)
  static final TextStyle microHeader = GoogleFonts.instrumentSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
    color: muted,
  );
  static final TextStyle microStyle = microHeader;

  static final TextStyle monoSmall = GoogleFonts.dmMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ink,
  );
  static final TextStyle monoMedium = GoogleFonts.dmMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ink,
  );
  static final TextStyle monoLarge = GoogleFonts.dmMono(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: ink,
  );
  static final TextStyle monoExtraLarge = GoogleFonts.dmMono(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
    color: ink,
  );
  static final TextStyle monoHuge = GoogleFonts.dmMono(
    fontSize: 44,
    fontWeight: FontWeight.w400,
    letterSpacing: -1.0,
    color: ink,
  );

  static final TextStyle sansTiny = GoogleFonts.instrumentSans(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: ink,
  );
  static final TextStyle sansSmall = GoogleFonts.instrumentSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ink,
  );
  static final TextStyle sansLabel = GoogleFonts.instrumentSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: muted,
  );
  static final TextStyle sansMedium = GoogleFonts.instrumentSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ink,
  );
  static final TextStyle sansBold = GoogleFonts.instrumentSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ink,
  );
  static final TextStyle sansHeader = GoogleFonts.instrumentSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: ink,
  );

  static final TextStyle titleSmall = GoogleFonts.newsreader(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ink,
  );
  static final TextStyle titleMedium = GoogleFonts.newsreader(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: ink,
  );
  static final TextStyle titleLarge = GoogleFonts.newsreader(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.56,
    color: ink,
  );
  static final TextStyle titleDisplay = GoogleFonts.newsreader(
    fontSize: 34,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.68,
    color: ink,
  );

  static TextStyle titleStyle({double fontSize = 28, FontWeight fontWeight = FontWeight.w400, Color? color, FontStyle? fontStyle}) {
    if (fontSize == 28 && fontWeight == FontWeight.w400 && color == null && fontStyle == null) {
      return titleLarge;
    }
    if (fontSize == 20 && fontWeight == FontWeight.w400 && color == null && fontStyle == null) {
      return titleMedium;
    }
    return GoogleFonts.newsreader(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.02 * fontSize,
      color: color ?? ink,
      fontStyle: fontStyle,
    );
  }

  static TextStyle uiStyle({double fontSize = 14, FontWeight fontWeight = FontWeight.w400, Color? color}) {
    if (fontSize == 14 && fontWeight == FontWeight.w400 && color == null) {
      return sansMedium;
    }
    if (fontSize == 12 && fontWeight == FontWeight.w400 && color == null) {
      return sansSmall;
    }
    if (fontSize == 14 && fontWeight == FontWeight.w600 && color == null) {
      return sansBold;
    }
    return GoogleFonts.instrumentSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? ink,
    );
  }

  static TextStyle monoStyle({double fontSize = 14, FontWeight fontWeight = FontWeight.w400, Color? color, double? letterSpacing}) {
    if (fontSize == 14 && fontWeight == FontWeight.w400 && color == null && letterSpacing == null) {
      return monoMedium;
    }
    if (fontSize == 12 && fontWeight == FontWeight.w400 && color == null && letterSpacing == null) {
      return monoSmall;
    }
    return GoogleFonts.dmMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? ink,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: canvas,
      primaryColor: moss,
      colorScheme: const ColorScheme.light(
        primary: moss,
        surface: surface,
        error: danger,
        onPrimary: Colors.white,
        onSurface: ink,
      ),
      textTheme: ThemeData.light().textTheme.copyWith(
        displayLarge: GoogleFonts.newsreader(color: ink, fontWeight: FontWeight.w400),
        displayMedium: GoogleFonts.newsreader(color: ink, fontWeight: FontWeight.w400),
        headlineLarge: GoogleFonts.newsreader(color: ink, fontWeight: FontWeight.w400),
        headlineMedium: GoogleFonts.newsreader(color: ink, fontWeight: FontWeight.w400),
        headlineSmall: GoogleFonts.newsreader(color: ink, fontWeight: FontWeight.w400),
        titleLarge: GoogleFonts.newsreader(color: ink, fontWeight: FontWeight.w400),
        titleMedium: GoogleFonts.instrumentSans(color: ink, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.instrumentSans(color: ink, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.instrumentSans(color: ink, fontWeight: FontWeight.w400),
        bodySmall: GoogleFonts.instrumentSans(color: muted, fontWeight: FontWeight.w400),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: moss,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.instrumentSans(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: surface,
          side: const BorderSide(color: line),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.instrumentSans(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: canvas,
        hintStyle: GoogleFonts.instrumentSans(color: muted.withValues(alpha: 0.7), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: line),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: moss.withValues(alpha: 0.4), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: line),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}