import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_support/core/theme/app_colors.dart';
import 'package:student_support/core/theme/app_palette.dart';
import 'package:student_support/core/theme/app_radius.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/core/widgets/user_avatar.dart';
import 'package:student_support/models/history_entry_model.dart';
import 'package:student_support/providers/incident_provider.dart';
import 'package:student_support/utils/incident_labels.dart';

/// Displays the status change history for an incident.
class StatusTimelineWidget extends ConsumerWidget {
  final String incidentId;

  const StatusTimelineWidget({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider(incidentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status History', style: context.text.title),
        const SizedBox(height: AppSpacing.sm),
        historyAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return Text(
                'No status changes yet.',
                style: context.text.body.copyWith(color: context.palette.textHint),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _HistoryEntryCard(entry: entry);
              },
            );
          },
          loading: () => const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => Text(
            'Could not load history.',
            style: context.text.body.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  final HistoryEntryModel entry;

  const _HistoryEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final toColor = IncidentLabels.statusColor(entry.toStatus);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: toColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.arrow_forward, size: 16, color: toColor),
              const SizedBox(width: AppSpacing.xs),
              if (entry.fromStatus.isNotEmpty) ...[
                Text(
                  IncidentLabels.status(entry.fromStatus),
                  style: context.text.caption,
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.arrow_forward, size: 12),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                IncidentLabels.status(entry.toStatus),
                style: context.text.caption.copyWith(
                  color: toColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                IncidentLabels.relativeDate(entry.at),
                style: context.text.caption,
              ),
            ],
          ),
          if (entry.byName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                UserAvatar(userId: entry.byUid, name: entry.byName, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'By ${entry.byName}',
                    style: context.text.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (entry.note != null && entry.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.note!,
              style: context.text.body.copyWith(
                fontStyle: FontStyle.italic,
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
