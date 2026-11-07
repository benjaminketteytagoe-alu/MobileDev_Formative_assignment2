import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isOutlined;

  /// Fill for the solid button. Defaults to [AppColors.primaryGradient].
  final Gradient? gradient;

  const PremiumButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.isOutlined = false,
    this.gradient,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  double scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      setState(() => scale = 0.96);
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final outline = context.palette.accent;
    return Semantics(
      button: true,
      enabled: !widget.isLoading,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              gradient: widget.isOutlined
                  ? null
                  : widget.gradient ?? AppColors.primaryGradient,
              border: widget.isOutlined
                  ? Border.all(color: outline, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: widget.isOutlined ? null : AppShadows.buttonShadow,
            ),
            child: widget.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isOutlined ? outline : Colors.white,
                      ),
                    ),
                  )
                : Text(
                    widget.label,
                    style: widget.isOutlined
                        ? AppTextStyles.button.copyWith(color: outline)
                        : AppTextStyles.button,
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }
}
