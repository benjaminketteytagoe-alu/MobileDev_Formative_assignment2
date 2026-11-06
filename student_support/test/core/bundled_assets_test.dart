import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:student_support/core/dicebear.dart';
import 'package:student_support/models/incident_model.dart';
import 'package:student_support/utils/incident_labels.dart';

/// Assets are only checked at runtime, so a missing file otherwise shows up as
/// a blank space on a real phone.
void main() {
  test('branding files exist', () {
    for (final path in [
      'assets/images/logo.svg',
      'assets/images/google_g.svg',
      'assets/images/app_icon.png',
      'assets/images/app_icon_foreground.png',
      'assets/images/logo_splash.png',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('every category has an illustration and a DiceBear icon', () {
    for (final category in IncidentModel.categories) {
      for (final path in [
        IncidentLabels.categoryAsset(category)!,
        DiceBear.categoryIcon(category),
      ]) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }
  });

  test('every mascot exists', () {
    for (final path in [
      DiceBear.mascotEmpty,
      DiceBear.mascotSearch,
      DiceBear.mascotError,
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('photos are in formats Flutter can decode on every device', () {
    const supported = {'.jpg', '.jpeg', '.png', '.webp', '.svg', '.txt'};
    final files = Directory('assets/images').listSync(recursive: true);
    for (final file in files.whereType<File>()) {
      final name = file.path.toLowerCase();
      expect(
        supported.any(name.endsWith),
        isTrue,
        reason: '${file.path} will not decode. Convert it to JPEG.',
      );
    }
  });
}
