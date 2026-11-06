import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../utils/error_messages.dart';
import '../theme/app_colors.dart';

/// Asks for confirmation, then signs out. The auth gate in main.dart returns
/// to the login screen on its own. Returns true if the user signed out.
Future<bool> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.logout, color: AppColors.secondary),
      title: const Text('Sign out?'),
      content: const Text(
        'You will need to sign in again to use CampusSupport.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  try {
    await ref.read(authServiceProvider).logout();
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(describeError(e))));
    }
    return false;
  }
}

/// App bar action that signs the user out after confirmation.
class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout_rounded, color: Colors.white),
      tooltip: 'Sign out',
      onPressed: () => confirmAndSignOut(context, ref),
    );
  }
}
