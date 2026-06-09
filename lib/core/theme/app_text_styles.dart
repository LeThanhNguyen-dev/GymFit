import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings - Montserrat
  static TextStyle get headlineLarge => GoogleFonts.montserrat(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02,
  );

  static TextStyle get headlineMedium => GoogleFonts.montserrat(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.01,
  );

  static TextStyle get headlineSmall => GoogleFonts.montserrat(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
  );

  // Body - Inter
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );

  // Labels - Inter
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.05,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.04,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
  );

  // Title variants
  static TextStyle get titleLarge => GoogleFonts.montserrat(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get titleMedium => GoogleFonts.montserrat(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get titleSmall => GoogleFonts.montserrat(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );

  // Display
  static TextStyle get displayLarge => GoogleFonts.montserrat(
    fontSize: 48,
    height: 56 / 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.03,
  );

  // Button
  static TextStyle get buttonLarge => GoogleFonts.inter(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.05,
  );

  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
  );
}
