import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'premium_button.dart';

/// Cancel + primary action pinned to the bottom of a form, so both are
/// always within thumb reach no matter how long the form is.
class FormActionBar extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onCancel;
  final bool isLoading;
  final String cancelLabel;

  const FormActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onCancel,
    this.isLoading = false,
    this.cancelLabel = 'Cancel',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkSurface : context.palette.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm + AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm + AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: PremiumButton(
                  label: cancelLabel,
                  onTap: isLoading ? () {} : onCancel,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                flex: 2,
                child: PremiumButton(
                  label: primaryLabel,
                  onTap: onPrimary,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
