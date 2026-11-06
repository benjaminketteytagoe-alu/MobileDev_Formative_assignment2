import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_support/core/theme/app_colors.dart';
import 'package:student_support/core/theme/app_palette.dart';
import 'package:student_support/core/theme/app_radius.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/core/widgets/auth_scaffold.dart';
import 'package:student_support/core/widgets/error_banner.dart';
import 'package:student_support/core/widgets/premium_button.dart';
import 'package:student_support/core/widgets/premium_text_field.dart';
import 'package:student_support/providers/auth_provider.dart';
import 'package:student_support/utils/error_messages.dart';
import 'package:student_support/utils/validators.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  /// Pre-fills the email field, e.g. with what was typed on the login screen.
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.initialEmail ?? '',
  );
  bool _isLoading = false;
  String? _error;
  String? _sentTo;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() {
      _isLoading = true;
      _error = null;
      _sentTo = null;
    });

    try {
      await ref.read(authServiceProvider).resetPassword(email: email);
      if (mounted) setState(() => _sentTo = email);
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AuthScaffold(
      title: 'Reset your password',
      subtitle:
          "Enter your ALU email and we'll send you a link to choose a new "
          'password.',
      showBack: true,
      header: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.lock_reset_outlined,
          size: 36,
          color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
        ),
      ),
      children: [
        if (_sentTo != null) ...[
          _SentNotice(email: _sentTo!),
          const SizedBox(height: AppSpacing.lg),
        ],
        Form(
          key: _formKey,
          child: PremiumTextField(
            controller: _emailController,
            labelText: 'ALU email',
            hintText: 'name@alustudent.com',
            prefixIcon: const Icon(Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _resetPassword(),
            validator: Validators.email,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_error != null) ...[
          ErrorBanner(message: _error!),
          const SizedBox(height: AppSpacing.md),
        ],
        PremiumButton(
          label: _sentTo == null ? 'Send Reset Link' : 'Resend Link',
          onTap: _resetPassword,
          isLoading: _isLoading,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Signed up with Google? You have no CampusSupport password. Use '
          '"Continue with Google" on the sign-in screen instead.',
          style: context.text.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        AuthFooterLink(
          prompt: 'Remembered it?',
          action: 'Back to sign in',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _SentNotice extends StatelessWidget {
  final String email;

  const _SentNotice({required this.email});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.resolved.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.resolved,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              // Firebase does not reveal whether an address has an account,
              // so the message must not either.
              child: Text(
                'If an account exists for $email, a reset link is on its way. '
                'Check your inbox and spam folder.',
                style: context.text.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
