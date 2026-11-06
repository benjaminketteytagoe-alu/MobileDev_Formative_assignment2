import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_support/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson creates correct model', () {
      final now = DateTime.now();
      final json = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'student',
        'createdAt': Timestamp.fromDate(now),
      };

      final model = UserModel.fromJson('user1', json);

      expect(model.id, 'user1');
      expect(model.name, 'John Doe');
      expect(model.email, 'john@example.com');
      expect(model.role, UserRole.student);
    });

    test('fromJson parses staff role', () {
      final json = {
        'name': 'Jane Staff',
        'email': 'jane@example.com',
        'role': 'staff',
        'createdAt': Timestamp.now(),
      };

      final model = UserModel.fromJson('user2', json);

      expect(model.role, UserRole.staff);
    });

    test('toJson creates correct map', () {
      final now = DateTime.now();
      final model = UserModel(
        id: 'user1',
        name: 'John Doe',
        email: 'john@example.com',
        role: UserRole.student,
        createdAt: now,
      );

      final json = model.toJson();

      expect(json['name'], 'John Doe');
      expect(json['email'], 'john@example.com');
      expect(json['role'], 'student');
    });

    test('toJson serializes staff role', () {
      final model = UserModel(
        name: 'Jane Staff',
        email: 'jane@example.com',
        role: UserRole.staff,
      );

      final json = model.toJson();

      expect(json['role'], 'staff');
    });

    test('copyWith updates fields correctly', () {
      final model = UserModel(
        name: 'John Doe',
        email: 'john@example.com',
        role: UserRole.student,
      );

      final updated = model.copyWith(name: 'John Updated');

      expect(updated.name, 'John Updated');
      expect(updated.email, 'john@example.com');
      expect(updated.role, UserRole.student);
    });

    test('fromJson handles null fields', () {
      final json = <String, dynamic>{};
      final model = UserModel.fromJson('user1', json);

      expect(model.id, 'user1');
      expect(model.name, '');
      expect(model.email, '');
      expect(model.role, UserRole.student);
    });
  });
}
