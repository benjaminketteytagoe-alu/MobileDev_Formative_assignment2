import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Display helpers shared by every screen that shows an incident.
class IncidentLabels {
  IncidentLabels._();

  static String status(String status) {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'in_review':
        return 'In Review';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'submitted':
        return AppColors.submitted;
      case 'in_review':
        return AppColors.inReview;
      case 'in_progress':
        return AppColors.inProgress;
      case 'resolved':
        return AppColors.resolved;
      case 'rejected':
        return AppColors.rejected;
      default:
        return AppColors.textHint;
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.schedule_outlined;
      case 'in_review':
        return Icons.search_outlined;
      case 'in_progress':
        return Icons.pending_actions_outlined;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  static String urgency(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      default:
        return urgency;
    }
  }

  static Color urgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'low':
        return AppColors.urgencyLow;
      case 'medium':
        return AppColors.urgencyMedium;
      case 'high':
        return AppColors.urgencyHigh;
      default:
        return AppColors.textHint;
    }
  }

  static IconData urgencyIcon(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'low':
        return Icons.arrow_downward;
      case 'medium':
        return Icons.remove_outlined;
      case 'high':
        return Icons.arrow_upward;
      default:
        return Icons.help_outline;
    }
  }

  static String category(String category) {
    if (category.isEmpty) return category;
    return category[0].toUpperCase() + category.substring(1);
  }

  static IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'facility':
        return Icons.build_outlined;
      case 'water':
        return Icons.water_drop_outlined;
      case 'electricity':
        return Icons.bolt_outlined;
      case 'furniture':
        return Icons.chair_outlined;
      case 'sanitation':
        return Icons.cleaning_services_outlined;
      case 'safety':
        return Icons.shield_outlined;
      default:
        return Icons.report_outlined;
    }
  }

  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'facility':
        return AppColors.categoryFacility;
      case 'water':
        return AppColors.categoryWater;
      case 'electricity':
        return AppColors.categoryElectricity;
      case 'furniture':
        return AppColors.categoryFurniture;
      case 'sanitation':
        return AppColors.categorySanitation;
      case 'safety':
        return AppColors.categorySafety;
      default:
        return AppColors.primary;
    }
  }

  /// Illustration for a category, or null for an unknown category.
  static String? categoryAsset(String category) {
    const known = {
      'facility',
      'water',
      'electricity',
      'furniture',
      'sanitation',
      'safety',
    };
    final key = category.toLowerCase();
    return known.contains(key) ? 'assets/images/categories/$key.svg' : null;
  }

  /// One-line description shown under each tile in the category picker.
  static String categoryHint(String category) {
    switch (category.toLowerCase()) {
      case 'facility':
        return 'Doors, roofs, lifts, buildings';
      case 'water':
        return 'Leaks, no water, broken taps';
      case 'electricity':
        return 'Outages, sockets, lights';
      case 'furniture':
        return 'Chairs, desks, beds, shelves';
      case 'sanitation':
        return 'Toilets, waste, cleanliness';
      case 'safety':
        return 'Hazards, security, lighting';
      default:
        return '';
    }
  }

  static String sector(String sector) {
    switch (sector) {
      case 'social_commons':
        return 'Social Commons';
      case 'enterprise_commons':
        return 'Enterprise Commons';
      case 'leadership_centre':
        return 'Leadership Centre';
      case 'collaboration_street':
        return 'Collaboration Street';
      default:
        return sector;
    }
  }

  static IconData sectorIcon(String sector) {
    switch (sector) {
      case 'social_commons':
        return Icons.groups_outlined;
      case 'enterprise_commons':
        return Icons.business_center_outlined;
      case 'leadership_centre':
        return Icons.account_balance_outlined;
      case 'collaboration_street':
        return Icons.handshake_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  static const String _locationSeparator = ' · ';

  /// "Leadership Centre · Room 204", or just the sector when no room or area
  /// was given.
  static String composeLocation(String sector, String detail) {
    final place = detail.trim();
    final name = IncidentLabels.sector(sector);
    return place.isEmpty ? name : '$name$_locationSeparator$place';
  }

  /// The room/area part of a location built by [composeLocation]. Older
  /// reports without a sector return their location unchanged.
  static String locationDetail(String location, String sector) {
    if (sector.isEmpty) return location;
    final name = IncidentLabels.sector(sector);
    if (location == name) return '';
    final prefix = '$name$_locationSeparator';
    return location.startsWith(prefix)
        ? location.substring(prefix.length)
        : location;
  }

  /// "Just now", "5m ago", "3h ago", "2d ago", or a plain date after a week.
  static String relativeDate(DateTime date, {DateTime? now}) {
    final difference = (now ?? DateTime.now()).difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
