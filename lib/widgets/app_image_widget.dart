import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'custom_glasses_painter.dart';
import '../services/local_image_cache_service.dart';

class AppImageWidget extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double iconSize;

  const AppImageWidget({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.iconSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return _buildFallback();
    }

    if (imagePath.startsWith('data:image')) {
      try {
        final base64Str = imagePath.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      } catch (_) {
        return _buildFallback();
      }
    }

    if (!kIsWeb && (imagePath.startsWith('/') || imagePath.contains(':\\') || imagePath.startsWith('file://'))) {
      try {
        final String cleanPath = imagePath.startsWith('file://')
            ? Uri.parse(imagePath).toFilePath()
            : imagePath;
        final file = File(cleanPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildFallback(),
          );
        }
      } catch (_) {}
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return FutureBuilder<File?>(
        future: LocalImageCacheService().getLocalDeviceStorageFile(imagePath),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.existsSync()) {
            return Image.file(
              snapshot.data!,
              fit: fit,
              errorBuilder: (_, __, ___) => _buildFallback(),
            );
          }
          return Container(
            color: const Color(0xFFF5F6F8),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF121212),
                ),
              ),
            ),
          );
        },
      );
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      color: const Color(0xFFF5F6F8),
      child: Center(
        child: CustomGlassesIcon(
          color: const Color(0xFF8E8E93),
          size: iconSize,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
