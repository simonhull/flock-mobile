import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// A circular avatar picker that allows selecting and cropping an image.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    this.imageBytes,
    this.initials,
    this.size = 96,
    this.onImageSelected,
    this.enabled = true,
  });

  /// Currently selected image bytes.
  final Uint8List? imageBytes;

  /// Initials to show when no image is selected.
  final String? initials;

  /// Size of the avatar.
  final double size;

  /// Callback when an image is selected and cropped.
  final void Function(Uint8List bytes, String mimeType)? onImageSelected;

  /// Whether the picker is enabled.
  final bool enabled;

  Future<void> _pickAndCropImage(BuildContext context) async {
    final picker = ImagePicker();

    // Show bottom sheet to choose source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.images),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    // Pick image
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );

    if (pickedFile == null) return;

    // Crop image
    if (!context.mounted) return;
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: Theme.of(context).colorScheme.primary,
          toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );

    if (croppedFile == null) return;

    // Read bytes and notify
    final bytes = await croppedFile.readAsBytes();
    onImageSelected?.call(bytes, 'image/jpeg');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: enabled ? () => _pickAndCropImage(context) : null,
      child: Stack(
        children: [
          // Avatar circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary,
              image: imageBytes != null
                  ? DecorationImage(
                      image: MemoryImage(imageBytes!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageBytes == null
                ? Center(
                    child: Text(
                      initials ?? '?',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: size * 0.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
          ),

          // Camera overlay
          if (enabled)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.camera,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: size * 0.25,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
