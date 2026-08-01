import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalImageCacheService {
  static final LocalImageCacheService _instance = LocalImageCacheService._internal();
  factory LocalImageCacheService() => _instance;
  LocalImageCacheService._internal();

  Directory? _storageDir;

  Future<Directory> _getPermanentStorageDirectory() async {
    if (_storageDir != null && await _storageDir!.exists()) {
      return _storageDir!;
    }
    final appDocs = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDocs.path}/perfect_optical_media/images');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _storageDir = dir;
    return dir;
  }

  String _generateFileName(String urlOrData) {
    if (urlOrData.contains('/storage/v1/object/public/eyewear-images/')) {
      final parts = urlOrData.split('/eyewear-images/');
      if (parts.length > 1 && parts.last.isNotEmpty) {
        return parts.last.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      }
    }
    final int hash = urlOrData.hashCode.abs();
    return 'frame_data_img_$hash.jpg';
  }

  Future<File?> getLocalDeviceStorageFile(String imagePathOrUrl) async {
    if (kIsWeb || imagePathOrUrl.isEmpty) return null;

    if (imagePathOrUrl.startsWith('/') || imagePathOrUrl.contains(':\\') || imagePathOrUrl.startsWith('file://')) {
      final String cleanPath = imagePathOrUrl.startsWith('file://')
          ? Uri.parse(imagePathOrUrl).toFilePath()
          : imagePathOrUrl;
      final file = File(cleanPath);
      if (file.existsSync() && file.lengthSync() > 0) return file;
    }

    try {
      final savedPath = await saveImageToDeviceStorage(imagePathOrUrl: imagePathOrUrl);
      if (savedPath.isNotEmpty && (savedPath.startsWith('/') || savedPath.contains(':\\'))) {
        final file = File(savedPath);
        if (file.existsSync() && file.lengthSync() > 0) {
          return file;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> getCachedLocalPath(String imagePathOrUrl) async {
    if (kIsWeb || imagePathOrUrl.isEmpty) return null;

    if (imagePathOrUrl.startsWith('/') || imagePathOrUrl.contains(':\\') || imagePathOrUrl.startsWith('file://')) {
      final String cleanPath = imagePathOrUrl.startsWith('file://')
          ? Uri.parse(imagePathOrUrl).toFilePath()
          : imagePathOrUrl;
      if (File(cleanPath).existsSync()) {
        return cleanPath;
      }
    }

    try {
      final dir = await _getPermanentStorageDirectory();
      final fileName = _generateFileName(imagePathOrUrl);
      final file = File('${dir.path}/$fileName');
      if (await file.exists() && (await file.length()) > 0) {
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  Future<String> saveImageToDeviceStorage({required String imagePathOrUrl, Uint8List? rawBytes}) async {
    if (kIsWeb || imagePathOrUrl.isEmpty) return imagePathOrUrl;

    try {
      final dir = await _getPermanentStorageDirectory();
      final fileName = _generateFileName(imagePathOrUrl);
      final file = File('${dir.path}/$fileName');

      if (await file.exists() && (await file.length()) > 0) {
        return file.path;
      }

      if (rawBytes != null && rawBytes.isNotEmpty) {
        await file.writeAsBytes(rawBytes);
        return file.path;
      }

      if (imagePathOrUrl.startsWith('data:image')) {
        final base64Str = imagePathOrUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        await file.writeAsBytes(bytes);
        return file.path;
      }

      if (imagePathOrUrl.startsWith('http://') || imagePathOrUrl.startsWith('https://')) {
        final request = await HttpClient().getUrl(Uri.parse(imagePathOrUrl));
        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = await consolidateHttpClientResponseBytes(response);
          if (bytes.isNotEmpty) {
            await file.writeAsBytes(bytes);
            return file.path;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Permanent device image storage error: $e');
    }
    return imagePathOrUrl;
  }

  Future<String> cacheImageData({required String imagePathOrUrl, Uint8List? rawBytes}) async {
    return await saveImageToDeviceStorage(imagePathOrUrl: imagePathOrUrl, rawBytes: rawBytes);
  }

  Future<void> preCacheImages(List<String> imageUrls) async {
    if (kIsWeb) return;
    for (final url in imageUrls) {
      if (url.isNotEmpty && (url.startsWith('http') || url.startsWith('data:image'))) {
        await saveImageToDeviceStorage(imagePathOrUrl: url);
      }
    }
  }
}
