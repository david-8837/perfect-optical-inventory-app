import 'dart:async';
import 'package:flutter/material.dart';
import '../services/supabase_sync_service.dart';

class SyncLoadingScreen extends StatefulWidget {
  final VoidCallback onSyncComplete;

  const SyncLoadingScreen({super.key, required this.onSyncComplete});

  @override
  State<SyncLoadingScreen> createState() => _SyncLoadingScreenState();
}

class _SyncLoadingScreenState extends State<SyncLoadingScreen> {
  String _currentStatusMessage = 'Initializing application...';
  double _progress = 0.05;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _runRealSync();
  }

  Future<void> _runRealSync() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
      _progress = 0.05;
      _currentStatusMessage = 'Initializing application...';
    });

    await SupabaseSyncService().syncWithCloudProgress((message, progress) {
      if (mounted) {
        setState(() {
          _currentStatusMessage = message;
          _progress = progress.clamp(0.0, 1.0);
        });
      }
    });

    if (mounted) {
      setState(() {
        _isSyncing = false;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) widget.onSyncComplete();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F12) : const Color(0xFFFFFFFF);
    final txt = isDark ? Colors.white : const Color(0xFF121212);
    final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Pulse Icon
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.9, end: 1.05),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, val, child) => Transform.scale(
                  scale: val,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1B20) : const Color(0xFFF5F6F8),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.cloud_sync_rounded,
                        size: 38,
                        color: isDark ? Colors.white : const Color(0xFF121212),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Synchronizing Store Data',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: txt,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),

              // Animated Status Message from Real Sync Engine
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _currentStatusMessage,
                  key: ValueKey<String>(_currentStatusMessage),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: subTxt,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: isDark ? const Color(0xFF282A32) : const Color(0xFFE0E0E0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white : const Color(0xFF121212),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(_progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: subTxt,
                ),
              ),
              const SizedBox(height: 24),

              // Skip/Continue Button in case user wants immediate access
              TextButton(
                onPressed: widget.onSyncComplete,
                style: TextButton.styleFrom(
                  foregroundColor: subTxt,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Continue to App →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

