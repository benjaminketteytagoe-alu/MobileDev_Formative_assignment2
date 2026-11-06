import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads [file] to [path] and returns its download URL.
  /// The content type is set explicitly because the Storage rules only
  /// accept image uploads.
  Future<String> uploadImage(File file, String path) async {
    final ref = _storage.ref().child(path);
    final snapshot = await ref.putFile(
      file,
      SettableMetadata(contentType: contentTypeFor(path)),
    );
    return snapshot.ref.getDownloadURL();
  }

  Future<void> deleteImage(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // Best-effort cleanup. A leftover file is harmless.
    }
  }

  static String contentTypeFor(String path) {
    final ext = extensionOf(path);
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  static String extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return 'jpg';
    final ext = path.substring(dot + 1).toLowerCase();
    return ext == 'jpeg' ? 'jpg' : ext;
  }
}
