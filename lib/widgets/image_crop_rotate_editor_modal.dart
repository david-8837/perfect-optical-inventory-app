import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'app_image_widget.dart';
import '../services/local_image_cache_service.dart';

class ImageCropRotateEditorModal extends StatefulWidget {
  final String imageProviderUrl;
  final Function(String finalImageUrl) onCropSaved;

  const ImageCropRotateEditorModal({
    super.key,
    required this.imageProviderUrl,
    required this.onCropSaved,
  });

  @override
  State<ImageCropRotateEditorModal> createState() =>
      _ImageCropRotateEditorModalState();
}

class _ImageCropRotateEditorModalState
    extends State<ImageCropRotateEditorModal> {
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _cropViewportKey = GlobalKey();
  int _rotationQuarterTurns = 0; // 0, 1, 2, 3
  bool _isApplying = false;

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _rotateCounterClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 3) % 4;
    });
  }

  void _resetTransform() {
    setState(() {
      _transformationController.value = Matrix4.identity();
      _rotationQuarterTurns = 0;
    });
  }

  Future<void> _applyCropAndSave() async {
    if (_isApplying) return;
    setState(() => _isApplying = true);

    try {
      if (_cropViewportKey.currentContext != null) {
        final boundary = _cropViewportKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary != null) {
          final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
          final ByteData? byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final pngBytes = byteData.buffer.asUint8List();
            final base64Uri =
                'data:image/png;base64,${base64Encode(pngBytes)}';
            final localFilePath = await LocalImageCacheService().cacheImageData(
              imagePathOrUrl: base64Uri,
              rawBytes: pngBytes,
            );
            if (mounted) {
              Navigator.pop(context);
              widget.onCropSaved(localFilePath);
            }
            return;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error baking rotated image: $e');
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onCropSaved(widget.imageProviderUrl);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.crop_rotate_rounded,
                        color: Color(0xFF121212), size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Crop & Rotate Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF121212),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF8E8E93)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Hold & slide image inside the crop outline to position frame',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 16),

            // Interactive Crop Viewport Canvas
            Container(
              height: 230,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2023),
                borderRadius: BorderRadius.circular(28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    // Pan, Zoom & Rotated Image Canvas
                    Positioned.fill(
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        boundaryMargin: const EdgeInsets.all(200),
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: RepaintBoundary(
                            key: _cropViewportKey,
                            child: RotatedBox(
                              quarterTurns: _rotationQuarterTurns,
                              child: AppImageWidget(
                                imagePath: widget.imageProviderUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Drawer Crop Frame Outline Mask (Red Highlight Outline)
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFFEF4444),
                            width: 2.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Rule of Thirds Grid Guidelines
                            Column(
                              children: [
                                const Expanded(child: SizedBox()),
                                Divider(
                                    color: Colors.white.withOpacity(0.20),
                                    height: 1),
                                const Expanded(child: SizedBox()),
                                Divider(
                                    color: Colors.white.withOpacity(0.20),
                                    height: 1),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                            Row(
                              children: [
                                const Expanded(child: SizedBox()),
                                VerticalDivider(
                                    color: Colors.white.withOpacity(0.20),
                                    width: 1),
                                const Expanded(child: SizedBox()),
                                VerticalDivider(
                                    color: Colors.white.withOpacity(0.20),
                                    width: 1),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                            Positioned(
                              top: 10,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'DRAWER PREVIEW CROP OUTLINE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rotation & Reset Tools Toolbar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _rotateCounterClockwise,
                    icon: const Icon(Icons.rotate_left_rounded, size: 16),
                    label: const Text('↺ Left'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF121212),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _rotateClockwise,
                    icon: const Icon(Icons.rotate_right_rounded, size: 16),
                    label: const Text('↻ Right'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF121212),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _resetTransform,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8E8E93),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Crop & Apply Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isApplying ? null : _applyCropAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF121212),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: _isApplying
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Saving Rotated Photo...',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Apply Crop & Save Photo',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
