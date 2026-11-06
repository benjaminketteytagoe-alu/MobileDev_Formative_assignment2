import 'package:cloud_firestore/cloud_firestore.dart';

/// In-app notification for a user (e.g., status change on their report).
class NotificationModel {
  final String id;
  final String userId;
  final String message;
  final String? incidentId;
  final bool read;
  final DateTime at;

  NotificationModel({
    this.id = '',
    required this.userId,
    required this.message,
    this.incidentId,
    this.read = false,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  factory NotificationModel.fromJson(String id, Map<String, dynamic> json) {
    return NotificationModel(
      id: id,
      userId: json['userId'] as String? ?? '',
      message: json['message'] as String? ?? '',
      incidentId: json['incidentId'] as String?,
      read: json['read'] as bool? ?? false,
      at: (json['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'message': message,
      if (incidentId != null) 'incidentId': incidentId,
      'read': read,
      'at': Timestamp.fromDate(at),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? message,
    String? incidentId,
    bool? read,
    DateTime? at,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      incidentId: incidentId ?? this.incidentId,
      read: read ?? this.read,
      at: at ?? this.at,
    );
  }
}
