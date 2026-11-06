import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/incident_model.dart';
import '../../navigation/app_router.dart';
import '../../utils/error_messages.dart';
import '../../utils/incident_labels.dart';
import '../dicebear.dart';
import '../theme/app_spacing.dart';
import 'dicebear_art.dart';
import 'empty_state_widget.dart';
import 'incident_card.dart';
import 'motion.dart';
import 'skeleton_loader.dart';

/// Loading, error, empty and data states for any list of incidents.
class IncidentListView extends StatefulWidget {
  final AsyncValue<List<IncidentModel>> incidents;
  final Widget emptyState;
  final VoidCallback onRetry;

  const IncidentListView({
    super.key,
    required this.incidents,
    required this.emptyState,
    required this.onRetry,
  });

  @override
  State<IncidentListView> createState() => _IncidentListViewState();
}

class _IncidentListViewState extends State<IncidentListView> {
  static const int _maxStaggered = 6;

  /// Cards that have already animated in, so scrolling back does not replay it.
  final Set<String> _shown = {};

  Widget _card(IncidentModel incident, int index) {
    final card = IncidentCard(
      id: incident.id,
      title: incident.title,
      category: incident.category,
      status: incident.status,
      urgency: incident.urgency,
      location: incident.location,
      imageUrl: incident.images.isNotEmpty ? incident.images.first : null,
      timestamp: IncidentLabels.relativeDate(incident.createdAt),
      upvoteCount: incident.upvoteCount,
      reporterId: incident.reporterId,
      reporterName: incident.reporterName,
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRouter.incidentDetail, arguments: incident.id),
    );
    if (!_shown.add(incident.id)) return card;
    return FadeSlideIn(
      delay: Duration(milliseconds: 50 * index.clamp(0, _maxStaggered)),
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => widget.onRetry(),
      child: widget.incidents.when(
        data: (items) {
          if (items.isEmpty) return widget.emptyState;
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl * 2),
            itemCount: items.length,
            itemBuilder: (context, index) => _card(items[index], index),
          );
        },
        loading: () => ListView.builder(
          itemCount: 5,
          itemBuilder: (_, _) => const IncidentCardSkeleton(),
        ),
        error: (error, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          illustration: const DiceBearMascot(DiceBear.mascotError),
          title: 'Could not load reports',
          message: describeError(error),
          actionLabel: 'Retry',
          onAction: widget.onRetry,
        ),
      ),
    );
  }
}
