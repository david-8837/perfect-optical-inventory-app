import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/sync_status.dart';
import '../services/supabase_sync_service.dart';
import '../services/local_database_service.dart';
import 'sync_notification_toast.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = SupabaseSyncService();
    return AnimatedBuilder(
      animation: syncService,
      builder: (context, _) {
        final status = syncService.status;
        Color statusColor;
        IconData statusIcon;
        String statusLabel;

        switch (status) {
          case SyncStatus.synced:
            statusColor = const Color(0xFF10B981);
            statusIcon = Icons.check_circle_rounded;
            statusLabel = 'Synced';
            break;
          case SyncStatus.syncing:
            statusColor = const Color(0xFFFFC107);
            statusIcon = Icons.sync_rounded;
            statusLabel = 'Syncing...';
            break;
          case SyncStatus.offline:
            statusColor = const Color(0xFFEF4444);
            statusIcon = Icons.wifi_off_rounded;
            statusLabel = 'Offline';
            break;
          case SyncStatus.pendingChanges:
            statusColor = const Color(0xFFFF9800);
            statusIcon = Icons.cloud_upload_rounded;
            statusLabel = 'Pending Changes';
            break;
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8);
        final textColor = isDark ? Colors.white : const Color(0xFF121212);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _showSyncInfoSheet(context, syncService);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: statusColor.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == SyncStatus.syncing)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  )
                else
                  Icon(statusIcon, size: 13, color: statusColor),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSyncInfoSheet(BuildContext context, SupabaseSyncService syncService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.50),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
          final txt = isDark ? Colors.white : const Color(0xFF121212);
          final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
          final cardBg = isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8);

          final localDb = LocalDatabaseService();
          final allFrames = localDb.frames;
          final pendingCount = localDb.getPendingSyncItems().length;

          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Drag Handle
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header Info Tile
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.cloud_sync_rounded,
                            color: Color(0xFF10B981), size: 26),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supabase Cloud Control',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: txt,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Real-Time PostgreSQL Database & Storage Engine',
                            style: TextStyle(fontSize: 12, color: subTxt),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close_rounded, color: subTxt),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.withOpacity(0.15), height: 1),
                const SizedBox(height: 16),

                // Live Sync Telemetry Metric Cards Row
                Row(
                  children: [
                    // Card 1: Cloud Status
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.wifi_rounded,
                                    size: 14, color: Color(0xFF10B981)),
                                SizedBox(width: 5),
                                Text(
                                  'STATUS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              syncService.isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: txt,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Card 2: Synced Items
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 14, color: Color(0xFF3B82F6)),
                                SizedBox(width: 5),
                                Text(
                                  'TOTAL ITEMS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${allFrames.length} Frames',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: txt,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Card 3: Pending Queue
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.pending_actions_rounded,
                                    size: 14,
                                    color: pendingCount > 0
                                        ? const Color(0xFFFF9800)
                                        : const Color(0xFF10B981)),
                                const SizedBox(width: 5),
                                Text(
                                  'QUEUE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: pendingCount > 0
                                        ? const Color(0xFFFF9800)
                                        : const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              pendingCount > 0 ? '$pendingCount Pending' : 'All Synced',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: txt,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // USEFUL THING 1: Export Full Database (JSON Backup)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      final List<Map<String, dynamic>> jsonList =
                          allFrames.map((f) => f.toMap()).toList();
                      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);

                      Clipboard.setData(ClipboardData(text: jsonString));

                      SyncToastController().showNotification(
                        title: 'Database Exported',
                        message: 'Copied full JSON backup of ${allFrames.length} frames to clipboard!',
                        eventType: 'sync',
                        icon: Icons.content_copy_rounded,
                        accentColor: const Color(0xFF3B82F6),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text(
                      'Export Full Database Backup (JSON)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: txt,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.15)
                            : const Color(0xFFE0E0E0),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // USEFUL THING 2: Force Cloud Sync Now
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      syncService.syncWithCloud();
                      Navigator.pop(ctx);
                      SyncToastController().showNotification(
                        title: 'Sync Triggered',
                        message: 'Syncing store database with Supabase Cloud...',
                        eventType: 'sync',
                        icon: Icons.cloud_sync_rounded,
                        accentColor: const Color(0xFF10B981),
                      );
                    },
                    icon: const Icon(Icons.sync_rounded, size: 20),
                    label: const Text(
                      'Force Cloud Sync Now',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : const Color(0xFF121212),
                      foregroundColor: isDark ? const Color(0xFF121212) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
