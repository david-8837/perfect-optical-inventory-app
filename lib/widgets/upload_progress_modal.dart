import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/frame_item.dart';
import 'app_image_widget.dart';

class UploadProgressModal extends StatefulWidget {
  final String frameName;
  final String brand;
  final double price;
  final String imagePath;
  final bool isEditMode;
  final bool isDeleteMode;
  final Future<FrameItem?> Function() uploadTask;
  final Function(FrameItem savedFrame) onSuccess;

  const UploadProgressModal({
    super.key,
    required this.frameName,
    required this.brand,
    required this.price,
    required this.imagePath,
    this.isEditMode = false,
    this.isDeleteMode = false,
    required this.uploadTask,
    required this.onSuccess,
  });

  @override
  State<UploadProgressModal> createState() => _UploadProgressModalState();
}

class _UploadProgressModalState extends State<UploadProgressModal>
    with SingleTickerProviderStateMixin {
  bool _isSuccess = false;
  bool _hasError = false;
  String _errorMessage = '';
  double _progress = 0.20;
  late String _statusText;
  FrameItem? _savedFrame;

  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    if (widget.isDeleteMode) {
      _statusText = 'Deleting Frame from Inventory...';
    } else if (widget.isEditMode) {
      _statusText = 'Updating Eyewear Details...';
    } else {
      _statusText = 'Optimizing Frame Photos...';
    }

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);

    _startUploadFlow();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _startUploadFlow() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() {
      _progress = 0.55;
      if (widget.isDeleteMode) {
        _statusText = 'Removing Local Data & Syncing Cloud...';
      } else if (widget.isEditMode) {
        _statusText = 'Saving to Local Storage & Cloud Sync...';
      } else {
        _statusText = 'Uploading to Cloud & Local Storage...';
      }
    });

    try {
      final result = await widget.uploadTask();
      _savedFrame = result;

      if (!mounted) return;
      setState(() {
        _progress = 0.90;
        _statusText = widget.isDeleteMode
            ? 'Updating Live Inventory List...'
            : 'Syncing Live Inventory Database...';
      });

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      setState(() {
        _progress = 1.0;
        _isSuccess = true;
      });

      HapticFeedback.mediumImpact();
      _animCtrl.forward();

      if (_savedFrame != null) {
        widget.onSuccess(_savedFrame!);
      }
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = err.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final txtColor = isDark ? Colors.white : const Color(0xFF121212);
    final subTxtColor = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
    final containerBg = isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8);
    final btnBg = isDark ? Colors.white : const Color(0xFF121212);
    final btnFg = isDark ? const Color(0xFF121212) : Colors.white;

    String titleHeader;
    String successHeader;
    String successSub;
    String actionBtnText;

    if (widget.isDeleteMode) {
      titleHeader = 'Deleting Frame...';
      successHeader = 'Frame Deleted!';
      successSub = 'Removed "${widget.frameName}" from inventory';
      actionBtnText = 'Done & Continue';
    } else if (widget.isEditMode) {
      titleHeader = 'Updating Eyewear...';
      successHeader = 'Eyewear Updated!';
      successSub = 'Updated "${widget.frameName}" in inventory';
      actionBtnText = 'Done & Return';
    } else {
      titleHeader = 'Uploading Frame Photo...';
      successHeader = 'Frame Saved Successfully!';
      successSub = 'Added "${widget.frameName}" to inventory';
      actionBtnText = 'Done & Add Another';
    }

    IconData spinnerIcon = Icons.cloud_upload_rounded;
    if (widget.isDeleteMode) {
      spinnerIcon = Icons.delete_sweep_rounded;
    } else if (widget.isEditMode) {
      spinnerIcon = Icons.edit_note_rounded;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(32),
          border: isDark
              ? Border.all(color: Colors.white.withOpacity(0.08), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasError) ...[
              // Error State
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.error_outline_rounded,
                      color: Color(0xFFEF4444), size: 36),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isDeleteMode
                    ? 'Delete Failed'
                    : (widget.isEditMode ? 'Update Failed' : 'Upload Failed'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: txtColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage.isNotEmpty ? _errorMessage : 'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: subTxtColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Close'),
              ),
            ] else if (!_isSuccess) ...[
              // Phase 1: Uploading/Updating/Deleting Spinner State
              const SizedBox(height: 10),
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 4.5,
                      backgroundColor: isDark
                          ? const Color(0xFF282A32)
                          : const Color(0xFFE0E0E0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isDeleteMode
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                    Icon(
                      spinnerIcon,
                      color: isDark ? Colors.white : const Color(0xFF121212),
                      size: 30,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                titleHeader,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: txtColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subTxtColor,
                ),
              ),
              const SizedBox(height: 20),
              // Linear Progress Bar & Percentage
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? const Color(0xFF282A32)
                      : const Color(0xFFE0E0E0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFEF4444),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ] else ...[
              // Phase 2: Success Morphed Checkmark / Trash State
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: widget.isDeleteMode
                        ? (isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFEBEE))
                        : (isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      widget.isDeleteMode
                          ? Icons.delete_forever_rounded
                          : Icons.check_circle_rounded,
                      color: widget.isDeleteMode
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      size: 44,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                successHeader,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: txtColor,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                successSub,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: subTxtColor,
                ),
              ),
              const SizedBox(height: 20),

              // Product Preview Badge Tile
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: containerBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1B20)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AppImageWidget(
                          imagePath: widget.imagePath,
                          fit: BoxFit.cover,
                          iconSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.frameName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: txtColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.brand,
                            style: TextStyle(
                              fontSize: 12,
                              color: subTxtColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '₹${widget.price.toInt()}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnBg,
                    foregroundColor: btnFg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    actionBtnText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
