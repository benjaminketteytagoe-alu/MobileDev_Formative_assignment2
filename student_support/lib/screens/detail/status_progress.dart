import 'package:flutter/material.dart';
import 'package:student_support/core/theme/app_palette.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/core/widgets/motion.dart';
import 'package:student_support/utils/incident_labels.dart';

/// Tracker showing how far a report has progressed. A rejected report leaves
/// the normal path, so its last step becomes a red "Rejected".
class StatusProgress extends StatelessWidget {
  final String status;

  const StatusProgress({super.key, required this.status});

  static const _path = ['submitted', 'in_review', 'in_progress', 'resolved'];

  @override
  Widget build(BuildContext context) {
    final rejected = status == 'rejected';
    final steps = rejected ? ['submitted', 'rejected'] : _path;
    final current = steps.indexOf(status);
    final palette = context.palette;
    final duration = motionAllowed(context)
        ? const Duration(milliseconds: 450)
        : Duration.zero;

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: i <= current ? 1 : 0),
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    builder: (context, fill, _) => LinearProgressIndicator(
                      value: fill,
                      minHeight: 2,
                      backgroundColor: palette.border,
                      color: IncidentLabels.statusColor(steps[i]),
                    ),
                  ),
                ),
              Icon(
                i <= current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: i <= current
                    ? IncidentLabels.statusColor(steps[i])
                    : palette.textHint,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Equal shares, so long labels shorten rather than overflow.
        Row(
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Text(
                  IncidentLabels.status(steps[i]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: i == 0
                      ? TextAlign.start
                      : i == steps.length - 1
                      ? TextAlign.end
                      : TextAlign.center,
                  style: context.text.caption.copyWith(
                    color: i == current ? palette.textPrimary : null,
                    fontWeight: i == current ? FontWeight.w600 : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
