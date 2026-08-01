import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class AppImagePicker {
  static final ImagePicker _picker = ImagePicker();

  /// Opens native photo gallery / file picker on Android, iOS, or Web.
  /// Returns base64 data URI `data:image/jpeg;base64,...` or null if cancelled.
  static Future<String?> pickImageAsDataUri() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (file == null) return null;

      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;

      final String base64Str = base64Encode(bytes);
      final String mimeType = file.mimeType ?? 'image/jpeg';
      return 'data:$mimeType;base64,$base64Str';
    } catch (e) {
      if (kDebugMode) print('AppImagePicker error: $e');
      return null;
    }
  }
}
