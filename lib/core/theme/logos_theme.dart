import 'package:flutter/material.dart';

/// LOGOS IN ME Design Tokens & Circadian Themes
class LogosColors {
  // Light Sanctuary Palette (5:00 AM - 7:59 PM)
  static const Color ink = Color(0xFF24201B);
  static const Color inkSecondary = Color(0xFF6B6358);
  static const Color sand = Color(0xFFF7F2EB);
  static const Color coral = Color(0xFFE29578);
  static const Color coralLight = Color(0xFFF8EDE7);
  static const Color taupe = Color(0xFFE5DDD2);
  static const Color surface = Color(0xFFFFFDF9);
  static const Color surfaceGlass = Color(0xCCFFFDF9);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFBF4DC);
  static const Color emerald = Color(0xFF2E7D32);
  static const Color emeraldLight = Color(0xFFE8F5E9);

  // Examen Contemplation Palette (8:00 PM - 4:59 AM)
  static const Color examenBg = Color(0xFF141210);
  static const Color examenInk = Color(0xFFF7F2EB);
  static const Color examenInkSecondary = Color(0xFFA69E92);
  static const Color examenSurface = Color(0xFF1F1B17);
  static const Color examenSurfaceGlass = Color(0xCC1F1B17);
  static const Color examenCoral = Color(0xFFE29578);
  static const Color examenBorder = Color(0xFF2F2923);

  // Feature Module Semantic Colors
  static const Color studyPods = Color(0xFF385E60); // Deep dusty sage
  static const Color prayerCircles = Color(0xFF9E654C); // Terracotta clay
  static const Color theWell = Color(0xFF8C7355); // Rich ochre
  static const Color valleyRooms = Color(0xFF3A3530); // Deep basalt
  static const Color voiceComfort = Color(0xFFB5745B); // Warm sienna

  // Luxury Gradients
  static const LinearGradient sanctuaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF24484D), Color(0xFFE29578)],
  );

  static const LinearGradient parchmentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFDF9), Color(0xFFF5ECE0)],
  );

  static const LinearGradient examenParchmentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF26211C), Color(0xFF1A1714)],
  );

  static const LinearGradient goldGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF4DE9C), Color(0xFFD4AF37)],
  );

  // Apple-grade Soft Layered Shadows
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get relicShadow => [
        BoxShadow(
          color: const Color(0xFFE29578).withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floatingDockShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 30,
          offset: const Offset(0, 10),
          spreadRadius: 2,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];
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
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: LogosColors.taupe, width: 0.8),
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
        outline: LogosColors.examenBorder,
      ),
      cardTheme: CardThemeData(
        color: LogosColors.examenSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: LogosColors.examenBorder, width: 0.8),
        ),
      ),
    );
  }
}
