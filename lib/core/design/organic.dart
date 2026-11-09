import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Organic" design system — tokens taken from the design source
/// (Logos Redesign · design-system tokens). Warm parchment ground, terracotta
/// accent, sage secondary; Caprasimo display type over Figtree text.
class OC {
  OC._();

  // Roles
  static const bg = Color(0xFFF5EAD8);
  static const surface = Color(0xFFEBDDC5);
  static const text = Color(0xFF201E1D);
  static const accent = Color(0xFFC67139);
  static const accent2 = Color(0xFF7A8A5E);
  static Color get divider => text.withValues(alpha: 0.16);

  // Neutral ramp
  static const n100 = Color(0xFFF9F4ED);
  static const n200 = Color(0xFFEEE7DB);
  static const n300 = Color(0xFFDCD3C4);
  static const n400 = Color(0xFFC0B6A5);
  static const n500 = Color(0xFFA19786);
  static const n600 = Color(0xFF82796A);
  static const n700 = Color(0xFF645C50);
  static const n800 = Color(0xFF474238);
  static const n900 = Color(0xFF2E2B25);

  // Accent (terracotta) ramp
  static const a100 = Color(0xFFFFF2EB);
  static const a200 = Color(0xFFFFE1D0);
  static const a300 = Color(0xFFFFC6A5);
  static const a400 = Color(0xFFF6A06B);
  static const a500 = Color(0xFFD67F48);
  static const a600 = Color(0xFFB2622D);
  static const a700 = Color(0xFF8C491A);
  static const a800 = Color(0xFF643312);
  static const a900 = Color(0xFF402310);

  // Accent-2 (sage) ramp
  static const s100 = Color(0xFFF0FAE1);
  static const s200 = Color(0xFFE1EECC);
  static const s300 = Color(0xFFCCDBB2);
  static const s400 = Color(0xFFAEBF92);
  static const s500 = Color(0xFF8FA073);
  static const s600 = Color(0xFF728157);
  static const s700 = Color(0xFF56633F);
  static const s800 = Color(0xFF3D472B);
  static const s900 = Color(0xFF272E1B);

  static Color muted(Color c, [double a = 0.55]) => c.withValues(alpha: a);
}

/// Every practice has its own atmosphere.
enum Atmosphere {
  parchment(OC.bg, OC.text, false), // Today, Altar, Community, Pods, Milestones, Setup
  dusk(OC.n900, OC.n100, true), // Encounter, Examen, Valley
  sage(OC.s100, OC.s900, false), // Roots, The Well, Voice Comfort
  night(OC.s900, OC.s100, true), // Stillness
  paper(OC.surface, OC.text, false), // Exchange
  ember(OC.a700, OC.n100, true), // Covenant, Week recap
  blush(OC.a100, OC.a900, false); // Prayer Circles

  final Color bg;
  final Color ink;
  final bool dark;
  const Atmosphere(this.bg, this.ink, this.dark);

  SystemUiOverlayStyle get overlay => dark
      ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
      : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent);
}

class ORadius {
  ORadius._();
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 28.0;
  static const card = 24.0;
  static const pill = 999.0;
}

class OShadow {
  OShadow._();
  static List<BoxShadow> get sm => [BoxShadow(color: OC.n900.withValues(alpha: 0.14), blurRadius: 2, offset: const Offset(0, 1))];
  static List<BoxShadow> get md => [BoxShadow(color: OC.n900.withValues(alpha: 0.16), blurRadius: 10, offset: const Offset(0, 3))];
  static List<BoxShadow> get lg => [BoxShadow(color: OC.n900.withValues(alpha: 0.22), blurRadius: 32, offset: const Offset(0, 12))];
}

/// Typography: Caprasimo for display & headings, Figtree for everything else.
class OT {
  OT._();

  static TextStyle display(double size, {Color color = OC.text, double height = 1.12}) =>
      GoogleFonts.caprasimo(fontSize: size, height: height, color: color, letterSpacing: -0.015 * size);

  static TextStyle h1({Color color = OC.text}) => display(42, color: color);
  static TextStyle h2({Color color = OC.text}) => display(32, color: color);
  static TextStyle h3({Color color = OC.text}) => display(25, color: color);
  static TextStyle h4({Color color = OC.text}) => display(20, color: color, height: 1.2);

  /// The verse — the hero of every screen.
  static TextStyle verse({double size = 30, Color color = OC.text}) => display(size, color: color, height: 1.16);

  static TextStyle body({double size = 15, Color color = OC.text, FontWeight weight = FontWeight.w400, double height = 1.5}) =>
      GoogleFonts.figtree(fontSize: size, color: color, fontWeight: weight, height: height);

  static TextStyle label({double size = 15, Color color = OC.text}) =>
      GoogleFonts.figtree(fontSize: size, color: color, fontWeight: FontWeight.w700, height: 1.3);

  static TextStyle small({Color color = OC.text, double alpha = 0.7}) =>
      GoogleFonts.figtree(fontSize: 13, color: color.withValues(alpha: alpha), height: 1.4);

  /// Uppercase tracked label ("JOHN 15:5", "TODAY · DAY 2").
  static TextStyle kicker({Color color = OC.a600, double size = 12}) => GoogleFonts.figtree(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: size * 0.14,
        height: 1.2,
      );

  /// Greek / Hebrew originals: the platform font has full coverage
  /// (Caprasimo maps some Greek letters to empty glyphs).
  static TextStyle original({double size = 19, Color color = OC.text}) =>
      TextStyle(fontSize: size, color: color, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle button({Color color = OC.n100, double size = 16}) =>
      GoogleFonts.figtree(fontSize: size, color: color, fontWeight: FontWeight.w700, height: 1.2);
}

ThemeData organicTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: OC.accent,
      primary: OC.accent,
      secondary: OC.accent2,
      surface: OC.bg,
      onSurface: OC.text,
    ),
    scaffoldBackgroundColor: OC.bg,
  );
  return base.copyWith(
    textTheme: GoogleFonts.figtreeTextTheme(base.textTheme).apply(bodyColor: OC.text, displayColor: OC.text),
    splashFactory: InkSparkle.splashFactory,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: OC.text,
      contentTextStyle: OT.body(size: 14, color: OC.n100, weight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ORadius.pill)),
      insetPadding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
    ),
    timePickerTheme: const TimePickerThemeData(
      backgroundColor: OC.bg,
      dialBackgroundColor: OC.n200,
      hourMinuteColor: OC.n200,
      dayPeriodColor: OC.a200,
      dialHandColor: OC.accent,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: OC.accent,
      selectionColor: OC.accent.withValues(alpha: 0.3),
      selectionHandleColor: OC.accent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(OC.n100),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? OC.s500 : OC.n400),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
  );
}
