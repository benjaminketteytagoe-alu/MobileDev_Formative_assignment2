import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_support/core/theme/app_colors.dart';
import 'package:student_support/core/theme/app_palette.dart';
import 'package:student_support/core/theme/app_radius.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/core/widgets/motion.dart';
import 'package:student_support/providers/incident_provider.dart';
import 'package:student_support/utils/error_messages.dart';

/// Button to upvote ("Me too") an incident.
class UpvoteButton extends ConsumerWidget {
  final String incidentId;

  const UpvoteButton({super.key, required this.incidentId});

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    bool voted,
  ) async {
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(incidentControllerProvider);
    try {
      voted
          ? await controller.unvote(incidentId)
          : await controller.vote(incidentId);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not save your vote. ${describeError(e)}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final votedAsync = ref.watch(voteStatusProvider(incidentId));
    final voted = votedAsync.value ?? false;
    final activeColor = context.palette.accent;
    final color = voted ? activeColor : context.palette.textSecondary;
    final duration = motionAllowed(context)
        ? const Duration(milliseconds: 220)
        : Duration.zero;

    return votedAsync.when(
      data: (_) => InkWell(
        onTap: () => _toggle(context, ref, voted),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: duration,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: voted
                ? activeColor.withValues(alpha: 0.12)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: voted ? activeColor : context.palette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: voted ? 1.2 : 1,
                duration: duration,
                curve: Curves.easeOutBack,
                child: Icon(Icons.arrow_upward, size: 18, color: color),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                voted ? 'Voted' : 'Me too',
                style: context.text.caption.copyWith(
                  color: color,
                  fontWeight: voted ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
