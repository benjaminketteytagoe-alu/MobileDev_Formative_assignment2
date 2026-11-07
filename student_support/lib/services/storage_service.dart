import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart'
    show FileOptions, StorageFileApi, Supabase;

import '../core/supabase_config.dart';
import '../utils/error_messages.dart';

class StorageService {
  static const String bucket = 'incident-photos';

  StorageFileApi get _files {
    if (!isSupabaseConfigured) {
      throw const AppException(
        'Photo storage is not set up in this build. '
        'Run the app with --dart-define-from-file=supabase.env.json.',
      );
    }
    return Supabase.instance.client.storage.from(bucket);
  }

  /// Uploads [file] to [path] and returns its public URL.
  /// The content type is set explicitly because the bucket only accepts images.
  Future<String> uploadImage(File file, String path) async {
    final files = _files;
    await files.upload(
      path,
      file,
      fileOptions: FileOptions(contentType: contentTypeFor(path)),
    );
    return files.getPublicUrl(path);
  }

  Future<void> deleteImage(String url) async {
    final path = pathFromUrl(url);
    if (path == null) return;
    try {
      await _files.remove([path]);
    } catch (_) {
      // Best-effort cleanup. A leftover file is harmless.
    }
  }

  /// The path inside the bucket, or null for a URL from anywhere else.
  static String? pathFromUrl(String url) {
    const marker = '/storage/v1/object/public/$bucket/';
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.path.contains(marker)) return null;
    final path = uri.path.substring(uri.path.indexOf(marker) + marker.length);
    return path.isEmpty ? null : Uri.decodeComponent(path);
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
