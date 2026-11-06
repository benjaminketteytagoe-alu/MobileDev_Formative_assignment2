import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  /// Categories a report can belong to. Must match the list in firestore.rules.
  static const List<String> categories = [
    'facility',
    'water',
    'electricity',
    'furniture',
    'sanitation',
    'safety',
  ];

  /// ALU campus sectors a report can be filed under. Must match the list in
  /// firestore.rules.
  static const List<String> sectors = [
    'social_commons',
    'enterprise_commons',
    'leadership_centre',
    'collaboration_street',
  ];

  /// Lifecycle of a report. Must match the list in firestore.rules.
  static const List<String> statuses = [
    'submitted',
    'in_review',
    'in_progress',
    'resolved',
    'rejected',
  ];

  /// Valid urgency levels.
  static const List<String> urgencies = ['low', 'medium', 'high'];

  /// Valid status transitions: fromStatus → [toStatuss].
  static const Map<String, List<String>> validTransitions = {
    'submitted': ['in_review', 'rejected'],
    'in_review': ['in_progress', 'rejected'],
    'in_progress': ['resolved', 'rejected'],
  };

  final String id;
  final String title;
  final String description;
  final String category;
  /// Human-readable place, e.g. "Leadership Centre · Room 204". Built from
  /// [sector] and the optional room/area the reporter typed.
  final String location;

  /// One of [sectors], or empty for reports filed before sectors existed.
  final String sector;
  final String urgency;
  final String status;
  final String reporterId;
  final String reporterName;
  final String? assignedTo;
  final String? assignedToName;
  final List<String> images;
  final List<String> searchKeywords;
  final int upvoteCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  IncidentModel({
    this.id = '',
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.sector = '',
    this.urgency = 'medium',
    this.status = 'submitted',
    required this.reporterId,
    required this.reporterName,
    this.assignedTo,
    this.assignedToName,
    this.images = const [],
    this.searchKeywords = const [],
    this.upvoteCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.resolvedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory IncidentModel.fromJson(String id, Map<String, dynamic> json) {
    return IncidentModel(
      id: id,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      location: json['location'] as String? ?? '',
      sector: json['sector'] as String? ?? '',
      urgency: json['urgency'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'submitted',
      reporterId: json['reporterId'] as String? ?? '',
      reporterName: json['reporterName'] as String? ?? '',
      assignedTo: json['assignedTo'] as String?,
      assignedToName: json['assignedToName'] as String?,
      images: List<String>.from(json['images'] ?? []),
      searchKeywords: List<String>.from(json['searchKeywords'] ?? []),
      upvoteCount: (json['upvoteCount'] as num?)?.toInt() ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (json['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      if (sector.isNotEmpty) 'sector': sector,
      'urgency': urgency,
      'status': status,
      'reporterId': reporterId,
      'reporterName': reporterName,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (assignedToName != null) 'assignedToName': assignedToName,
      'images': images,
      'searchKeywords': searchKeywords,
      'upvoteCount': upvoteCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
    };
  }

  IncidentModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    String? sector,
    String? urgency,
    String? status,
    String? reporterId,
    String? reporterName,
    String? assignedTo,
    String? assignedToName,
    List<String>? images,
    List<String>? searchKeywords,
    int? upvoteCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return IncidentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      sector: sector ?? this.sector,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      images: images ?? this.images,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  /// Case-insensitive text search across the fields a user would expect.
  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        location.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        reporterName.toLowerCase().contains(q);
  }

  /// Checks whether [newStatus] is a valid transition from [currentStatus].
  static bool canTransition(String currentStatus, String newStatus) {
    final allowed = validTransitions[currentStatus] ?? [];
    return allowed.contains(newStatus);
  }

  /// Generates lowercase search keywords from the title.
  static List<String> generateSearchKeywords(String title) {
    final tokens = title
        .toLowerCase()
        .split(RegExp(r'[\s,;.!?]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    return tokens.toSet().toList();
  }
}
