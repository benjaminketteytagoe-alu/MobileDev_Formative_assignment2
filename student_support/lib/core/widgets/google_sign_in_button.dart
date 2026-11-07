import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/auth_provider.dart';
import '../../utils/error_messages.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// "Continue with Google" button, styled after Google's sign-in branding:
/// neutral surface, the full-color G, and a plain label.
///
/// Handles its own loading state. Errors are passed to [onError] so the
/// screen can show them next to its other messages.
class GoogleSignInButton extends ConsumerStatefulWidget {
  final String label;
  final ValueChanged<String> onError;

  /// Called before sign-in starts, e.g. to clear an earlier error.
  final VoidCallback? onStart;

  const GoogleSignInButton({
    super.key,
    this.label = 'Continue with Google',
    required this.onError,
    this.onStart,
  });

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _isLoading = false;

  Future<void> _signIn() async {
    widget.onStart?.call();
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // The auth gate in main.dart switches to the home screen.
    } catch (e) {
      if (mounted) widget.onError(describeError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark
              ? AppColors.darkSurface
              : context.palette.surface,
          foregroundColor: isDark
              ? AppColors.darkTextPrimary
              : context.palette.textPrimary,
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : context.palette.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/google_g.svg',
                    width: 20,
                    height: 20,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Text(
                    widget.label,
                    style: AppTextStyles.button.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : context.palette.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
