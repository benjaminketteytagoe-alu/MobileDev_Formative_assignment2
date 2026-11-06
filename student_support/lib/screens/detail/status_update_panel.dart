import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_support/core/theme/app_colors.dart';
import 'package:student_support/core/theme/app_palette.dart';
import 'package:student_support/core/theme/app_radius.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/models/incident_model.dart';
import 'package:student_support/providers/auth_provider.dart';
import 'package:student_support/providers/incident_provider.dart';
import 'package:student_support/utils/error_messages.dart';
import 'package:student_support/utils/incident_labels.dart';

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
class StatusUpdatePanel extends ConsumerStatefulWidget {
  final IncidentModel incident;

  const StatusUpdatePanel({super.key, required this.incident});

  @override
  ConsumerState<StatusUpdatePanel> createState() => StatusUpdatePanelState();
}

class StatusUpdatePanelState extends ConsumerState<StatusUpdatePanel> {
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
          border: Border.all(
            color: context.palette.textHint.withValues(alpha: 0.2),
          ),
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
        border: Border.all(
          color: context.palette.accent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Update Status', style: context.text.title)),
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
