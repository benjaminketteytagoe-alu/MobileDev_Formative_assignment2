import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_support/core/dicebear.dart';
import 'package:student_support/core/theme/app_colors.dart';
import 'package:student_support/core/theme/app_palette.dart';
import 'package:student_support/core/theme/app_radius.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/core/widgets/category_art.dart';
import 'package:student_support/core/widgets/custom_app_bar.dart';
import 'package:student_support/core/widgets/dicebear_art.dart';
import 'package:student_support/core/widgets/empty_state_widget.dart';
import 'package:student_support/core/widgets/flag_report_button.dart';
import 'package:student_support/core/widgets/status_timeline_widget.dart';
import 'package:student_support/core/widgets/upvote_button.dart';
import 'package:student_support/core/widgets/user_avatar.dart';
import 'package:student_support/models/incident_model.dart';
import 'package:student_support/navigation/app_router.dart';
import 'package:student_support/providers/auth_provider.dart';
import 'package:student_support/providers/incident_provider.dart';
import 'package:student_support/utils/error_messages.dart';
import 'package:student_support/screens/detail/status_progress.dart';
import 'package:student_support/screens/detail/status_update_panel.dart';
import 'package:student_support/utils/incident_labels.dart';

class IncidentDetailScreen extends ConsumerWidget {
  final String incidentId;

  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isStaff = authState.valueOrNull?.isStaff ?? false;
    final currentUserId = authState.valueOrNull?.user?.id ?? '';
    final incidentAsync = ref.watch(incidentByIdProvider(incidentId));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Report Details',
        showBack: true,
        actions: [
          Builder(
            builder: (context) {
              return incidentAsync.when(
                data: (incident) {
                  if (incident == null) return const SizedBox.shrink();
                  final isOwner = incident.reporterId == currentUserId;
                  final canEdit = isOwner && incident.status == 'submitted';
                  if (!canEdit) return const SizedBox.shrink();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit report',
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRouter.editReport,
                            arguments: {'incidentId': incidentId},
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete report',
                        onPressed: () =>
                            _showDeleteDialog(context, ref, incidentId),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      body: incidentAsync.when(
        data: (incident) {
          if (incident == null) {
            return const EmptyStateWidget(
              icon: Icons.error_outline,
              illustration: DiceBearMascot(DiceBear.mascotSearch),
              title: 'Not found',
              message: 'This report no longer exists.',
            );
          }
          return _DetailBody(
            incident: incident,
            isStaff: isStaff,
            isOwner: incident.reporterId == currentUserId,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          illustration: const DiceBearMascot(DiceBear.mascotError),
          title: 'Could not load report',
          message: describeError(error),
        ),
      ),
    );
  }

  static Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String incidentId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete report?'),
        content: const Text(
          'This will permanently delete this report. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(incidentControllerProvider).deleteIncident(incidentId);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Report deleted.')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete. ${describeError(e)}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _DetailBody extends StatelessWidget {
  final IncidentModel incident;
  final bool isStaff;
  final bool isOwner;

  const _DetailBody({
    required this.incident,
    required this.isStaff,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (incident.images.isEmpty) ...[
            // Shares its tag with the card thumbnail so it animates across.
            Hero(
              tag: 'incident-${incident.id}',
              child: SizedBox(
                height: 170,
                width: double.infinity,
                child: CategoryArt(
                  category: incident.category,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          // Wraps rather than overflows with a large system font size.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusBadge(status: incident.status),
              _UrgencyBadge(urgency: incident.urgency),
              Text(
                IncidentLabels.relativeDate(incident.createdAt),
                style: context.text.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(incident.title, style: context.text.heading),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryIconBadge(category: incident.category, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    IncidentLabels.category(incident.category),
                    style: context.text.body,
                  ),
                ],
              ),
              _IconText(
                icon: Icons.location_on_outlined,
                text: incident.location,
              ),
              if (incident.upvoteCount > 0)
                _IconText(
                  icon: Icons.arrow_upward,
                  text: '${incident.upvoteCount} "Me too"',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          StatusProgress(status: incident.status),
          const SizedBox(height: AppSpacing.lg),
          _Section(label: 'Description', value: incident.description),
          const SizedBox(height: AppSpacing.lg),
          if (incident.anonymous)
            const _Section(
              label: 'Reported by',
              value: IncidentModel.anonymousName,
            )
          else
            _PersonSection(
              label: 'Reported by',
              userId: incident.reporterId,
              name: incident.reporterName,
            ),
          const SizedBox(height: AppSpacing.lg),
          if (incident.assignedTo == null)
            const _Section(label: 'Assigned to', value: 'Not assigned yet')
          else
            _PersonSection(
              label: 'Assigned to',
              userId: incident.assignedTo!,
              name: incident.assignedToName ?? 'Staff',
            ),
          const SizedBox(height: AppSpacing.lg),
          _Section(
            label: 'Last updated',
            value: IncidentLabels.relativeDate(incident.updatedAt),
          ),
          if (incident.resolvedAt != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _Section(
              label: 'Resolved',
              value: IncidentLabels.relativeDate(incident.resolvedAt!),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (incident.images.isNotEmpty) ...[
            Text('Photos', style: context.text.title),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: incident.images.length,
                itemBuilder: (context, index) {
                  final image = Container(
                    width: 250,
                    decoration: BoxDecoration(
                      color: context.palette.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: CachedNetworkImage(
                        imageUrl: incident.images[index],
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, _, _) => const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    // The first photo shares its tag with the thumbnail on
                    // the incident card, so it animates between screens.
                    child: index == 0
                        ? Hero(tag: 'incident-${incident.id}', child: image)
                        : image,
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (isStaff) ...[
            FlagCountNotice(incidentId: incident.id),
            StatusUpdatePanel(incident: incident),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (!isOwner) ...[
            UpvoteButton(incidentId: incident.id),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (!isOwner && !isStaff) ...[
            FlagReportButton(incidentId: incident.id),
            const SizedBox(height: AppSpacing.lg),
          ],
          StatusTimelineWidget(incidentId: incident.id),
        ],
      ),
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  final String urgency;

  const _UrgencyBadge({required this.urgency});

  @override
  Widget build(BuildContext context) {
    final color = IncidentLabels.urgencyColor(urgency);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IncidentLabels.urgencyIcon(urgency), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            IncidentLabels.urgency(urgency),
            style: context.text.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: context.palette.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(text, style: context.text.body)),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final String value;

  const _Section({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.caption),
        const SizedBox(height: AppSpacing.sm),
        Text(value, style: context.text.body),
      ],
    );
  }
}

/// A labelled person with their avatar.
class _PersonSection extends StatelessWidget {
  final String label;
  final String userId;
  final String name;

  const _PersonSection({
    required this.label,
    required this.userId,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.caption),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            UserAvatar(userId: userId, name: name, size: 32),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(name, style: context.text.body)),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = IncidentLabels.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IncidentLabels.statusIcon(status), size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            IncidentLabels.status(status),
            style: context.text.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
