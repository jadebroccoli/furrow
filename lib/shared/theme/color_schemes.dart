import 'package:flutter/material.dart';

/// Furrow earthy color palette
/// Primary: Deep Forest Green
/// Secondary: Warm Brown
/// Tertiary: Sage Green
/// Surfaces: Cream / Off-white
class FurrowColors {
  FurrowColors._();

  // Seed colors
  static const Color primarySeed = Color(0xFF2D5A27);
  static const Color secondarySeed = Color(0xFF8B6914);
  static const Color tertiarySeed = Color(0xFF7A8B6F);

  // Light mode overrides
  static const Color lightSurface = Color(0xFFFFF8F0);
  static const Color lightBackground = Color(0xFFFFFDF7);

  // Dark mode overrides
  static const Color darkSurface = Color(0xFF1A1C18);
  static const Color darkBackground = Color(0xFF121410);

  // Accent colors for specific use
  static const Color harvestGold = Color(0xFFD4A017);
  static const Color frostBlue = Color(0xFF5B9BD5);
  static const Color alertRed = Color(0xFFBA1A1A);
  static const Color seedlingGreen = Color(0xFF66BB6A);

  static ColorScheme get lightColorScheme {
    final base = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    return base.copyWith(
      secondary: secondarySeed,
      tertiary: tertiarySeed,
      surface: lightSurface,
      surfaceContainerLowest: lightBackground,
      error: alertRed,
    );
  }

  static ColorScheme get darkColorScheme {
    final base = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    return base.copyWith(
      secondary: const Color(0xFFCBB979),
      tertiary: const Color(0xFFA8B89A),
      surface: darkSurface,
      surfaceContainerLowest: darkBackground,
      error: const Color(0xFFFFB4AB),
    );
  }
}
