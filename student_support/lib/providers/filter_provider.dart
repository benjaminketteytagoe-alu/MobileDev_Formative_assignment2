import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which list a filter belongs to. Each list keeps its own filter so that
/// changing one screen does not change another.
enum FeedScope { home, staff }

class IncidentFilter {
  /// Empty string means "all categories".
  final String category;

  /// Empty string means "all statuses".
  final String status;

  /// Empty string means "all urgencies".
  final String urgency;

  /// Empty string means "all sectors". Applied on the client, like search.
  final String sector;

  final String search;

  const IncidentFilter({
    this.category = '',
    this.status = '',
    this.urgency = '',
    this.sector = '',
    this.search = '',
  });

  bool get isActive =>
      category.isNotEmpty ||
      status.isNotEmpty ||
      urgency.isNotEmpty ||
      sector.isNotEmpty ||
      search.trim().isNotEmpty;

  IncidentFilter copyWith({
    String? category,
    String? status,
    String? urgency,
    String? sector,
    String? search,
  }) {
    return IncidentFilter(
      category: category ?? this.category,
      status: status ?? this.status,
      urgency: urgency ?? this.urgency,
      sector: sector ?? this.sector,
      search: search ?? this.search,
    );
  }
}

final incidentFilterProvider = StateProvider.family<IncidentFilter, FeedScope>((
  ref,
  scope,
) {
  return const IncidentFilter();
});
