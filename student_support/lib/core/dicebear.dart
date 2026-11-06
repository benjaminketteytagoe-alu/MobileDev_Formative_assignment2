import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Builds DiceBear (https://www.dicebear.com) requests.
///
/// Requests go to a third party, so the seed is a salted hash of the user id:
/// names, emails and Firebase ids never leave the app, and the same user still
/// gets the same avatar on every device.
class DiceBear {
  DiceBear._();

  /// The major version is pinned so avatars do not change under the app.
  /// Point this at a self-hosted instance with
  /// `--dart-define=DICEBEAR_BASE_URL=https://...`. The public API is free for
  /// non-commercial use only, so a commercial release must self-host.
  static const String baseUrl = String.fromEnvironment(
    'DICEBEAR_BASE_URL',
    defaultValue: 'https://api.dicebear.com/10.x',
  );

  /// CC0 licensed and supports DiceBear's animation option.
  static const String avatarStyle = 'thumbs';

  /// Brand tints the avatar background is chosen from.
  static const List<String> avatarBackgrounds = [
    '0b2a5b',
    '14407f',
    '1f5fbf',
    'f5b014',
  ];

  static String seedFor(String userId) {
    // The salt keeps its original value on purpose: it is never shown, and
    // changing it would give every user a different avatar.
    final digest = sha256.convert(utf8.encode('campusfix-avatar:$userId'));
    return digest.toString().substring(0, 24);
  }

  static Uri avatarUrl(String userId) {
    return Uri.parse('$baseUrl/$avatarStyle/svg').replace(
      queryParameters: {
        'seed': seedFor(userId),
        // Repeated, not comma-joined: Uri encodes a comma as %2C, which the
        // API rejects with HTTP 400.
        'backgroundColor': avatarBackgrounds,
        // Ignored by flutter_svg, played by AnimatedSvgView.
        'animationVariant': 'slow',
      },
    );
  }

  // Bundled artwork. See tool/fetch_dicebear_assets.py.
  static const String mascotEmpty = 'assets/images/dicebear/mascot_empty.svg';
  static const String mascotSearch = 'assets/images/dicebear/mascot_search.svg';
  static const String mascotError = 'assets/images/dicebear/mascot_error.svg';

  static String categoryIcon(String category) =>
      'assets/images/dicebear/icons/${category.toLowerCase()}.svg';
}
