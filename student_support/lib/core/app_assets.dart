import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Optional photos you can drop into assets/images/ without touching code.
/// Each lookup returns the asset path if a file with that name exists (as
/// .jpg, .jpeg, .png or .webp), or null so the caller can use its built-in
/// fallback. AVIF and HEIC are not listed because Flutter cannot decode them
/// on every device: convert those to JPEG first.
///
/// | Photo                 | File                                         |
/// |-----------------------|----------------------------------------------|
/// | Home hero (campus)    | assets/images/campus_hero.jpg                |
/// | Splash background     | assets/images/splash_image.jpg               |
/// | Category, e.g. water  | assets/images/categories/water.jpg           |
class AppAssets {
  AppAssets._();

  static const List<String> _extensions = ['jpg', 'jpeg', 'png', 'webp'];

  static Set<String> _available = const {};

  /// Reads the bundled asset list once at start-up, so later lookups are
  /// synchronous and screens never flash a fallback before the photo.
  static Future<void> load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _available = manifest.listAssets().toSet();
    } catch (e) {
      debugPrint('Could not read the asset manifest: $e');
    }
  }

  @visibleForTesting
  static set debugAvailable(Set<String> assets) => _available = assets;

  static String? _photo(String basePath) {
    for (final ext in _extensions) {
      final path = '$basePath.$ext';
      if (_available.contains(path)) return path;
    }
    return null;
  }

  static String? get campusHero => _photo('assets/images/campus_hero');

  static String? get splashImage => _photo('assets/images/splash_image');

  static String? categoryPhoto(String category) =>
      _photo('assets/images/categories/${category.toLowerCase()}');
}
