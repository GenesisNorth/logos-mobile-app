import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LogosTypography {
  // Scripture & Contemplation Display (Source Serif 4)
  static TextStyle scriptureHero({required Color color}) {
    return GoogleFonts.sourceSerif4(
      fontSize: 27,
      fontWeight: FontWeight.w600,
      height: 1.38,
      letterSpacing: -0.4,
      color: color,
    );
  }

  static TextStyle sacredHeader({required Color color}) {
    return GoogleFonts.sourceSerif4(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.3,
      color: color,
    );
  }

  static TextStyle scriptureBody({required Color color}) {
    return GoogleFonts.sourceSerif4(
      fontSize: 18,
      fontWeight: FontWeight.normal,
      height: 1.65,
      letterSpacing: -0.1,
      color: color,
    );
  }

  static TextStyle scriptureCitation({required Color color}) {
    return GoogleFonts.sourceSerif4(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
      height: 1.3,
      letterSpacing: 0.2,
      color: color,
    );
  }

  // UI System, Buttons & Navigation (Inter)
  static TextStyle headlineLarge({required Color color}) {
    return GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: -0.6,
      color: color,
    );
  }

  static TextStyle headline({required Color color}) {
    return GoogleFonts.inter(
      fontSize: 19,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.3,
      color: color,
    );
  }

  static TextStyle label({required Color color}) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0.1,
      color: color,
    );
  }

  static TextStyle monasticLabel({required Color color}) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: 1.8,
      color: color,
    );
  }

  static TextStyle body({required Color color}) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: -0.1,
      color: color,
    );
  }

  static TextStyle caption({required Color color}) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.25,
      color: color,
    );
  }
}
