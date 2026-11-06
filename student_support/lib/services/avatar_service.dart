import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../core/dicebear.dart';

/// Fetches DiceBear avatars and keeps them on disk, so an avatar seen once
/// still appears offline. Avatars are deterministic, so a long cache is safe.
class AvatarService {
  AvatarService({BaseCacheManager? cache}) : _cache = cache ?? _sharedCache;

  static final CacheManager _sharedCache = CacheManager(
    Config(
      'dicebearAvatars',
      stalePeriod: const Duration(days: 90),
      maxNrOfCacheObjects: 500,
    ),
  );

  final BaseCacheManager _cache;

  static final RegExp _metadata = RegExp(r'<metadata[\s\S]*?</metadata>');

  /// The avatar's SVG source, or null when it cannot be loaded. Callers show
  /// the initials instead, so a DiceBear outage or rate limit (HTTP 429) is
  /// invisible to the user.
  Future<String?> fetchSvg(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final file = await _cache.getSingleFile(
        DiceBear.avatarUrl(userId).toString(),
      );
      final svg = await file.readAsString();
      if (!svg.contains('<svg')) return null;
      // Licence metadata is large and flutter_svg logs a warning for it.
      return svg.replaceAll(_metadata, '');
    } catch (e) {
      debugPrint('Avatar unavailable: $e');
      return null;
    }
  }
}
