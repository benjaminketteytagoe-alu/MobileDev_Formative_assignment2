import 'package:cloud_firestore/cloud_firestore.dart';

/// Records a single status change in an incident's history subcollection.
class HistoryEntryModel {
  final String id;
  final String fromStatus;
  final String toStatus;
  final String byUid;
  final String byName;
  final String? note;
  final DateTime at;

  HistoryEntryModel({
    this.id = '',
    required this.fromStatus,
    required this.toStatus,
    required this.byUid,
    required this.byName,
    this.note,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  factory HistoryEntryModel.fromJson(String id, Map<String, dynamic> json) {
    return HistoryEntryModel(
      id: id,
      fromStatus: json['fromStatus'] as String? ?? '',
      toStatus: json['toStatus'] as String? ?? '',
      byUid: json['byUid'] as String? ?? '',
      byName: json['byName'] as String? ?? '',
      note: json['note'] as String?,
      at: (json['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromStatus': fromStatus,
      'toStatus': toStatus,
      'byUid': byUid,
      'byName': byName,
      if (note != null) 'note': note,
      'at': Timestamp.fromDate(at),
    };
  }
}
