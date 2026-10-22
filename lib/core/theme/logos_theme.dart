import 'package:flutter/material.dart';

/// LOGOS IN ME Design Tokens & Circadian Themes
class LogosColors {
  // Light Sanctuary Palette (5:00 AM - 7:59 PM)
  static const Color ink = Color(0xFF2E2A24);
  static const Color sand = Color(0xFFF2EAE0);
  static const Color coral = Color(0xFFE8A98C);
  static const Color taupe = Color(0xFFD9CFC4);
  static const Color surface = Color(0xFFFAF6F0);

  // Examen Contemplation Palette (8:00 PM - 4:59 AM)
  static const Color examenBg = Color(0xFF1E1B17);
  static const Color examenInk = Color(0xFFF2EAE0);
  static const Color examenSurface = Color(0xFF2A2520);
  static const Color examenCoral = Color(0xFFE8A98C);

  // Feature Module Semantic Colors
  static const Color studyPods = Color(0xFF3D5A5B); // Dusty sage / blue-green
  static const Color prayerCircles = Color(0xFF9A6B55); // Clay
  static const Color theWell = Color(0xFF8C7A5E); // Ochre
  static const Color valleyRooms = Color(0xFF4A453E); // Basalt
  static const Color voiceComfort = Color(0xFFB87D65); // Sienna

  // Sanctuary Gradients
  static const LinearGradient sanctuaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D5A60), Color(0xFFE8A98C)],
  );

  static const LinearGradient duneGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF2EAE0), Color(0xFFD9CFC4)],
  );
}

class LogosTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: LogosColors.sand,
      colorScheme: const ColorScheme.light(
        primary: LogosColors.coral,
        onPrimary: Colors.white,
        surface: LogosColors.surface,
        onSurface: LogosColors.ink,
        outline: LogosColors.taupe,
      ),
      cardTheme: CardThemeData(
        color: LogosColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: LogosColors.taupe, width: 1),
        ),
      ),
    );
  }

  static ThemeData examenTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: LogosColors.examenBg,
      colorScheme: const ColorScheme.dark(
        primary: LogosColors.examenCoral,
        onPrimary: Colors.white,
        surface: LogosColors.examenSurface,
        onSurface: LogosColors.examenInk,
        outline: Color(0xFF3E3730),
      ),
      cardTheme: CardThemeData(
        color: LogosColors.examenSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF3E3730), width: 1),
        ),
      ),
    );
  }
}
