import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/frame_item.dart';
import '../models/sync_status.dart';
import '../widgets/sync_notification_toast.dart';
import 'local_database_service.dart';
import 'local_image_cache_service.dart';

class SupabaseSyncService extends ChangeNotifier {
  static final SupabaseSyncService _instance = SupabaseSyncService._internal();
  factory SupabaseSyncService() => _instance;
  SupabaseSyncService._internal();

  static const String supabaseUrl = 'https://jrrwucqoeqdpjqpyojzw.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impycnd1Y3FvZXFkcGpxcHlvanp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUzODY3NDMsImV4cCI6MjEwMDk2Mjc0M30.uFOrjjdTC0KYnH5F1A6_de4U3FZZb6OVzALkmcG7pKU';

  SyncStatus _status = SyncStatus.synced;
  bool _isOnline = true;
  bool _isInitializing = false;
  bool _isSupabaseConnected = false;
  RealtimeChannel? _realtimeChannel;
  Timer? _bgSyncTimer;

  SyncStatus get status => _status;
  bool get isOnline => _isOnline;
  bool get isConnected => _isSupabaseConnected;

  final LocalDatabaseService _localDb = LocalDatabaseService();

  Future<void> initSyncEngine() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      Supabase.instance.client;
    } catch (_) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          publishableKey: supabaseAnonKey,
        );
      } catch (_) {}
    }

    _subscribeToRealtimeEvents();

    // Perform immediate initial cloud fetch & reconciliation on startup
    await syncWithCloud();

    _bgSyncTimer?.cancel();
    _bgSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isOnline) {
        syncWithCloud();
      }
    });

    _isInitializing = false;
  }

  void _subscribeToRealtimeEvents() {
    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client.channel('public:products');

      // 1. Listen for Broadcast Events for ultra-fast cross-device synchronization
      _realtimeChannel?.onBroadcast(
        event: 'inventory_action',
        callback: (payload) {
          _handleRealtimePayload(payload);
        },
      );

      // 2. Listen for Postgres DB Changes (INSERT, UPDATE, DELETE)
      _realtimeChannel?.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'products',
        callback: (payload) {
          _handlePostgresChange(payload);
        },
      );

      _realtimeChannel?.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _isSupabaseConnected = true;
          notifyListeners();
        } else {
          _isSupabaseConnected = false;
          notifyListeners();
        }
      });
    } catch (e) {
      if (kDebugMode) print('Realtime subscription error: $e');
    }
  }

  void _handleRealtimePayload(Map<String, dynamic> payload) {
    try {
      final String action = payload['action'] ?? 'update';
      final Map<String, dynamic>? frameData = payload['frame'] != null
          ? Map<String, dynamic>.from(payload['frame'])
          : null;
      final String? frameId = payload['id']?.toString() ?? frameData?['id']?.toString();

      if (frameData == null && frameId == null) return;

      final existing = frameId != null ? _localDb.getFrameById(frameId) : null;
      final frameName = frameData?['name'] ?? frameData?['title'] ?? existing?.name ?? 'Optical Frame';

      switch (action) {
        case 'add':
          if (frameData != null) {
            final newFrame = FrameItem.fromMap(frameData);
            _localDb.saveFrame(newFrame, markPending: false);
            SyncToastController().showNotification(
              title: 'New frame synced',
              message: '$frameName added to catalog',
              eventType: 'add',
              icon: Icons.add_circle_outline_rounded,
            );
          }
          break;

        case 'stock':
          final int? newStock = payload['stockCount'] ?? frameData?['stockCount'] ?? frameData?['stock_count'];
          final int? delta = payload['delta'];
          if (frameId != null) {
            if (newStock != null) {
              final curr = _localDb.getFrameById(frameId);
              if (curr != null) {
                _localDb.saveFrame(curr.copyWith(stockCount: newStock, isPendingSync: false));
              }
            } else if (delta != null) {
              _localDb.updateStock(frameId, delta, markPending: false);
            }
            SyncToastController().showNotification(
              title: 'Stock updated',
              message: '$frameName stock updated${newStock != null ? " ($newStock units)" : ""}',
              eventType: 'stock',
              icon: Icons.inventory_2_rounded,
            );
          }
          break;

        case 'price':
          final double? newPrice = (payload['price'] as num?)?.toDouble() ?? (frameData?['price'] as num?)?.toDouble();
          if (frameId != null && newPrice != null) {
            _localDb.updatePrice(frameId, newPrice, markPending: false);
            SyncToastController().showNotification(
              title: 'Price updated',
              message: '$frameName price updated to ₹${newPrice.toStringAsFixed(0)}',
              eventType: 'price',
              icon: Icons.sell_rounded,
            );
          }
          break;

        case 'category':
          final String? newCat = payload['category'] ?? frameData?['category'];
          if (frameId != null && newCat != null) {
            _localDb.updateCategory(frameId, newCat, markPending: false);
            SyncToastController().showNotification(
              title: 'Category updated',
              message: '$frameName category set to $newCat',
              eventType: 'category',
              icon: Icons.category_rounded,
            );
          }
          break;

        case 'image':
          final String? newImg = payload['imagePath'] ?? frameData?['imagePath'] ?? frameData?['image'];
          if (frameId != null && newImg != null) {
            _localDb.updateImagePath(frameId, newImg, markPending: false);
            SyncToastController().showNotification(
              title: 'Image updated',
              message: 'New image updated for $frameName',
              eventType: 'image',
              icon: Icons.image_rounded,
            );
          }
          break;

        case 'delete':
          if (frameId != null) {
            _localDb.deleteFrame(frameId, markPending: false);
            SyncToastController().showNotification(
              title: 'Product deleted',
              message: '$frameName removed from inventory',
              eventType: 'delete',
              icon: Icons.delete_forever_rounded,
            );
          }
          break;

        case 'edit':
        default:
          if (frameData != null) {
            final editedFrame = FrameItem.fromMap(frameData);
            _localDb.saveFrame(editedFrame, markPending: false);
            SyncToastController().showNotification(
              title: 'Inventory updated',
              message: '$frameName updated across devices',
              eventType: 'edit',
              icon: Icons.edit_note_rounded,
            );
          }
          break;
      }
      _status = SyncStatus.synced;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Realtime payload error: $e');
    }
  }

  void _handlePostgresChange(PostgresChangePayload payload) {
    try {
      final eventType = payload.eventType;
      final record = payload.newRecord;
      final oldRecord = payload.oldRecord;

      if (eventType == PostgresChangeEvent.insert && record.isNotEmpty) {
        final frame = FrameItem.fromMap(record);
        _localDb.saveFrame(frame, markPending: false);
        SyncToastController().showNotification(
          title: 'New frame synced',
          message: '${frame.name} added in real-time',
          eventType: 'add',
        );
      } else if (eventType == PostgresChangeEvent.update && record.isNotEmpty) {
        final frame = FrameItem.fromMap(record);
        if (frame.isDeleted) {
          _localDb.deleteFrame(frame.id, markPending: false);
          SyncToastController().showNotification(
            title: 'Product deleted',
            message: '${frame.name} deleted',
            eventType: 'delete',
          );
        } else {
          _localDb.saveFrame(frame, markPending: false);
          SyncToastController().showNotification(
            title: 'Inventory updated',
            message: '${frame.name} synced from cloud',
            eventType: 'edit',
          );
        }
      } else if (eventType == PostgresChangeEvent.delete && oldRecord.isNotEmpty) {
        final String id = oldRecord['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          _localDb.deleteFrame(id, markPending: false);
          SyncToastController().showNotification(
            title: 'Product deleted',
            message: 'Item removed from database',
            eventType: 'delete',
          );
        }
      }
      _status = SyncStatus.synced;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> broadcastAction({
    required String action, // 'add', 'edit', 'delete', 'stock', 'price', 'category', 'image'
    required FrameItem frame,
    Map<String, dynamic>? extraData,
  }) async {
    // Cache image locally for 100% offline access
    if (frame.imagePath.isNotEmpty) {
      await LocalImageCacheService().cacheImageData(imagePathOrUrl: frame.imagePath);
    }

    // 1. Update local database first (Instant offline & UI responsiveness)
    switch (action) {
      case 'add':
      case 'edit':
        _localDb.saveFrame(frame, markPending: !_isOnline);
        break;
      case 'delete':
        _localDb.deleteFrame(frame.id, markPending: !_isOnline);
        break;
      case 'stock':
        if (extraData?['delta'] != null) {
          _localDb.updateStock(frame.id, extraData!['delta'] as int, markPending: !_isOnline);
        } else {
          _localDb.saveFrame(frame, markPending: !_isOnline);
        }
        break;
      case 'price':
        if (extraData?['price'] != null) {
          _localDb.updatePrice(frame.id, (extraData!['price'] as num).toDouble(), markPending: !_isOnline);
        }
        break;
      case 'category':
        if (extraData?['category'] != null) {
          _localDb.updateCategory(frame.id, extraData!['category'].toString(), markPending: !_isOnline);
        }
        break;
      case 'image':
        if (extraData?['imagePath'] != null) {
          _localDb.updateImagePath(frame.id, extraData!['imagePath'].toString(), markPending: !_isOnline);
        }
        break;
    }

    if (!_isOnline) {
      _status = SyncStatus.pendingChanges;
      notifyListeners();
      return;
    }

    // 2. Persist to Supabase Database (Critical Cloud Backup)
    try {
      final client = Supabase.instance.client;
      if (action == 'delete') {
        try {
          final allPaths = [frame.imagePath, ...frame.imagePaths]
              .where((p) => p.isNotEmpty)
              .toSet()
              .toList();
          await deleteImagesFromStorage(allPaths);
          await client.from('products').delete().eq('id', frame.id);
        } catch (_) {
          await client.from('products').upsert(frame.copyWith(isDeleted: true).toMap());
        }
      } else {
        FrameItem frameToUpload = frame;
        if (frameToUpload.imagePaths.isNotEmpty) {
          final List<String> uploadedPaths = [];
          for (final p in frameToUpload.imagePaths) {
            if (p.isNotEmpty && !p.startsWith('http')) {
              final cdnUrl = await uploadLocalPathToStorage(p);
              if (cdnUrl != null && cdnUrl.isNotEmpty) {
                await LocalImageCacheService().cacheImageData(imagePathOrUrl: cdnUrl);
                uploadedPaths.add(cdnUrl);
              } else {
                uploadedPaths.add(p);
              }
            } else {
              uploadedPaths.add(p);
            }
          }
          frameToUpload = frameToUpload.copyWith(
            imagePaths: uploadedPaths,
            imagePath: uploadedPaths.isNotEmpty ? uploadedPaths.first : frameToUpload.imagePath,
          );
          _localDb.saveFrame(frameToUpload, markPending: false);
        }
        await client.from('products').upsert(frameToUpload.toMap());
      }
      _status = SyncStatus.synced;

      // 3. Broadcast real-time message to all connected devices (Instant Push)
      if (_realtimeChannel != null) {
        try {
          final payload = {
            'action': action,
            'id': frame.id,
            'frame': frame.toMap(),
            if (extraData != null) ...extraData,
          };
          (_realtimeChannel as dynamic)?.sendBroadcast(
            event: 'inventory_action',
            payload: payload,
          );
        } catch (err) {
          if (kDebugMode) print('Realtime broadcast error: $err');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Supabase DB upsert error: $e');
      _status = SyncStatus.pendingChanges;
    }
    notifyListeners();
  }

  Future<String?> uploadImageToStorage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!_isOnline) return null;
    try {
      final client = Supabase.instance.client;
      final String cleanFileName = 'frame_${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
      await client.storage.from('eyewear-images').uploadBinary(
        cleanFileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
      final String publicUrl = client.storage.from('eyewear-images').getPublicUrl(cleanFileName);
      return publicUrl;
    } catch (e) {
      if (kDebugMode) print('Supabase Storage upload error: $e');
      return null;
    }
  }

  Future<String?> uploadDataUriToStorage(String dataUri) async {
    if (!_isOnline || !dataUri.contains('data:image')) return null;
    try {
      final base64Str = dataUri.split(',').last;
      final bytes = base64Decode(base64Str);
      return await uploadImageToStorage(
        bytes: bytes,
        fileName: 'cropped_frame.jpg',
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadLocalPathToStorage(String imagePath) async {
    if (!_isOnline || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    if (imagePath.startsWith('data:image')) {
      return await uploadDataUriToStorage(imagePath);
    }

    try {
      final String cleanPath = imagePath.startsWith('file://')
          ? Uri.parse(imagePath).toFilePath()
          : imagePath;
      final file = File(cleanPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return await uploadImageToStorage(
          bytes: bytes,
          fileName: 'offline_frame.jpg',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Upload local path error: $e');
    }
    return null;
  }

  Future<void> deleteImagesFromStorage(List<String> paths) async {
    if (!_isOnline || paths.isEmpty) return;
    try {
      final client = Supabase.instance.client;
      final List<String> fileNamesToDelete = [];

      for (final p in paths) {
        if (p.contains('eyewear-images/')) {
          final parts = p.split('eyewear-images/');
          if (parts.length > 1) {
            final fileName = parts.last.split('?').first;
            if (fileName.isNotEmpty) {
              fileNamesToDelete.add(fileName);
            }
          }
        }
      }

      if (fileNamesToDelete.isNotEmpty) {
        await client.storage.from('eyewear-images').remove(fileNamesToDelete.toSet().toList());
        if (kDebugMode) {
          print('Deleted ${fileNamesToDelete.length} images from Supabase Storage: $fileNamesToDelete');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error deleting images from Supabase storage: $e');
    }
  }

  Future<void> toggleOnlineMode(bool online) async {
    _isOnline = online;
    if (!_isOnline) {
      _status = SyncStatus.offline;
      notifyListeners();
      SyncToastController().showNotification(
        title: 'Offline Mode Active',
        message: 'Using local database. Changes will sync when online.',
        eventType: 'sync',
        icon: Icons.wifi_off_rounded,
        accentColor: const Color(0xFFEF4444),
      );
    } else {
      SyncToastController().showNotification(
        title: 'Network Restored',
        message: 'Synchronizing missed changes with Supabase cloud...',
        eventType: 'sync',
        icon: Icons.wifi_rounded,
        accentColor: const Color(0xFF10B981),
      );
      await syncWithCloud();
    }
  }

  Future<void> syncWithCloudProgress(void Function(String message, double progress) onProgress) async {
    if (!_isOnline) {
      _status = SyncStatus.offline;
      notifyListeners();
      onProgress('Offline mode: Using cached inventory', 1.0);
      return;
    }

    onProgress('Connecting to Supabase cloud...', 0.15);
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final pending = _localDb.getPendingSyncItems();
      if (pending.isNotEmpty) {
        onProgress('Backing up ${pending.length} pending local change${pending.length > 1 ? 's' : ''} to cloud...', 0.40);
        _status = SyncStatus.syncing;
        notifyListeners();

        final client = Supabase.instance.client;
        for (int i = 0; i < pending.length; i++) {
          var item = pending[i];
          final stepProgress = 0.40 + (0.25 * ((i + 1) / pending.length));
          onProgress('Backing up "${item.name}"...', stepProgress);

          if (item.isDeleted) {
            try {
              final allPaths = [item.imagePath, ...item.imagePaths]
                  .where((p) => p.isNotEmpty)
                  .toSet()
                  .toList();
              await deleteImagesFromStorage(allPaths);
              await client.from('products').delete().eq('id', item.id);
            } catch (_) {}
          } else {
            // Upload offline local image files or base64 dataUris to Supabase Storage if not uploaded yet
            if (item.imagePaths.isNotEmpty) {
              onProgress('Uploading offline photos for "${item.name}"...', stepProgress);
              final List<String> uploadedPaths = [];
              for (final p in item.imagePaths) {
                if (p.isNotEmpty && !p.startsWith('http')) {
                  final cdnUrl = await uploadLocalPathToStorage(p);
                  if (cdnUrl != null && cdnUrl.isNotEmpty) {
                    await LocalImageCacheService().cacheImageData(imagePathOrUrl: cdnUrl);
                    uploadedPaths.add(cdnUrl);
                  } else {
                    uploadedPaths.add(p);
                  }
                } else {
                  uploadedPaths.add(p);
                }
              }
              item = item.copyWith(
                imagePaths: uploadedPaths,
                imagePath: uploadedPaths.isNotEmpty ? uploadedPaths.first : item.imagePath,
              );
              _localDb.saveFrame(item, markPending: true);
            }
            await client.from('products').upsert(item.toMap());
          }
        }
        _localDb.markAllSynced();
      } else {
        onProgress('Local offline database is up to date', 0.50);
        await Future.delayed(const Duration(milliseconds: 150));
      }

      // Pull cloud items & reconcile
      onProgress('Downloading latest store inventory...', 0.70);
      final client = Supabase.instance.client;
      final List<dynamic> response = await client.from('products').select().order('created_at', ascending: false);
      final cloudFrames = response.map((e) => FrameItem.fromMap(Map<String, dynamic>.from(e))).toList();
      
      onProgress('Reconciling ${cloudFrames.length} store items...', 0.85);
      if (cloudFrames.isNotEmpty) {
        await _localDb.reconcileFromCloud(cloudFrames);
        onProgress('Caching frame photos locally for offline use...', 0.95);
        final List<String> allPhotosToCache = [];
        for (final f in cloudFrames) {
          allPhotosToCache.addAll(f.imagePaths.where((p) => p.isNotEmpty));
          if (f.imagePath.isNotEmpty) allPhotosToCache.add(f.imagePath);
        }
        await LocalImageCacheService().preCacheImages(allPhotosToCache.toSet().toList());
      }
      await Future.delayed(const Duration(milliseconds: 150));

      _status = SyncStatus.synced;
      notifyListeners();
      onProgress('Store data synchronized successfully!', 1.0);
    } catch (e) {
      if (kDebugMode) print('Cloud sync error: $e');
      _status = SyncStatus.offline;
      notifyListeners();
      onProgress('Cloud sync complete (using cached data)', 1.0);
    }
  }

  Future<void> syncWithCloud() async {
    await syncWithCloudProgress((_, __) {});
  }


  void triggerPending() {
    if (_isOnline) {
      _status = SyncStatus.pendingChanges;
      notifyListeners();
      syncWithCloud();
    } else {
      _status = SyncStatus.offline;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _bgSyncTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
