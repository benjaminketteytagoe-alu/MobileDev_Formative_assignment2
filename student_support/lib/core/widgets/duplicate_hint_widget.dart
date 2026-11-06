import 'package:flutter/material.dart';
import 'package:student_support/core/theme/app_colors.dart';
import 'package:student_support/core/theme/app_palette.dart';
import 'package:student_support/core/theme/app_radius.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/models/incident_model.dart';
import 'package:student_support/utils/incident_labels.dart';

/// Shows similar open reports as duplicate hints.
class DuplicateHintWidget extends StatelessWidget {
  final List<IncidentModel> hints;
  final ValueChanged<IncidentModel> onTap;

  const DuplicateHintWidget({
    super.key,
    required this.hints,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (hints.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Similar reports exist',
          style: context.text.caption.copyWith(color: AppColors.warning),
        ),
        const SizedBox(height: AppSpacing.xs),
        ...hints.take(3).map((incident) {
          return InkWell(
            onTap: () => onTap(incident),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      incident.title,
                      style: context.text.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: IncidentLabels.statusColor(incident.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      IncidentLabels.status(incident.status),
                      style: context.text.caption.copyWith(
                        fontSize: 10,
                        color: IncidentLabels.statusColor(incident.status),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
