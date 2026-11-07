import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../utils/incident_labels.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'category_art.dart';
import 'dicebear_art.dart';
import 'user_avatar.dart';

class IncidentCard extends StatelessWidget {
  final String id;
  final String title;
  final String category;
  final String status;
  final String urgency;
  final String location;
  final String? imageUrl;
  final String timestamp;
  final int upvoteCount;
  final String reporterId;
  final String reporterName;
  final VoidCallback onTap;

  const IncidentCard({
    super.key,
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    this.urgency = 'medium',
    required this.location,
    this.imageUrl,
    required this.timestamp,
    this.upvoteCount = 0,
    this.reporterId = '',
    this.reporterName = '',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'incident-$id',
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl!,
                              fit: BoxFit.cover,
                              // Decode at display size, not full resolution.
                              memCacheWidth: 288,
                              placeholder: (_, _) => _categoryArt(),
                              errorWidget: (_, _, _) => _categoryArt(),
                            ),
                          )
                        : _categoryArt(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(child: _details(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _details(BuildContext context) {
    final caption = context.text.caption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.text.title.copyWith(fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            CategoryIconBadge(category: category, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                location,
                style: caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            if (reporterId.isNotEmpty) ...[
              UserAvatar(userId: reporterId, name: reporterName, size: 20),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                timestamp,
                style: caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (upvoteCount > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.arrow_upward,
                size: 14,
                color: context.palette.textHint,
              ),
              const SizedBox(width: 2),
              Text('$upvoteCount', style: caption.copyWith(fontSize: 11)),
            ],
            const Spacer(),
            _urgencyBadge(),
            const SizedBox(width: AppSpacing.xs),
            _statusBadge(context),
          ],
        ),
      ],
    );
  }

  Widget _categoryArt() {
    return CategoryArt(
      category: category,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    );
  }

  Widget _statusBadge(BuildContext context) {
    final color = IncidentLabels.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        IncidentLabels.status(status),
        style: context.text.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _urgencyBadge() {
    final color = IncidentLabels.urgencyColor(urgency);
    return Tooltip(
      message: '${IncidentLabels.urgency(urgency)} urgency',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(
          IncidentLabels.urgencyIcon(urgency),
          size: 12,
          color: color,
        ),
      ),
    );
  }
}
