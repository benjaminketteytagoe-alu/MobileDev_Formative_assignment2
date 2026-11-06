import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_support/models/incident_model.dart';

void main() {
  group('IncidentModel', () {
    test('fromJson creates correct model', () {
      final now = DateTime.now();
      final json = {
        'title': 'Broken Chair',
        'description': 'Chair in room 101 is broken',
        'category': 'furniture',
        'location': 'Room 101',
        'status': 'submitted',
        'reporterId': 'user123',
        'reporterName': 'John Doe',
        'images': ['https://example.com/image.jpg'],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final model = IncidentModel.fromJson('doc1', json);

      expect(model.id, 'doc1');
      expect(model.title, 'Broken Chair');
      expect(model.description, 'Chair in room 101 is broken');
      expect(model.category, 'furniture');
      expect(model.location, 'Room 101');
      expect(model.status, 'submitted');
      expect(model.reporterId, 'user123');
      expect(model.reporterName, 'John Doe');
      expect(model.images, ['https://example.com/image.jpg']);
    });

    test('toJson creates correct map', () {
      final now = DateTime.now();
      final model = IncidentModel(
        id: 'doc1',
        title: 'Broken Chair',
        description: 'Chair in room 101 is broken',
        category: 'furniture',
        location: 'Room 101',
        reporterId: 'user123',
        reporterName: 'John Doe',
        images: ['https://example.com/image.jpg'],
        createdAt: now,
        updatedAt: now,
      );

      final json = model.toJson();

      expect(json['title'], 'Broken Chair');
      expect(json['description'], 'Chair in room 101 is broken');
      expect(json['category'], 'furniture');
      expect(json['location'], 'Room 101');
      expect(json['status'], 'submitted');
      expect(json['reporterId'], 'user123');
      expect(json['reporterName'], 'John Doe');
      expect(json['images'], ['https://example.com/image.jpg']);
    });

    test('copyWith updates fields correctly', () {
      final model = IncidentModel(
        title: 'Broken Chair',
        description: 'Chair in room 101 is broken',
        category: 'furniture',
        location: 'Room 101',
        reporterId: 'user123',
        reporterName: 'John Doe',
      );

      final updated = model.copyWith(status: 'resolved');

      expect(updated.status, 'resolved');
      expect(updated.title, 'Broken Chair');
    });

    test('fromJson handles null fields', () {
      final json = <String, dynamic>{};
      final model = IncidentModel.fromJson('doc1', json);

      expect(model.id, 'doc1');
      expect(model.title, '');
      expect(model.status, 'submitted');
      expect(model.images, isEmpty);
      expect(model.assignedTo, isNull);
      expect(model.assignedToName, isNull);
    });

    test('assignee round-trips through toJson and fromJson', () {
      final model = IncidentModel(
        title: 'Broken Chair',
        description: 'Chair in room 101 is broken',
        category: 'furniture',
        location: 'Room 101',
        reporterId: 'user123',
        reporterName: 'John Doe',
        assignedTo: 'staff1',
        assignedToName: 'Ama Staff',
      );

      final json = model.toJson();
      expect(json['assignedTo'], 'staff1');
      expect(json['assignedToName'], 'Ama Staff');

      final restored = IncidentModel.fromJson('doc1', json);
      expect(restored.assignedTo, 'staff1');
      expect(restored.assignedToName, 'Ama Staff');
    });

    test('unassigned reports leave the assignee out of toJson', () {
      final json = IncidentModel(
        title: 'Broken Chair',
        description: 'Chair in room 101 is broken',
        category: 'furniture',
        location: 'Room 101',
        reporterId: 'user123',
        reporterName: 'John Doe',
      ).toJson();
      // The create rule only allows the listed keys, so these must be absent.
      expect(json.containsKey('assignedTo'), isFalse);
      expect(json.containsKey('assignedToName'), isFalse);
    });
  });
}
