import 'package:flutter_test/flutter_test.dart';
import 'package:student_support/models/incident_model.dart';
import 'package:student_support/models/user_model.dart';
import 'package:student_support/providers/filter_provider.dart';
import 'package:student_support/services/auth_service.dart';
import 'package:student_support/services/storage_service.dart';
import 'package:student_support/utils/incident_labels.dart';

void main() {
  IncidentModel incident({
    String title = 'Broken tap',
    String location = 'Block A',
  }) {
    return IncidentModel(
      title: title,
      description: 'Water is leaking in the second floor bathroom',
      category: 'water',
      location: location,
      reporterId: 'u1',
      reporterName: 'Jane Doe',
    );
  }

  group('IncidentModel.matchesQuery', () {
    test('matches title, location, category and reporter, ignoring case', () {
      final item = incident();
      expect(item.matchesQuery('TAP'), isTrue);
      expect(item.matchesQuery('block a'), isTrue);
      expect(item.matchesQuery('water'), isTrue);
      expect(item.matchesQuery('jane'), isTrue);
    });

    test('an empty query matches everything', () {
      expect(incident().matchesQuery('   '), isTrue);
    });

    test('returns false when nothing matches', () {
      expect(incident().matchesQuery('electricity'), isFalse);
    });
  });

  group('IncidentFilter', () {
    test('is inactive by default', () {
      expect(const IncidentFilter().isActive, isFalse);
    });

    test('copyWith keeps the other fields', () {
      final filter = const IncidentFilter(category: 'water')
          .copyWith(status: 'submitted');
      expect(filter.category, 'water');
      expect(filter.status, 'submitted');
      expect(filter.isActive, isTrue);
    });

    test('whitespace-only search does not count as a filter', () {
      expect(const IncidentFilter(search: '  ').isActive, isFalse);
    });
  });

  group('AuthService.roleForEmail', () {
    test('every university address starts as a student', () {
      expect(AuthService.roleForEmail('a@alustudent.com'), UserRole.student);
      expect(AuthService.roleForEmail('B@ALUEDUCATION.COM'), UserRole.student);
    });

    test('rejects other domains', () {
      expect(AuthService.roleForEmail('someone@gmail.com'), isNull);
    });
  });

  group('StorageService helpers', () {
    test('normalises file extensions', () {
      expect(StorageService.extensionOf('/tmp/photo.JPEG'), 'jpg');
      expect(StorageService.extensionOf('/tmp/photo.png'), 'png');
      expect(StorageService.extensionOf('/tmp/photo'), 'jpg');
    });

    test('derives an image content type', () {
      expect(StorageService.contentTypeFor('a.png'), 'image/png');
      expect(StorageService.contentTypeFor('a.jpg'), 'image/jpeg');
    });
  });

  group('StorageService.pathFromUrl', () {
    const base =
        'https://example.supabase.co/storage/v1/object/public/incident-photos';

    test('finds the path of a photo in the bucket', () {
      expect(
        StorageService.pathFromUrl('$base/incidents/uid1/123_0.jpg'),
        'incidents/uid1/123_0.jpg',
      );
    });

    test('ignores URLs from anywhere else', () {
      expect(
        StorageService.pathFromUrl('http://10.0.2.2:9199/v0/b/x/o/a.jpg'),
        isNull,
      );
      expect(StorageService.pathFromUrl('$base/'), isNull);
    });
  });

  group('IncidentLabels', () {
    test('formats statuses and categories', () {
      expect(IncidentLabels.status('in_progress'), 'In Progress');
      expect(IncidentLabels.category('sanitation'), 'Sanitation');
    });

    test('relativeDate covers each range', () {
      final now = DateTime(2026, 10, 23, 12);
      expect(IncidentLabels.relativeDate(now, now: now), 'Just now');
      expect(
        IncidentLabels.relativeDate(
          now.subtract(const Duration(minutes: 5)),
          now: now,
        ),
        '5m ago',
      );
      expect(
        IncidentLabels.relativeDate(
          now.subtract(const Duration(hours: 3)),
          now: now,
        ),
        '3h ago',
      );
      expect(
        IncidentLabels.relativeDate(DateTime(2026, 10, 1), now: now),
        '1/10/2026',
      );
    });
  });
}
