import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_support/core/app_assets.dart';
import 'package:student_support/core/widgets/category_art.dart';
import 'package:student_support/core/widgets/category_picker.dart';
import 'package:student_support/models/incident_model.dart';
import 'package:student_support/utils/incident_labels.dart';

void main() {
  group('IncidentLabels category helpers', () {
    test('every category has its own color and an illustration', () {
      final colors = IncidentModel.categories
          .map(IncidentLabels.categoryColor)
          .toSet();
      expect(colors.length, IncidentModel.categories.length);
      for (final category in IncidentModel.categories) {
        expect(
          IncidentLabels.categoryAsset(category),
          'assets/images/categories/$category.svg',
        );
        expect(IncidentLabels.categoryHint(category), isNotEmpty);
      }
    });

    test('unknown categories have no illustration', () {
      expect(IncidentLabels.categoryAsset('parking'), isNull);
    });
  });

  testWidgets('CategoryArt draws the SVG for a known category', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 120,
          height: 80,
          child: CategoryArt(category: 'water'),
        ),
      ),
    );
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('CategoryArt falls back to an icon for unknown categories', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 120,
          height: 80,
          child: CategoryArt(category: 'x'),
        ),
      ),
    );
    expect(find.byType(SvgPicture), findsNothing);
    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('CategoryPicker reports the tapped category', (tester) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryPicker(
            selected: 'facility',
            onChanged: (c) => picked = c,
          ),
        ),
      ),
    );
    // The cards scroll horizontally, so bring each one into view first.
    for (final category in IncidentModel.categories) {
      final label = find.text(IncidentLabels.category(category));
      await tester.scrollUntilVisible(label, 100, scrollable: find.byType(Scrollable));
      expect(label, findsOneWidget);
    }
    await tester.tap(find.text('Safety'));
    expect(picked, 'safety');
  });

  testWidgets('CategoryPicker lays the cards out in one horizontal row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryPicker(selected: 'water', onChanged: (_) {}),
        ),
      ),
    );
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.scrollDirection, Axis.horizontal);
    final facility = tester.getTopLeft(find.text('Facility'));
    final water = tester.getTopLeft(find.text('Water'));
    expect(water.dy, facility.dy);
    expect(water.dx, greaterThan(facility.dx));
  });

  testWidgets('CategoryPicker with showAll reports "" for All', (tester) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryPicker(
            selected: 'water',
            showAll: true,
            onChanged: (c) => picked = c,
          ),
        ),
      ),
    );
    await tester.tap(find.text('All'));
    expect(picked, '');
  });

  group('category photos', () {
    tearDown(() => AppAssets.debugAvailable = const {});

    testWidgets('CategoryArt prefers a bundled photo over the illustration', (
      tester,
    ) async {
      AppAssets.debugAvailable = {'assets/images/categories/water.jpg'};
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 120,
            height: 80,
            child: CategoryArt(category: 'water'),
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as ResizeImage).imageProvider, isA<AssetImage>());
      expect(find.byType(SvgPicture), findsNothing);
    });

    test('AppAssets finds any supported extension', () {
      AppAssets.debugAvailable = {
        'assets/images/campus_hero.webp',
        'assets/images/splash_image.png',
      };
      expect(AppAssets.campusHero, 'assets/images/campus_hero.webp');
      expect(AppAssets.splashImage, 'assets/images/splash_image.png');
      expect(AppAssets.categoryPhoto('water'), isNull);
    });
  });
}
