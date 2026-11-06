import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../utils/error_messages.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Shown to staff accounts whose email address is not verified yet.
/// Staff tools stay locked until verification is complete.
class StaffVerificationNotice extends ConsumerStatefulWidget {
  const StaffVerificationNotice({super.key});

  @override
  ConsumerState<StaffVerificationNotice> createState() =>
      _StaffVerificationNoticeState();
}

class _StaffVerificationNoticeState
    extends ConsumerState<StaffVerificationNotice> {
  bool _busy = false;

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final message = await action();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _resend() async {
    await ref.read(authServiceProvider).resendVerificationEmail();
    return 'Verification email sent. Check your inbox.';
  }

  Future<String> _checkAgain() async {
    final verified = await ref
        .read(authServiceProvider)
        .refreshVerificationStatus();
    ref.invalidate(authStateProvider);
    return verified
        ? 'Email verified. Staff tools are now available.'
        : 'Your email is not verified yet. Open the link in the email first.';
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(
      authStateProvider.select((s) => s.valueOrNull?.user?.email ?? ''),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Verify your staff email',
                  style: context.text.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'We sent a link to $email. Staff tools unlock once the address is verified.',
            style: context.text.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: () => _run(_checkAgain),
                  child: const Text('I have verified'),
                ),
                TextButton(
                  onPressed: () => _run(_resend),
                  child: const Text('Resend email'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
