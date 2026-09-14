import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Palette
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceBorder = Color(0xFFE9ECEF);
  static const Color primaryText = Color(0xFF1A1A1A);
  static const Color secondaryText = Color(0xFF5F6368);
  static const Color primaryAccent = Color(0xFF1B6FB0); // Vibrant Blue accent
  static const Color primaryAccentLight = Color(0xFFE8F1F9);

  // Confidence Badges
  static const Color confidenceHigh = Color(0xFF2E7D32);   // Green
  static const Color confidenceMedium = Color(0xFFF9A825); // Amber
  static const Color confidenceLow = Color(0xFFC62828);    // Red

  // Disabled State
  static const Color disabledColor = Color(0xFF9E9E9E);
  static const Color disabledBackground = Color(0xFFEEEEEE);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryAccent,
      colorScheme: ColorScheme.light(
        primary: primaryAccent,
        surface: surface,
        onSurface: primaryText,
        secondary: primaryAccent,
      ),
      textTheme: GoogleFonts.notoSansTextTheme().copyWith(
        displayLarge: GoogleFonts.notoSans(
          color: primaryText,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.notoSans(
          color: primaryText,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.notoSans(
          color: primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.notoSans(
          color: primaryText,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.notoSans(
          color: secondaryText,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: primaryText),
        titleTextStyle: GoogleFonts.notoSans(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryAccent,
          side: const BorderSide(color: primaryAccent, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Ol Chiki text style helper
  static TextStyle olChikiStyle({double fontSize = 18, FontWeight fontWeight = FontWeight.normal, Color? color}) {
    return GoogleFonts.notoSansOlChiki(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? primaryText,
      height: 1.3,
    );
  }

  // Devanagari text style helper
  static TextStyle devanagariStyle({double fontSize = 16, FontWeight fontWeight = FontWeight.normal, Color? color}) {
    return GoogleFonts.notoSansDevanagari(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? primaryText,
      height: 1.3,
    );
  }
}
