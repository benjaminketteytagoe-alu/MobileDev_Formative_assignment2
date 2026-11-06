import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_support/core/widgets/user_avatar.dart';
import 'package:student_support/providers/avatar_provider.dart';
import 'package:student_support/services/avatar_service.dart';

class _FakeAvatars implements AvatarService {
  _FakeAvatars(this.svg);

  final String? svg;

  @override
  Future<String?> fetchSvg(String userId) async => svg;
}

Widget _avatar(String? svg, {String userId = 'u1', String name = 'Ama Mensah'}) {
  return ProviderScope(
    overrides: [avatarServiceProvider.overrideWithValue(_FakeAvatars(svg))],
    child: MaterialApp(
      home: UserAvatar(userId: userId, name: name, size: 48),
    ),
  );
}

void main() {
  group('UserAvatar.initials', () {
    test('uses up to two initials', () {
      expect(UserAvatar.initials('ama mensah kofi'), 'AM');
      expect(UserAvatar.initials('Ama'), 'A');
      expect(UserAvatar.initials('  Ama   Mensah '), 'AM');
    });

    test('copes with an empty name', () {
      expect(UserAvatar.initials(''), '?');
      expect(UserAvatar.initials('   '), '?');
    });
  });

  testWidgets('shows the DiceBear image once it loads', (tester) async {
    await tester.pumpWidget(_avatar('<svg viewBox="0 0 1 1"></svg>'));
    expect(find.text('AM'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('AM'), findsNothing);
  });

  testWidgets('keeps the initials when DiceBear is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(_avatar(null));
    await tester.pumpAndSettle();
    expect(find.text('AM'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('never asks for an avatar without a user id', (tester) async {
    await tester.pumpWidget(_avatar('<svg></svg>', userId: ''));
    await tester.pumpAndSettle();
    expect(find.text('AM'), findsOneWidget);
  });
}
