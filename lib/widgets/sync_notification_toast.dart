import 'dart:async';
import 'package:flutter/material.dart';

class SyncEventNotification {
  final String id;
  final String title;
  final String message;
  final String eventType; // 'add', 'edit', 'delete', 'stock', 'price', 'category', 'image', 'sync'
  final IconData icon;
  final Color accentColor;
  final DateTime timestamp;
  bool isUnread;

  SyncEventNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.eventType,
    required this.icon,
    required this.accentColor,
    DateTime? timestamp,
    this.isUnread = true,
  }) : timestamp = timestamp ?? DateTime.now();

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class SyncToastController {
  static final SyncToastController _instance = SyncToastController._internal();
  factory SyncToastController() => _instance;
  SyncToastController._internal();

  final _controller = StreamController<SyncEventNotification>.broadcast();
  Stream<SyncEventNotification> get eventStream => _controller.stream;

  final List<SyncEventNotification> _history = [];
  List<SyncEventNotification> get history => List.unmodifiable(_history);

  bool get hasUnread => _history.any((n) => n.isUnread);
  int get unreadCount => _history.where((n) => n.isUnread).length;

  void markAllRead() {
    for (var notif in _history) {
      notif.isUnread = false;
    }
  }

  void showNotification({
    required String title,
    required String message,
    required String eventType,
    IconData? icon,
    Color? accentColor,
  }) {
    IconData defaultIcon;
    Color defaultColor;

    switch (eventType) {
      case 'add':
        defaultIcon = Icons.add_circle_rounded;
        defaultColor = const Color(0xFF10B981); // Emerald Green
        break;
      case 'edit':
        defaultIcon = Icons.edit_note_rounded;
        defaultColor = const Color(0xFF3B82F6); // Blue
        break;
      case 'delete':
        defaultIcon = Icons.delete_sweep_rounded;
        defaultColor = const Color(0xFFEF4444); // Red
        break;
      case 'stock':
        defaultIcon = Icons.inventory_2_rounded;
        defaultColor = const Color(0xFF8B5CF6); // Purple
        break;
      case 'price':
        defaultIcon = Icons.sell_rounded;
        defaultColor = const Color(0xFFF59E0B); // Amber
        break;
      case 'category':
        defaultIcon = Icons.category_rounded;
        defaultColor = const Color(0xFF06B6D4); // Cyan
        break;
      case 'image':
        defaultIcon = Icons.image_rounded;
        defaultColor = const Color(0xFFEC4899); // Pink
        break;
      case 'sync':
      default:
        defaultIcon = Icons.cloud_sync_rounded;
        defaultColor = const Color(0xFF10B981);
        break;
    }

    final notif = SyncEventNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      message: message,
      eventType: eventType,
      icon: icon ?? defaultIcon,
      accentColor: accentColor ?? defaultColor,
    );

    _history.insert(0, notif);
    if (_history.length > 30) {
      _history.removeLast();
    }

    _controller.add(notif);
  }
}


class SyncNotificationOverlay extends StatefulWidget {
  final Widget child;
  const SyncNotificationOverlay({super.key, required this.child});

  @override
  State<SyncNotificationOverlay> createState() => _SyncNotificationOverlayState();
}

class _SyncNotificationOverlayState extends State<SyncNotificationOverlay> with SingleTickerProviderStateMixin {
  late StreamSubscription<SyncEventNotification> _subscription;
  SyncEventNotification? _currentNotification;
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _subscription = SyncToastController().eventStream.listen((event) {
      _displayToast(event);
    });
  }

  void _displayToast(SyncEventNotification event) {
    _dismissTimer?.cancel();
    setState(() {
      _currentNotification = event;
    });
    _animController.forward(from: 0.0);

    _dismissTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        _animController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentNotification = null;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        widget.child,
        if (_currentNotification != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                final notif = _currentNotification!;
                return Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: Opacity(
                    opacity: _fadeAnim.value.clamp(0.0, 1.0),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2028).withOpacity(0.95) : Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: notif.accentColor.withOpacity(0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: notif.accentColor.withOpacity(0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: notif.accentColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  notif.icon,
                                  color: notif.accentColor,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        notif.title,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white : const Color(0xFF121212),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: notif.accentColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'REALTIME',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: notif.accentColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    notif.message,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFFA0A0A5) : const Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                _animController.reverse().then((_) {
                                  if (mounted) {
                                    setState(() {
                                      _currentNotification = null;
                                    });
                                  }
                                });
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: isDark ? Colors.grey[500] : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
