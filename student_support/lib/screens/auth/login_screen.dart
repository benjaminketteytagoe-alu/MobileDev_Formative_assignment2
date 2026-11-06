import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_support/core/theme/app_colors.dart';
import 'package:student_support/core/theme/app_palette.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/core/widgets/auth_scaffold.dart';
import 'package:student_support/core/widgets/error_banner.dart';
import 'package:student_support/core/widgets/google_sign_in_button.dart';
import 'package:student_support/core/widgets/premium_button.dart';
import 'package:student_support/core/widgets/premium_text_field.dart';
import 'package:student_support/navigation/app_router.dart';
import 'package:student_support/providers/auth_provider.dart';
import 'package:student_support/utils/error_messages.dart';
import 'package:student_support/utils/validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // The auth gate in main.dart switches to the home screen.
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linkColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to report and track campus issues',
      children: [
        GoogleSignInButton(
          onStart: () => setState(() => _error = null),
          onError: (message) => setState(() => _error = message),
        ),
        const AuthDivider(label: 'or sign in with email'),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumTextField(
                  controller: _emailController,
                  labelText: 'ALU email',
                  hintText: 'name@alustudent.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.md),
                PremiumTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _login(),
                  validator: Validators.password,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pushNamed(
              AppRouter.forgotPassword,
              arguments: _emailController.text.trim(),
            ),
            child: Text(
              'Forgot password?',
              style: context.text.body.copyWith(
                color: linkColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_error != null) ...[
          ErrorBanner(message: _error!),
          const SizedBox(height: AppSpacing.md),
        ],
        PremiumButton(label: 'Sign In', onTap: _login, isLoading: _isLoading),
        const SizedBox(height: AppSpacing.lg),
        AuthFooterLink(
          prompt: "Don't have an account?",
          action: 'Sign up',
          onTap: () => Navigator.of(context).pushNamed(AppRouter.register),
        ),
      ],
    );
  }
}
