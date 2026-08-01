import 'package:flutter/material.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final Map<String, ImageProvider> _memoryCache = {};

  ImageProvider getImage(String url) {
    if (url.isEmpty) {
      return const AssetImage('assets/placeholder.png');
    }
    if (_memoryCache.containsKey(url)) {
      return _memoryCache[url]!;
    }

    ImageProvider provider;
    if (url.startsWith('http')) {
      provider = NetworkImage(url);
    } else {
      provider = NetworkImage(url);
    }

    _memoryCache[url] = provider;
    return provider;
  }
}
