import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/premium_button.dart';
import '../../providers/auth_provider.dart';
import '../../utils/error_messages.dart';

/// Every account must confirm its ALU address before reaching the app. The
/// auth gate shows this screen, and the security rules enforce the same check.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _checking = false;
  bool _resending = false;

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkVerified() async {
    setState(() => _checking = true);
    try {
      final verified = await ref
          .read(authServiceProvider)
          .refreshVerificationStatus();
      if (!mounted) return;
      if (verified) {
        ref.invalidate(authStateProvider);
      } else {
        _show('Not verified yet. Open the link in the email first.');
      }
    } catch (e) {
      if (mounted) _show(describeError(e));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ref.read(authServiceProvider).resendVerificationEmail();
      if (mounted) _show('Verification email sent. Check your inbox and spam.');
    } catch (e) {
      if (mounted) _show(describeError(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(
      authStateProvider.select((s) => s.valueOrNull?.user?.email ?? ''),
    );

    return AuthScaffold(
      title: 'Verify your ALU email',
      subtitle: 'We sent a link to $email. Open it, then come back here.',
      header: const Icon(
        Icons.mark_email_unread_outlined,
        size: 64,
        color: AppColors.secondary,
      ),
      children: [
        PremiumButton(
          label: 'I have verified',
          isLoading: _checking,
          onTap: _checkVerified,
        ),
        const SizedBox(height: AppSpacing.md),
        PremiumButton(
          label: 'Resend email',
          isOutlined: true,
          isLoading: _resending,
          onTap: _resend,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => ref.read(authServiceProvider).logout(),
          child: Text('Use another account', style: context.text.body),
        ),
      ],
    );
  }
}
