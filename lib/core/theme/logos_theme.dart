import 'package:flutter/material.dart';

/// LOGOS IN ME Design Tokens & Circadian Themes
/// Refined with a clean white foundation and gentle blended white-to-purple accents.
class LogosColors {
  // Vibrant Purple Palette Tokens (Softened & Blended)
  static const Color purpleDeep = Color(0xFF5B21B6);
  static const Color purplePrimary = Color(0xFF7C3AED);
  static const Color purpleRadiant = Color(0xFF8B5CF6);
  static const Color purpleAccent = Color(0xFFA78BFA);
  static const Color purpleLilac = Color(0xFFC4B5FD);
  static const Color purpleMist = Color(0xFFEDE9FE);
  static const Color purpleWhisper = Color(0xFFF7F5FE);

  // Light Sanctuary Palette (Clean White & Blended Purple)
  static const Color ink = Color(0xFF1E1A29); // Deep elegant charcoal-violet
  static const Color inkSecondary = Color(0xFF767086); // Soft heather-slate
  static const Color sand = Color(0xFFFFFFFF); // Clean shade of white
  static const Color coral = Color(0xFF7C3AED); // Primary accent violet
  static const Color coralLight = Color(0xFFF7F4FE); // Soft milky lilac wash
  static const Color taupe = Color(0xFFEBE5F5); // Ultra-delicate lilac-gray border
  static const Color surface = Color(0xFFFFFFFF); // Crisp clean white card surface
  static const Color surfaceGlass = Color(0xF8FFFFFF); // Clean frosted white glass
  static const Color gold = Color(0xFFF59E0B); // Amber gold
  static const Color goldLight = Color(0xFFFEF3C7);
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFFECFDF5);

  // Examen Contemplation Palette (Deep Velvet Midnight Purple)
  static const Color examenBg = Color(0xFF0F0B1C); // Deep velvet midnight
  static const Color examenInk = Color(0xFFF8F7FF);
  static const Color examenInkSecondary = Color(0xFFB4A8D1);
  static const Color examenSurface = Color(0xFF19132E);
  static const Color examenSurfaceGlass = Color(0xCC19132E);
  static const Color examenCoral = Color(0xFFA78BFA); // Soft luminous lavender
  static const Color examenBorder = Color(0xFF2E244D);

  // Feature Module Semantic Colors
  static const Color studyPods = Color(0xFF7C3AED); // Deep violet
  static const Color prayerCircles = Color(0xFF8B5CF6); // Amethyst
  static const Color theWell = Color(0xFF6D28D9); // Royal violet
  static const Color valleyRooms = Color(0xFF64748B); // Calm basalt slate (balanced)
  static const Color voiceComfort = Color(0xFF9333EA); // Radiant orchid

  // Luxury Gradients - Blended White and Purple
  static const LinearGradient whitePurpleBlend = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFAF7FE), Color(0xFFF2EBFC)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
  );

  static const LinearGradient purpleHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFAF7FE), Color(0xFFF0E8FC), Color(0xFFE5D7FA)],
  );

  static const LinearGradient sanctuaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F5FE), Color(0xFFEDE4FA)],
  );

  static const LinearGradient parchmentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFBF9FE), Color(0xFFF3EBFC)],
  );

  static const LinearGradient examenParchmentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F1836), Color(0xFF150F26)],
  );

  static const LinearGradient goldGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
  );

  // Clean, Subtle Layered Shadows (No harsh purple glare)
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get relicShadow => [
        BoxShadow(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get floatingDockShadow => [
        BoxShadow(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
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
          side: const BorderSide(color: LogosColors.taupe, width: 1.0),
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
          side: const BorderSide(color: LogosColors.examenBorder, width: 1.0),
        ),
      ),
    );
  }
}
