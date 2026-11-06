import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/incident_provider.dart';
import '../../utils/error_messages.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// Lets a user tell staff that a report is false or abusive. Each person can
/// flag a report once.
class FlagReportButton extends ConsumerWidget {
  final String incidentId;

  const FlagReportButton({super.key, required this.incidentId});

  Future<void> _flag(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag this report?'),
        content: const Text(
          'Staff will review it. Use this for false or abusive reports only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Flag report'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(incidentControllerProvider).flagReport(incidentId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Thanks. Staff will review this report.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not flag. ${describeError(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagged = ref.watch(hasFlaggedProvider(incidentId)).valueOrNull;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: flagged == false ? () => _flag(context, ref) : null,
        icon: const Icon(Icons.flag_outlined, size: 18),
        label: Text(
          flagged == true ? 'Flagged for review' : 'Flag this report',
        ),
      ),
    );
  }
}

/// Tells staff how many people flagged a report. Shows nothing when none have.
class FlagCountNotice extends ConsumerWidget {
  final String incidentId;

  const FlagCountNotice({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(flagCountProvider(incidentId)).valueOrNull ?? 0;
    if (count == 0) return const SizedBox.shrink();
    final people = count == 1 ? '1 person' : '$count people';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.flag, size: 18, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Flagged as false or abusive by $people',
              style: context.text.body,
            ),
          ),
        ],
      ),
    );
  }
}
