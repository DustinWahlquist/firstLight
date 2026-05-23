import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class ScreenshotService {
  ScreenshotService._();
  static final instance = ScreenshotService._();

  final _picker = ImagePicker();

  /// Opens the photo library so the user can pick a Merlin screenshot.
  /// Returns null if the user cancels.
  Future<Uint8List?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    return file?.readAsBytes();
  }

  /// Opens the camera. Returns null if the user cancels.
  Future<Uint8List?> pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    return file?.readAsBytes();
  }
}
