import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_support/core/widgets/sector_picker.dart';
import 'package:student_support/models/incident_model.dart';
import 'package:student_support/models/report_draft_model.dart';
import 'package:student_support/providers/filter_provider.dart';
import 'package:student_support/utils/incident_labels.dart';

void main() {
  group('sectors', () {
    test('the four ALU sectors have readable names and icons', () {
      expect(IncidentModel.sectors.map(IncidentLabels.sector), [
        'Social Commons',
        'Enterprise Commons',
        'Leadership Centre',
        'Collaboration Street',
      ]);
      final icons = IncidentModel.sectors.map(IncidentLabels.sectorIcon);
      expect(icons.toSet().length, 4);
    });

    test('location is built from sector and room, and split back', () {
      final full = IncidentLabels.composeLocation('leadership_centre', ' Room 2 ');
      expect(full, 'Leadership Centre · Room 2');
      expect(IncidentLabels.locationDetail(full, 'leadership_centre'), 'Room 2');

      final bare = IncidentLabels.composeLocation('social_commons', '');
      expect(bare, 'Social Commons');
      expect(IncidentLabels.locationDetail(bare, 'social_commons'), '');
    });

    test('older reports without a sector keep their location', () {
      expect(IncidentLabels.locationDetail('Block A', ''), 'Block A');
    });

    test('IncidentModel stores the sector only when set', () {
      final withSector = IncidentModel(
        title: 't',
        description: 'd',
        category: 'water',
        location: 'Social Commons',
        sector: 'social_commons',
        reporterId: 'u',
        reporterName: 'U',
      );
      expect(withSector.toJson()['sector'], 'social_commons');
      final restored = IncidentModel.fromJson('id', withSector.toJson());
      expect(restored.sector, 'social_commons');

      final legacy = withSector.copyWith(sector: '');
      expect(legacy.toJson().containsKey('sector'), isFalse);
    });

    test('the sector filter counts as an active filter', () {
      expect(const IncidentFilter(sector: 'social_commons').isActive, isTrue);
    });
  });

  group('ReportDraftModel', () {
    test('a fresh draft is empty', () {
      expect(ReportDraftModel().isEmpty, isTrue);
      expect(ReportDraftModel(title: '   ').isEmpty, isTrue);
      expect(ReportDraftModel(sector: 'social_commons').isEmpty, isFalse);
      expect(ReportDraftModel(localImagePaths: ['/a.jpg']).isEmpty, isFalse);
    });

    test('survives a JSON round trip', () {
      final draft = ReportDraftModel(
        title: 'Leaking tap',
        description: 'Water on the floor',
        category: 'water',
        sector: 'enterprise_commons',
        locationDetail: 'Room 3',
        urgency: 'high',
        localImagePaths: ['/tmp/a.jpg'],
      );
      final copy = ReportDraftModel.fromJson(draft.toJson());
      expect(copy.title, draft.title);
      expect(copy.description, draft.description);
      expect(copy.category, draft.category);
      expect(copy.sector, draft.sector);
      expect(copy.locationDetail, draft.locationDetail);
      expect(copy.urgency, draft.urgency);
      expect(copy.localImagePaths, draft.localImagePaths);
    });
  });

  testWidgets('SectorPicker reports the tapped sector', (tester) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectorPicker(selected: '', onChanged: (s) => picked = s),
        ),
      ),
    );
    await tester.tap(find.text('Enterprise Commons'));
    expect(picked, 'enterprise_commons');
  });

  testWidgets('SectorPicker shows its error text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectorPicker(
            selected: '',
            errorText: 'Choose the campus sector',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Choose the campus sector'), findsOneWidget);
  });
}
