import 'package:flutter_test/flutter_test.dart';
import 'package:student_support/core/dicebear.dart';
import 'package:student_support/core/widgets/animated_svg_view.dart';

void main() {
  group('DiceBear.avatarUrl', () {
    test('uses the pinned version and an SVG avatar', () {
      final url = DiceBear.avatarUrl('uid-1');
      expect(url.scheme, 'https');
      expect(url.path, '/10.x/thumbs/svg');
    });

    test('sends the color list in a form the API accepts', () {
      final url = DiceBear.avatarUrl('uid-1');
      expect(url.toString(), isNot(contains('%2C')));
      expect(
        url.queryParametersAll['backgroundColor'],
        DiceBear.avatarBackgrounds,
      );
    });

    test('the same user always gets the same avatar', () {
      expect(DiceBear.avatarUrl('uid-1'), DiceBear.avatarUrl('uid-1'));
      expect(
        DiceBear.seedFor('uid-1'),
        isNot(DiceBear.seedFor('uid-2')),
      );
    });

    test('never sends the user id to DiceBear', () {
      const uid = 'firebase-uid-abc123';
      final url = DiceBear.avatarUrl(uid).toString();
      expect(url, isNot(contains(uid)));
      expect(DiceBear.seedFor(uid), matches(RegExp(r'^[0-9a-f]{24}$')));
    });
  });

  group('AnimatedSvgView.htmlFor', () {
    final html = AnimatedSvgView.htmlFor('<svg></svg>');

    test('embeds the SVG on a transparent page', () {
      expect(html, contains('<svg></svg>'));
      expect(html, contains('background:transparent'));
    });

    test('blocks everything except inline styles', () {
      expect(html, contains("default-src 'none'"));
      expect(html, contains("style-src 'unsafe-inline'"));
      expect(html, isNot(contains('<script')));
    });
  });
}
