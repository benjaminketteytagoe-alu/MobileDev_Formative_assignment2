import 'package:cloud_firestore/cloud_firestore.dart';

/// A report the user started and chose to keep for later. Stored at
/// users/{uid}/drafts/current, so each user has at most one draft.
class ReportDraftModel {
  final String title;
  final String description;
  final String category;

  /// One of IncidentModel.sectors, or '' if none was picked yet.
  final String sector;
  final String locationDetail;
  final String urgency;

  /// Paths of photos on this phone. They are not uploaded until the report
  /// is submitted, so on another device they are skipped.
  final List<String> localImagePaths;
  final DateTime updatedAt;

  ReportDraftModel({
    this.title = '',
    this.description = '',
    this.category = 'facility',
    this.sector = '',
    this.locationDetail = '',
    this.urgency = 'medium',
    this.localImagePaths = const [],
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// True when there is nothing worth restoring.
  bool get isEmpty =>
      title.trim().isEmpty &&
      description.trim().isEmpty &&
      locationDetail.trim().isEmpty &&
      sector.isEmpty &&
      localImagePaths.isEmpty;

  factory ReportDraftModel.fromJson(Map<String, dynamic> json) {
    return ReportDraftModel(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'facility',
      sector: json['sector'] as String? ?? '',
      locationDetail: json['locationDetail'] as String? ?? '',
      urgency: json['urgency'] as String? ?? 'medium',
      localImagePaths: List<String>.from(json['localImagePaths'] ?? []),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'sector': sector,
      'locationDetail': locationDetail,
      'urgency': urgency,
      'localImagePaths': localImagePaths,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
