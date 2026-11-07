import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Photo row for a report: an "Add photo" tile that offers the camera or the
/// gallery, followed by removable thumbnails.
class PhotoAttachments extends StatefulWidget {
  /// Local file paths of the attached photos.
  final List<String> paths;
  final ValueChanged<List<String>> onChanged;
  final int maxCount;

  const PhotoAttachments({
    super.key,
    required this.paths,
    required this.onChanged,
    required this.maxCount,
  });

  @override
  State<PhotoAttachments> createState() => _PhotoAttachmentsState();
}

class _PhotoAttachmentsState extends State<PhotoAttachments> {
  static const double _tileSize = 88;

  // Large enough to read a label or meter, small enough to stay well under
  // the 5 MB Storage limit.
  static const double _maxDimension = 1280;
  static const int _quality = 80;

  final ImagePicker _picker = ImagePicker();

  int get _remaining => widget.maxCount - widget.paths.length;

  @override
  void initState() {
    super.initState();
    _recoverLostPhotos();
  }

  /// Android may kill the app while the camera is open. The photo is not
  /// lost: image_picker hands it back on the next launch.
  Future<void> _recoverLostPhotos() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final response = await _picker.retrieveLostData();
      final files = response.files;
      if (response.isEmpty || files == null || !mounted) return;
      _add(files.map((f) => f.path).toList());
    } catch (_) {
      // Nothing to recover.
    }
  }

  void _add(List<String> picked) {
    if (picked.isEmpty) return;
    final room = _remaining;
    widget.onChanged([...widget.paths, ...picked.take(room)]);
    if (picked.length > room) {
      _showMessage(
        'Only the first $room photos were added. '
        'The limit is ${widget.maxCount} per report.',
      );
    }
  }

  Future<void> _chooseSource() async {
    if (_remaining <= 0) {
      _showMessage('You can attach up to ${widget.maxCount} photos.');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              subtitle: const Text('Use the camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              subtitle: Text(
                _remaining == 1
                    ? 'Pick 1 more photo'
                    : 'Pick up to $_remaining photos at once',
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    HapticFeedback.selectionClick();
    source == ImageSource.camera
        ? await _takePhoto()
        : await _pickFromGallery();
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _quality,
        requestFullMetadata: false,
      );
      if (photo != null && mounted) _add([photo.path]);
    } on PlatformException catch (e) {
      _showMessage(
        e.code == 'camera_access_denied'
            ? 'Camera access is off. Turn it on for CampusSupport in Settings.'
            : 'Could not open the camera.',
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      // Multi-select needs a limit of at least 2, so the last free slot uses
      // the single-photo picker.
      final List<XFile> picked;
      if (_remaining == 1) {
        final photo = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: _maxDimension,
          maxHeight: _maxDimension,
          imageQuality: _quality,
          requestFullMetadata: false,
        );
        picked = [?photo];
      } else {
        picked = await _picker.pickMultiImage(
          maxWidth: _maxDimension,
          maxHeight: _maxDimension,
          imageQuality: _quality,
          limit: _remaining,
          // Skips location and other metadata, so no extra permission prompt
          // and no GPS data leaves the phone.
          requestFullMetadata: false,
        );
      }
      if (mounted) _add(picked.map((f) => f.path).toList());
    } on PlatformException catch (e) {
      _showMessage(
        e.code == 'photo_access_denied'
            ? 'Photo access is off. Turn it on for CampusSupport in Settings.'
            : 'Could not open the photo library.',
      );
    }
  }

  void _remove(int index) {
    HapticFeedback.selectionClick();
    widget.onChanged([...widget.paths]..removeAt(index));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canAdd = _remaining > 0;
    final radius = BorderRadius.circular(AppRadius.sm);

    return SizedBox(
      height: _tileSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.paths.length + (canAdd ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (canAdd && index == 0) {
            final accent = isDark ? AppColors.primaryLight : AppColors.primary;
            return Semantics(
              button: true,
              label: 'Add photo',
              excludeSemantics: true,
              child: Material(
                color: accent.withValues(alpha: 0.08),
                borderRadius: radius,
                child: InkWell(
                  onTap: _chooseSource,
                  borderRadius: radius,
                  child: Container(
                    width: _tileSize,
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: accent.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: accent),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Add photo',
                          style: context.text.caption.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          final photoIndex = canAdd ? index - 1 : index;
          return _Thumbnail(
            path: widget.paths[photoIndex],
            size: _tileSize,
            label: 'Photo ${photoIndex + 1}',
            onRemove: () => _remove(photoIndex),
          );
        },
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String path;
  final double size;
  final String label;
  final VoidCallback onRemove;

  const _Thumbnail({
    required this.path,
    required this.size,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Image.file(
            File(path),
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: (size * 3).round(),
            semanticLabel: label,
            errorBuilder: (_, _, _) => Container(
              width: size,
              height: size,
              color: context.palette.surfaceVariant,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: Material(
            color: Colors.black.withValues(alpha: 0.6),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: Tooltip(
                message: 'Remove $label',
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
