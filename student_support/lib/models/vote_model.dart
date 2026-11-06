import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single user's vote on an incident (stored in the votes subcollection).
class VoteModel {
  final String uid;
  final DateTime at;

  VoteModel({required this.uid, DateTime? at}) : at = at ?? DateTime.now();

  factory VoteModel.fromJson(Map<String, dynamic> json) {
    return VoteModel(
      uid: json['uid'] as String? ?? '',
      at: (json['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'uid': uid, 'at': Timestamp.fromDate(at)};
  }
}
