import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ALU brand ------------------------------------------------------------
  static const Color aluNavy = Color(0xFF0B2A5B);
  static const Color aluRed = Color(0xFFE4312B);
  static const Color aluGold = Color(0xFFF5B014);

  // Primary brand color - ALU navy. Every primary call to action uses it.
  static const Color primary = aluNavy;
  static const Color primaryLight = Color(0xFF1F5FBF);
  static const Color primaryDark = Color(0xFF06173A);

  // Secondary - ALU red. Reserved for destructive actions and errors, so red
  // always means "careful" and never "continue".
  static const Color secondary = aluRed;
  static const Color secondaryLight = Color(0xFFFF6B5E);

  // Accent - ALU gold
  static const Color accent = aluGold;

  // Status colors
  static const Color submitted = Color(0xFF6C7A96);
  static const Color inReview = Color(0xFFF59E0B);
  static const Color inProgress = Color(0xFF2F80ED);
  static const Color resolved = Color(0xFF12B76A);
  static const Color rejected = Color(0xFFE4312B);

  // Urgency colors
  static const Color urgencyLow = Color(0xFF12B76A);
  static const Color urgencyMedium = Color(0xFFF59E0B);
  static const Color urgencyHigh = Color(0xFFE4312B);

  // Category colors - one vivid color per report category
  static const Color categoryFacility = Color(0xFFFF7A1A);
  static const Color categoryWater = Color(0xFF00A8E8);
  static const Color categoryElectricity = Color(0xFFF5B014);
  static const Color categoryFurniture = Color(0xFF8B5CF6);
  static const Color categorySanitation = Color(0xFF12B76A);
  static const Color categorySafety = Color(0xFFE4312B);

  // Surface colors
  static const Color background = Color(0xFFF4F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE9EFF8);

  // Dark surface colors
  static const Color darkBackground = Color(0xFF071530);
  static const Color darkSurface = Color(0xFF0F2347);
  static const Color darkSurfaceVariant = Color(0xFF1A3361);

  // Text colors
  static const Color textPrimary = Color(0xFF0B1B3A);
  static const Color textSecondary = Color(0xFF55627A);
  static const Color textHint = Color(0xFF8C97AD);

  // Dark text colors
  static const Color darkTextPrimary = Color(0xFFF1F5FB);
  static const Color darkTextSecondary = Color(0xFFA9B6CF);
  static const Color darkTextHint = Color(0xFF6E7F9F);

  // Border and divider
  static const Color border = Color(0xFFD9E2F0);
  static const Color divider = Color(0xFFE9EFF8);

  // Dark border
  static const Color darkBorder = Color(0xFF1F3A6B);
  static const Color darkDivider = Color(0xFF0F2347);

  // Error
  static const Color error = Color(0xFFE4312B);
  static const Color errorLight = Color(0xFFFDECEB);
  static const Color darkErrorLight = Color(0xFF4A1512);

  // Warning
  static const Color warning = Color(0xFFF59E0B);

  // Gradients
  /// Fill for primary buttons. A subtle navy ramp so the button reads as one
  /// solid brand color.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF14407F), primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deep navy ramp. Used by the splash screen, app bar, hero and profile
  /// header.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryDark, aluNavy, Color(0xFF14407F)],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0xFFF4F7FC), Color(0xFFFFF4E5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
