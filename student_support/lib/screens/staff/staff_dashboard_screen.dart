import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_support/core/theme/app_radius.dart';
import 'package:student_support/core/theme/app_palette.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/core/dicebear.dart';
import 'package:student_support/core/widgets/custom_app_bar.dart';
import 'package:student_support/core/widgets/dicebear_art.dart';
import 'package:student_support/core/widgets/empty_state_widget.dart';
import 'package:student_support/core/widgets/incident_list_view.dart';
import 'package:student_support/core/widgets/motion.dart';
import 'package:student_support/core/widgets/skeleton_loader.dart';
import 'package:student_support/models/incident_model.dart';
import 'package:student_support/providers/auth_provider.dart';
import 'package:student_support/providers/filter_provider.dart';
import 'package:student_support/providers/incident_provider.dart';
import 'package:student_support/utils/incident_labels.dart';

/// Staff overview: live counts per status and a review queue. Tapping a
/// count filters the queue to that status.
class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  static const _scope = FeedScope.staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).valueOrNull;

    // The screen checks the role itself rather than relying on the
    // navigation bar to hide it. Firestore rules enforce the same check.
    if (auth == null || !auth.isStaff) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Staff Dashboard', showSignOut: true),
        body: const EmptyStateWidget(
          icon: Icons.lock_outline,
          title: 'Staff access only',
          message: 'This area is available to verified campus staff.',
        ),
      );
    }

    final filter = ref.watch(incidentFilterProvider(_scope));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Staff Dashboard', showSignOut: true),
      body: Column(
        children: [
          // Five cards do not fit a phone's width, so the row scrolls.
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: IncidentModel.statuses.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final status = IncidentModel.statuses[index];
                return SizedBox(
                  width: 108,
                  child: _StatCard(
                    status: status,
                    selected: filter.status == status,
                    onTap: () {
                      ref
                          .read(incidentFilterProvider(_scope).notifier)
                          .state = filter.copyWith(
                        status: filter.status == status ? '' : status,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    filter.status.isEmpty
                        ? 'All reports'
                        : '${IncidentLabels.status(filter.status)} reports',
                    style: context.text.title,
                  ),
                ),
                if (filter.status.isNotEmpty)
                  TextButton(
                    onPressed: () =>
                        ref
                            .read(incidentFilterProvider(_scope).notifier)
                            .state = filter.copyWith(
                          status: '',
                        ),
                    child: const Text('Show all'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: IncidentListView(
              incidents: ref.watch(incidentsProvider(_scope)),
              onRetry: () => ref.invalidate(incidentsProvider(_scope)),
              emptyState: EmptyStateWidget(
                icon: Icons.inbox_outlined,
                illustration: const DiceBearMascot(DiceBear.mascotEmpty),
                title: 'Nothing here',
                message: filter.status.isEmpty
                    ? 'No reports have been submitted yet.'
                    : 'No reports are currently ${IncidentLabels.status(filter.status).toLowerCase()}.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends ConsumerWidget {
  final String status;
  final bool selected;
  final VoidCallback onTap;

  const _StatCard({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = IncidentLabels.statusColor(status);
    final label = IncidentLabels.status(status);
    final count = ref.watch(incidentCountProvider(status));

    return Semantics(
      button: true,
      selected: selected,
      label: 'Filter by $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              count.when(
                data: (value) => CountUpText(
                  value,
                  style: context.text.heading.copyWith(
                    color: color,
                    fontSize: 26,
                  ),
                ),
                loading: () => const SkeletonLoader(width: 40, height: 24),
                error: (_, _) => Text(
                  '-',
                  style: context.text.heading.copyWith(color: color),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
