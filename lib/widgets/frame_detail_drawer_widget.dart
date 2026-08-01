import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../models/frame_item.dart';
import '../screens/edit_frame_screen.dart';
import 'app_image_widget.dart';
import 'upload_progress_modal.dart';
import '../services/local_database_service.dart';
import '../services/supabase_sync_service.dart';

class FrameDetailDrawerWidget extends StatefulWidget {
  final FrameItem frame;
  final VoidCallback? onDelete;
  final Function(FrameItem updatedFrame)? onEdit;

  const FrameDetailDrawerWidget({
    super.key,
    required this.frame,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<FrameDetailDrawerWidget> createState() =>
      _FrameDetailDrawerWidgetState();
}

class _FrameDetailDrawerWidgetState extends State<FrameDetailDrawerWidget> {
  int _selectedPhotoIndex = 0;
  double _currentPage = 0.0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _currentPage = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _photoList {
    if (widget.frame.imagePaths.isNotEmpty) {
      return widget.frame.imagePaths;
    }
    if (widget.frame.imagePath.isNotEmpty) {
      return [widget.frame.imagePath];
    }
    return [''];
  }

  void _goToNextPhoto() {
    if (_selectedPhotoIndex < _photoList.length - 1) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedPhotoIndex++;
        _pageController.animateToPage(
          _selectedPhotoIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  void _goToPrevPhoto() {
    if (_selectedPhotoIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedPhotoIndex--;
        _pageController.animateToPage(
          _selectedPhotoIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final txtColor = isDark ? Colors.white : const Color(0xFF121212);
    final subTxtColor = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
    final cardBg = isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8);
    final tileBg = isDark ? const Color(0xFF22242B) : const Color(0xFFF9FAFB);
    final closeBg = isDark ? const Color(0xFF282A32) : Colors.white;
    final editBtnFg = isDark ? Colors.white : const Color(0xFF121212);
    final doneBtnBg = isDark ? Colors.white : const Color(0xFF121212);
    final doneBtnFg = isDark ? const Color(0xFF121212) : Colors.white;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Drag Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. Interactive Hold & Slide Photo Carousel Card
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(28),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -80) {
                      _goToNextPhoto();
                    } else if (details.primaryVelocity! > 80) {
                      _goToPrevPhoto();
                    }
                  }
                },
                child: Stack(
                  children: [
                    // Swipeable PageView Carousel
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            _selectedPhotoIndex = index;
                          });
                        },
                        itemCount: _photoList.length,
                        itemBuilder: (context, index) {
                          return AppImageWidget(
                            imagePath: _photoList[index],
                            fit: BoxFit.cover,
                            iconSize: 56,
                          );
                        },
                      ),
                    ),

                    // Left Chevron Slide Arrow
                    if (_selectedPhotoIndex > 0)
                      Positioned(
                        left: 10,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _goToPrevPhoto,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Right Chevron Slide Arrow
                    if (_selectedPhotoIndex < _photoList.length - 1)
                      Positioned(
                        right: 10,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _goToNextPhoto,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Top Right Close X Button
                    Positioned(
                      right: 14,
                      top: 14,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: closeBg,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.close_rounded,
                              color: txtColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom Left Category Pill Badge
                    Positioned(
                      left: 14,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.frame.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),

                    // Bottom Right Fluid Morphing Carousel Dots Indicator
                    Positioned(
                      right: 14,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_photoList.length, (index) {
                            final double dist = (index - _currentPage).abs();
                            final double factor = (1.0 - dist.clamp(0.0, 1.0));
                            final double dotWidth = 6.0 + (factor * 12.0);
                            final Color? dotColor = Color.lerp(
                              Colors.white.withOpacity(0.65),
                              const Color(0xFFEF4444),
                              factor,
                            );

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              width: dotWidth,
                              height: 6,
                              decoration: BoxDecoration(
                                color: dotColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. Thumbnail Preview Selector Row
            Row(
              children: List.generate(_photoList.length, (index) {
                final isSelected = _selectedPhotoIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPhotoIndex = index;
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(right: 10),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFEF4444)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AppImageWidget(
                        imagePath: _photoList[index],
                        fit: BoxFit.cover,
                        iconSize: 24,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // 4. Company Brand Subtitle & Frame Title
            Text(
              'COMPANY BRAND • ${widget.frame.brand.toUpperCase()}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFFEF4444),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.frame.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: txtColor,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),

            // 5. Price & Active Stock Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${widget.frame.priceSymbol}${widget.frame.price.toInt()}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFEF4444),
                    letterSpacing: -0.5,
                  ),
                ),

                // Active Stock Green Pill Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1B382B)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: isDark
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Active Stock • ${widget.frame.stockCount} Pcs',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const CircleAvatar(
                        radius: 4,
                        backgroundColor: Color(0xFF4CAF50),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 6. Prominent Stock Quantity & Box Number Metadata Grid Cards
            Row(
              children: [
                // Stock Quantity Tile
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: tileBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.inventory_2_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AVAILABLE STOCK',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: subTxtColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.frame.stockCount} Pcs',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: txtColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Box Number Tile
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: tileBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.inbox_rounded,
                              color: Color(0xFF0284C7),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BOX LOCATION',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: subTxtColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.frame.boxNumber.isEmpty ? 'BOX-01' : widget.frame.boxNumber,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: txtColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 7. Upload Timestamp Card Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPLOAD TIMESTAMP',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: subTxtColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.frame.formattedDate,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: txtColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 8. Stock Colors Row
            Row(
              children: [
                Text(
                  'STOCK COLORS:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: subTxtColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : const Color(0xFF121212),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 9. Bottom Action Buttons (Delete, Edit & Done)
            Row(
              children: [
                SizedBox(
                  height: 52,
                  width: 52,
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => UploadProgressModal(
                          frameName: widget.frame.name,
                          brand: widget.frame.brand,
                          price: widget.frame.price,
                          imagePath: widget.frame.imagePath,
                          isDeleteMode: true,
                          uploadTask: () async {
                            if (widget.onDelete != null) {
                              widget.onDelete!();
                            }
                            LocalDatabaseService().deleteFrame(widget.frame.id, markPending: true);
                            await SupabaseSyncService().broadcastAction(action: 'delete', frame: widget.frame);
                            return widget.frame;
                          },
                          onSuccess: (deletedFrame) {
                            if (mounted) {
                              Navigator.pop(context); // Pops drawer
                            }
                          },
                        ),
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEBEE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => EditFrameScreen(
                              frame: widget.frame,
                              onSave: (updated) {
                                if (widget.onEdit != null) {
                                  widget.onEdit!(updated);
                                }
                              },
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.edit_outlined, size: 18, color: editBtnFg),
                      label: Text(
                        'Edit Details',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: editBtnFg,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: editBtnFg,
                        side: BorderSide(color: editBtnFg, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: doneBtnBg,
                        foregroundColor: doneBtnFg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: doneBtnFg,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
