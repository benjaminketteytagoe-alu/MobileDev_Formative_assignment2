import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:student_support/core/widgets/motion.dart';
import 'package:student_support/core/widgets/status_timeline_widget.dart';
import 'package:student_support/core/widgets/upvote_button.dart';
import 'package:student_support/core/widgets/user_avatar.dart';
import 'package:student_support/models/incident_model.dart';
import 'package:student_support/navigation/app_router.dart';
import 'package:student_support/providers/auth_provider.dart';
import 'package:student_support/providers/incident_provider.dart';
import 'package:student_support/utils/error_messages.dart';
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
          _StatusProgress(status: incident.status),
          const SizedBox(height: AppSpacing.lg),
          _Section(label: 'Description', value: incident.description),
          const SizedBox(height: AppSpacing.lg),
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
          if (isStaff) _StatusUpdatePanel(incident: incident),
          const SizedBox(height: AppSpacing.lg),
          if (!isOwner) ...[
            UpvoteButton(incidentId: incident.id),
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

/// Tracker showing how far a report has progressed. A rejected report leaves
/// the normal path, so its last step becomes a red "Rejected".
class _StatusProgress extends StatelessWidget {
  final String status;

  const _StatusProgress({required this.status});

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

/// Asks staff why a report is rejected. Returns the reason, which the student
/// sees in the status history, or null if cancelled.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reason = _reason.text.trim();
    return AlertDialog(
      title: const Text('Reject this report?'),
      content: TextField(
        controller: _reason,
        autofocus: true,
        maxLines: 3,
        maxLength: 300,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Reason',
          hintText: 'The student will see this',
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: reason.isEmpty
              ? null
              : () => Navigator.of(context).pop(reason),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Reject report'),
        ),
      ],
    );
  }
}

/// Staff-only controls. Shows progress while saving and reports the result.
class _StatusUpdatePanel extends ConsumerStatefulWidget {
  final IncidentModel incident;

  const _StatusUpdatePanel({required this.incident});

  @override
  ConsumerState<_StatusUpdatePanel> createState() => _StatusUpdatePanelState();
}

class _StatusUpdatePanelState extends ConsumerState<_StatusUpdatePanel> {
  String? _saving;
  bool _assigning = false;

  Future<void> _assignToMe() async {
    if (_assigning) return;
    setState(() => _assigning = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(incidentControllerProvider).assignToMe(widget.incident.id);
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        const SnackBar(content: Text('Report assigned to you.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not assign. ${describeError(e)}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  Future<void> _update(String status) async {
    if (_saving != null || status == widget.incident.status) return;

    String? note;
    if (status == 'rejected') {
      note = await showDialog<String>(
        context: context,
        builder: (context) => const _RejectDialog(),
      );
      if (note == null || !mounted) return;
    }

    if (status == 'resolved') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mark as resolved?'),
          content: const Text(
            'The student who reported this issue will see it as resolved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Mark resolved'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _saving = status);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(incidentControllerProvider)
          .updateStatus(widget.incident.id, status, note: note);
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Status changed to ${IncidentLabels.status(status)}.'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not update status. ${describeError(e)}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  List<String> _validNextStatuses() {
    return IncidentModel.validTransitions[widget.incident.status] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(
      authStateProvider.select((s) => s.valueOrNull?.user?.id),
    );
    final nextStatuses = _validNextStatuses();
    if (nextStatuses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.palette.textHint.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.palette.textHint.withValues(alpha: 0.2)),
        ),
        child: Text(
          'This report is ${IncidentLabels.status(widget.incident.status)}. No further status changes are allowed.',
          style: context.text.body,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.palette.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Update Status', style: context.text.title),
              ),
              if (widget.incident.assignedTo != currentUid)
                TextButton.icon(
                  onPressed: _assigning ? null : _assignToMe,
                  icon: _assigning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.assignment_ind_outlined, size: 18),
                  label: const Text('Assign to me'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.palette.accent,
                  ),
                )
              else
                Text(
                  'Assigned to you',
                  style: context.text.caption.copyWith(
                    color: AppColors.resolved,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final status in nextStatuses) ...[
                if (status != nextStatuses.first)
                  const SizedBox(width: AppSpacing.sm),
                Expanded(child: _statusButton(status)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusButton(String status) {
    final color = IncidentLabels.statusColor(status);
    final isSaving = _saving == status;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: _saving == null ? () => _update(status) : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: color),
          ),
          child: isSaving
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : Text(
                  IncidentLabels.status(status),
                  textAlign: TextAlign.center,
                  style: context.text.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
