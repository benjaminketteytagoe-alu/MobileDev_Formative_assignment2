import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_support/core/theme/app_colors.dart';
import 'package:student_support/core/theme/app_palette.dart';
import 'package:student_support/core/theme/app_radius.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/core/widgets/auth_scaffold.dart';
import 'package:student_support/core/widgets/error_banner.dart';
import 'package:student_support/core/widgets/google_sign_in_button.dart';
import 'package:student_support/core/widgets/premium_button.dart';
import 'package:student_support/core/widgets/premium_text_field.dart';
import 'package:student_support/providers/auth_provider.dart';
import 'package:student_support/utils/error_messages.dart';
import 'package:student_support/utils/validators.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  /// 'student', 'staff', or null until the email has an ALU domain. The
  /// role always follows the email, so there is nothing for the user to pick.
  String? _detectedRole;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onEmailChanged(String value) {
    final detected = Validators.detectRoleFromEmail(value.trim());
    if (detected != _detectedRole) setState(() => _detectedRole = detected);
  }

  String? _validateEmail(String? value) {
    final basic = Validators.email(value?.trim());
    if (basic != null) return basic;
    if (!Validators.isValidDomain(value!.trim())) {
      return 'Use your @alustudent.com or @alueducation.com email';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .signUp(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // The auth gate closes this screen and shows the home screen.
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _visibilityToggle(bool obscured, VoidCallback onPressed) {
    return IconButton(
      tooltip: obscured ? 'Show password' : 'Hide password',
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Use your ALU email to get started',
      showBack: true,
      children: [
        GoogleSignInButton(
          label: 'Sign up with Google',
          onStart: () => setState(() => _error = null),
          onError: (message) => setState(() => _error = message),
        ),
        const AuthDivider(label: 'or sign up with email'),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumTextField(
                  controller: _nameController,
                  labelText: 'Full name',
                  hintText: 'Full name',
                  prefixIcon: const Icon(Icons.person_outline),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) =>
                      Validators.required(v, 'Name') ??
                      Validators.maxLength(v, 100, 'Name'),
                ),
                const SizedBox(height: AppSpacing.md),
                PremiumTextField(
                  controller: _emailController,
                  labelText: 'ALU email',
                  hintText: 'name@alustudent.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  onChanged: _onEmailChanged,
                  validator: _validateEmail,
                ),
                if (_detectedRole != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _RoleBadge(isStaff: _detectedRole == 'staff'),
                ],
                const SizedBox(height: AppSpacing.md),
                PremiumTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'At least 6 characters',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                  suffixIcon: _visibilityToggle(
                    _obscurePassword,
                    () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PremiumTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm password',
                  hintText: 'Repeat your password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  validator: (v) =>
                      Validators.confirmPassword(v, _passwordController.text),
                  suffixIcon: _visibilityToggle(
                    _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_error != null) ...[
          ErrorBanner(message: _error!),
          const SizedBox(height: AppSpacing.md),
        ],
        PremiumButton(
          label: 'Create Account',
          onTap: _register,
          isLoading: _isLoading,
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthFooterLink(
          prompt: 'Already have an account?',
          action: 'Sign in',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Shows which kind of account the email will create.
class _RoleBadge extends StatelessWidget {
  final bool isStaff;

  const _RoleBadge({required this.isStaff});

  @override
  Widget build(BuildContext context) {
    final color = isStaff ? AppColors.accent : AppColors.resolved;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isStaff ? Icons.badge_outlined : Icons.school_outlined,
            size: 18,
            color: isStaff ? const Color(0xFF9A6A00) : AppColors.resolved,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isStaff
                  ? 'Staff account. We will email you a verification link; '
                        'staff tools unlock after you open it.'
                  : 'Student account.',
              style: context.text.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
