import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Colors that differ between light and dark mode. Widgets read these through
/// `context.palette` instead of using [AppColors] directly, so nothing has to
/// remember to handle dark mode itself.
class AppPalette {
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color surface;
  final Color surfaceVariant;
  final Color border;

  /// Primary color for foreground use: icons, links, selected states. ALU
  /// navy is unreadable on the dark surfaces, so dark mode uses a lighter blue.
  final Color accent;

  /// Soft page background used behind the profile.
  final Gradient pageGradient;

  const AppPalette._({
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.accent,
    required this.pageGradient,
  });

  static const AppPalette light = AppPalette._(
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textHint: AppColors.textHint,
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    border: AppColors.border,
    accent: AppColors.primary,
    pageGradient: AppColors.subtleGradient,
  );

  static const AppPalette dark = AppPalette._(
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textHint: AppColors.darkTextHint,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    border: AppColors.darkBorder,
    accent: Color(0xFF7FB0FF),
    pageGradient: LinearGradient(
      colors: [AppColors.darkBackground, AppColors.darkBackground],
    ),
  );
}

/// [AppTextStyles] in the colors of the current theme.
class AppThemedText {
  final AppPalette _palette;

  const AppThemedText(this._palette);

  TextStyle get heading =>
      AppTextStyles.heading.copyWith(color: _palette.textPrimary);
  TextStyle get title =>
      AppTextStyles.title.copyWith(color: _palette.textPrimary);
  TextStyle get body =>
      AppTextStyles.body.copyWith(color: _palette.textSecondary);
  TextStyle get caption =>
      AppTextStyles.caption.copyWith(color: _palette.textHint);
}

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;

  AppThemedText get text => AppThemedText(palette);
}
