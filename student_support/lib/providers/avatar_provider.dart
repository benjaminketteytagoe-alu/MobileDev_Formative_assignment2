import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/avatar_service.dart';

final avatarServiceProvider = Provider<AvatarService>((ref) => AvatarService());

/// SVG for a user's avatar, or null while unavailable. A success is kept for
/// the session; a failure is dropped with the widget, so it retries next time.
final avatarSvgProvider = FutureProvider.autoDispose.family<String?, String>((
  ref,
  userId,
) async {
  final svg = await ref.watch(avatarServiceProvider).fetchSvg(userId);
  if (svg != null) ref.keepAlive();
  return svg;
});
