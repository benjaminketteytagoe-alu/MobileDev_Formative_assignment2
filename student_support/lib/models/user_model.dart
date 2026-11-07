import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { student, staff }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final int reportsSubmitted;
  final DateTime createdAt;

  UserModel({
    this.id = '',
    required this.name,
    required this.email,
    this.role = UserRole.student,
    this.reportsSubmitted = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(String id, Map<String, dynamic> json) {
    return UserModel(
      id: id,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: _parseRole(json['role'] as String? ?? 'student'),
      reportsSubmitted: (json['reportsSubmitted'] as num?)?.toInt() ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'reportsSubmitted': reportsSubmitted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static UserRole _parseRole(String role) {
    switch (role) {
      case 'staff':
        return UserRole.staff;
      default:
        return UserRole.student;
    }
  }

  /// Creates a UserModel from a Firebase Auth User (fallback when Firestore is unavailable)
  factory UserModel.fromFirebaseUser(User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      name:
          firebaseUser.displayName ??
          firebaseUser.email?.split('@').first ??
          'User',
      email: firebaseUser.email ?? '',
      role: UserRole.student,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    int? reportsSubmitted,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      reportsSubmitted: reportsSubmitted ?? this.reportsSubmitted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
