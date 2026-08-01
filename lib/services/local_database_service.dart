import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/frame_item.dart';
import 'local_image_cache_service.dart';

class LocalDatabaseService extends ChangeNotifier {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static const String _prefKeyFrames = 'perfect_optical_local_frames_v3';
  List<FrameItem> _localFrames = [];
  bool _isInitialized = false;

  List<FrameItem> get frames => List.unmodifiable(_localFrames.where((f) => !f.isDeleted));
  List<FrameItem> get allLocalFrames => List.unmodifiable(_localFrames);
  bool get isInitialized => _isInitialized;

  Future<void> initDatabase() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_prefKeyFrames);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> listMap = jsonDecode(jsonStr);
        _localFrames = listMap.map((m) => FrameItem.fromMap(Map<String, dynamic>.from(m))).toList();
      } else {
        // Start with empty inventory — user adds their own products
        _localFrames = [];
      }
    } catch (_) {
      _localFrames = [];
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _persistToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMap = _localFrames.map((f) => f.toMap()).toList();
      await prefs.setString(_prefKeyFrames, jsonEncode(listMap));
    } catch (_) {}
  }

  FrameItem? getFrameById(String id) {
    try {
      return _localFrames.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  void saveFrame(FrameItem frame, {bool markPending = false}) {
    final frameToSave = markPending ? frame.copyWith(isPendingSync: true, updatedAt: DateTime.now()) : frame;
    final index = _localFrames.indexWhere((f) => f.id == frame.id);
    if (index >= 0) {
      _localFrames[index] = frameToSave;
    } else {
      _localFrames.insert(0, frameToSave);
    }
    _persistToDisk();
    notifyListeners();
  }

  void deleteFrame(String id, {bool markPending = false}) {
    if (markPending) {
      final index = _localFrames.indexWhere((f) => f.id == id);
      if (index >= 0) {
        _localFrames[index] = _localFrames[index].copyWith(
          isDeleted: true,
          isPendingSync: true,
          updatedAt: DateTime.now(),
        );
      }
    } else {
      _localFrames.removeWhere((f) => f.id == id);
    }
    _persistToDisk();
    notifyListeners();
  }

  void updateStock(String id, int delta, {bool markPending = false}) {
    final index = _localFrames.indexWhere((f) => f.id == id);
    if (index >= 0) {
      final current = _localFrames[index];
      final newCount = (current.stockCount + delta).clamp(0, 999);
      _localFrames[index] = current.copyWith(
        stockCount: newCount,
        isPendingSync: markPending ? true : current.isPendingSync,
        updatedAt: DateTime.now(),
      );
      _persistToDisk();
      notifyListeners();
    }
  }

  void updatePrice(String id, double newPrice, {bool markPending = false}) {
    final index = _localFrames.indexWhere((f) => f.id == id);
    if (index >= 0) {
      final current = _localFrames[index];
      _localFrames[index] = current.copyWith(
        price: newPrice,
        isPendingSync: markPending ? true : current.isPendingSync,
        updatedAt: DateTime.now(),
      );
      _persistToDisk();
      notifyListeners();
    }
  }

  void updateCategory(String id, String newCategory, {bool markPending = false}) {
    final index = _localFrames.indexWhere((f) => f.id == id);
    if (index >= 0) {
      final current = _localFrames[index];
      _localFrames[index] = current.copyWith(
        category: newCategory,
        isPendingSync: markPending ? true : current.isPendingSync,
        updatedAt: DateTime.now(),
      );
      _persistToDisk();
      notifyListeners();
    }
  }

  void updateImagePath(String id, String newImagePath, {bool markPending = false}) {
    final index = _localFrames.indexWhere((f) => f.id == id);
    if (index >= 0) {
      final current = _localFrames[index];
      _localFrames[index] = current.copyWith(
        imagePath: newImagePath,
        isPendingSync: markPending ? true : current.isPendingSync,
        updatedAt: DateTime.now(),
      );
      _persistToDisk();
      notifyListeners();
    }
  }

  Future<void> reconcileFromCloud(List<FrameItem> remoteFrames) async {
    final validRemote = remoteFrames.where((f) => !f.isDeleted).toList();
    final Map<String, FrameItem> remoteMap = {for (final r in validRemote) r.id: r};
    final List<FrameItem> updatedList = [];

    // 1. Preserve local pending unsynced items
    for (final local in _localFrames) {
      if (local.isPendingSync && !local.isDeleted) {
        if (!remoteMap.containsKey(local.id)) {
          updatedList.add(local);
        }
      }
    }

    // 2. Reconcile with live cloud items
    for (var remote in validRemote) {
      final local = _localFrames.firstWhere(
        (l) => l.id == remote.id,
        orElse: () => remote,
      );

      if (local.isPendingSync) {
        updatedList.add(local);
        continue;
      }

      final List<String> localPaths = [];
      for (final p in remote.imagePaths) {
        if (p.isNotEmpty) {
          final savedLocalPath =
              await LocalImageCacheService().saveImageToDeviceStorage(imagePathOrUrl: p);
          localPaths.add(savedLocalPath);
        }
      }
      final String mainLocalPath = remote.imagePath.isNotEmpty
          ? await LocalImageCacheService()
              .saveImageToDeviceStorage(imagePathOrUrl: remote.imagePath)
          : (localPaths.isNotEmpty ? localPaths.first : '');

      remote = remote.copyWith(
        imagePath: mainLocalPath,
        imagePaths: localPaths.isNotEmpty
            ? localPaths
            : (mainLocalPath.isNotEmpty ? [mainLocalPath] : []),
        isPendingSync: false,
      );
      updatedList.add(remote);
    }

    _localFrames = updatedList;
    _localFrames.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _persistToDisk();
    notifyListeners();
  }

  List<FrameItem> getPendingSyncItems() {
    return _localFrames.where((f) => f.isPendingSync).toList();
  }

  void markAllSynced() {
    for (int i = 0; i < _localFrames.length; i++) {
      if (_localFrames[i].isPendingSync) {
        _localFrames[i] = _localFrames[i].copyWith(isPendingSync: false);
      }
    }
    _localFrames.removeWhere((f) => f.isDeleted);
    _persistToDisk();
    notifyListeners();
  }
}

