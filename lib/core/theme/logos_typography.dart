import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LogosTypography {
  // Scripture & Contemplation Display (Source Serif 4)
  static TextStyle scriptureHero({required Color color}) {
    return GoogleFonts.sourceSerif4(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: -0.015,
      color: color,
    );
  }

  static TextStyle scriptureBody({required Color color}) {
    return GoogleFonts.sourceSerif4(
      fontSize: 18,
      fontWeight: FontWeight.normal,
      height: 1.6,
      letterSpacing: -0.005,
      color: color,
    );
  }

  static TextStyle scriptureCitation({required Color color}) {
    return GoogleFonts.sourceSerif4(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
      height: 1.3,
      color: color,
    );
  }

  // UI System, Buttons & Navigation (Inter)
  static TextStyle headline({required Color color}) {
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      height: 1.25,
      letterSpacing: -0.01,
      color: color,
    );
  }

  static TextStyle label({required Color color}) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0.01,
      color: color,
    );
  }

  static TextStyle body({required Color color}) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      height: 1.4,
      color: color,
    );
  }

  static TextStyle caption({required Color color}) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: color,
    );
  }
}
