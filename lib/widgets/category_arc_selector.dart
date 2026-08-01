import 'package:flutter/material.dart';
import 'dart:ui';
import 'custom_glasses_painter.dart';
import '../utils/app_translations.dart';

class CategoryItemData {
  final String label;
  final IconData? icon;
  final bool isCustomGlassesIcon;

  const CategoryItemData({
    required this.label,
    this.icon,
    this.isCustomGlassesIcon = false,
  });
}

class CategoryArcSelector extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;
  final String currentLanguage;
  final double progress; // 0.0 (curved arc) to 1.0 (sticky horizontal bar)

  const CategoryArcSelector({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
    this.currentLanguage = 'English (US)',
    this.progress = 0.0,
  });

  @override
  State<CategoryArcSelector> createState() => _CategoryArcSelectorState();
}

class _CategoryArcSelectorState extends State<CategoryArcSelector> {
  late PageController _pageController;

  static const List<CategoryItemData> categories = [
    CategoryItemData(label: 'Rimless', icon: Icons.light_mode_outlined),
    CategoryItemData(label: 'Cat Eye', icon: Icons.auto_awesome_outlined),
    CategoryItemData(label: 'Plastic Frame', icon: Icons.layers_outlined),
    CategoryItemData(label: 'All', isCustomGlassesIcon: true),
    CategoryItemData(label: 'Metal Frame', icon: Icons.shield_outlined),
    CategoryItemData(label: 'Half Frame', icon: Icons.remove_red_eye_outlined),
    CategoryItemData(label: 'Sunglass', icon: Icons.workspace_premium_outlined),
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = categories.indexWhere(
      (c) => c.label.toLowerCase() == widget.selectedCategory.toLowerCase(),
    );
    int allIndex = categories.indexWhere((c) => c.label.toLowerCase() == 'all');
    if (allIndex == -1) allIndex = 3;
    if (initialIndex == -1) initialIndex = allIndex;

    _pageController = PageController(
      initialPage: initialIndex,
      viewportFraction: 0.36,
    );
  }

  @override
  void didUpdateWidget(covariant CategoryArcSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      int targetIndex = categories.indexWhere(
        (c) => c.label.toLowerCase() == widget.selectedCategory.toLowerCase(),
      );
      if (targetIndex != -1 && _pageController.hasClients) {
        if (_pageController.page?.round() != targetIndex) {
          _pageController.animateToPage(
            targetIndex,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.progress.clamp(0.0, 1.0);

    // Interpolate container height from 160 (curved) to 58 (horizontal bar)
    final double containerHeight = lerpDouble(160.0, 58.0, p)!;

    return SizedBox(
      height: containerHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Single Shared Morphing Background (Curved Arc -> Flat Horizontal Pill Bar)
          Positioned.fill(
            child: CustomPaint(
              size: Size(screenWidth, containerHeight),
              painter: ArcBackgroundPainter(isDark: isDark, progress: p),
            ),
          ),

          // Interpolated Category Items Carousel
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double currentPage = 3.0;
              if (_pageController.hasClients &&
                  _pageController.position.haveDimensions) {
                currentPage = _pageController.page ?? 3.0;
              }

              return PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                itemCount: categories.length,
                onPageChanged: (index) {
                  widget.onSelectCategory(categories[index].label);
                },
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final delta = index - currentPage;
                  final absDelta = delta.abs();

                  // Interpolate Y-offset: Parabolic arc curve -> Perfectly aligned horizontal strip
                  final double arcYOffset = 4.0 + (6.0 * (delta * delta));
                  final double yOffset = lerpDouble(arcYOffset, 0.0, p)!;

                  // Interpolate Scale factor
                  final double arcScale = (1.15 - 0.20 * absDelta).clamp(0.75, 1.22);
                  final double barScale = (1.0 - 0.12 * absDelta).clamp(0.85, 1.0);
                  final double scale = lerpDouble(arcScale, barScale, p)!;

                  // Interpolate Opacity
                  final double arcOpacity = (1.0 - 0.38 * absDelta).clamp(0.45, 1.0);
                  final double barOpacity = (1.0 - 0.18 * absDelta).clamp(0.65, 1.0);
                  final double opacity = lerpDouble(arcOpacity, barOpacity, p)!;

                  final isSelected = delta.abs() < 0.3;

                  // Colors
                  final btnBg = isSelected
                      ? (isDark ? Colors.white : const Color(0xFF121212))
                      : (isDark ? const Color(0xFF282A32) : Colors.white);

                  final iconColor = isSelected
                      ? (isDark ? const Color(0xFF121212) : Colors.white)
                      : (isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93));

                  final labelColor = isSelected
                      ? (isDark ? Colors.white : const Color(0xFF121212))
                      : (isDark ? const Color(0xFFA0A0A5) : const Color(0xFF9E9E9E));

                  // Button Dimensions: Shrink smoothly from 66/52 to 42/36
                  final double targetWidth = isSelected ? 66.0 : 52.0;
                  final double compactWidth = isSelected ? 44.0 : 38.0;
                  final double btnSize = lerpDouble(targetWidth, compactWidth, p)!;

                  final double iconSize = lerpDouble(
                    cat.isCustomGlassesIcon
                        ? (isSelected ? 30.0 : 22.0)
                        : (isSelected ? 26.0 : 22.0),
                    cat.isCustomGlassesIcon ? 20.0 : 18.0,
                    p,
                  )!;

                  // Fade out text label smoothly when morphing into sticky bar
                  final double labelOpacity = lerpDouble(1.0, 0.0, (p * 2.0).clamp(0.0, 1.0))!;

                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: Transform.translate(
                      offset: Offset(0, yOffset),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon Container Button
                              Container(
                                width: btnSize,
                                height: btnSize,
                                decoration: BoxDecoration(
                                  color: btnBg,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? null
                                      : Border.all(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.08)
                                              : const Color(0xFFEFEFEF),
                                          width: 1,
                                        ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? (isDark
                                              ? Colors.black.withOpacity(0.55 * (1 - p * 0.4))
                                              : Colors.black.withOpacity(0.35 * (1 - p * 0.4)))
                                          : Colors.black.withOpacity(0.04),
                                      blurRadius: lerpDouble(isSelected ? 18.0 : 6.0, 4.0, p)!,
                                      spreadRadius: isSelected ? 1 : 0,
                                      offset: Offset(0, lerpDouble(isSelected ? 7.0 : 2.0, 2.0, p)!),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: cat.isCustomGlassesIcon
                                      ? CustomGlassesIcon(
                                          color: iconColor,
                                          size: iconSize,
                                          strokeWidth: isSelected ? 3.0 : 2.5,
                                        )
                                      : Icon(
                                          cat.icon,
                                          color: iconColor,
                                          size: iconSize,
                                        ),
                                ),
                              ),

                              // Text Label & Dot Indicator (Fade out smoothly as height shrinks)
                              if (labelOpacity > 0.01) ...[
                                const SizedBox(height: 4),
                                Opacity(
                                  opacity: labelOpacity,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppTranslations.trCategory(
                                            widget.currentLanguage, cat.label),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: isSelected ? 12.5 : 11,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w500,
                                          color: labelColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (isSelected)
                                        Container(
                                          width: 5.5,
                                          height: 5.5,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE53935),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class MorphingCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;
  final String currentLanguage;

  MorphingCategoryHeaderDelegate({
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.currentLanguage,
  });

  @override
  double get minExtent => 58.0;

  @override
  double get maxExtent => 160.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double range = maxExtent - minExtent;
    final double progress = (shrinkOffset / range).clamp(0.0, 1.0);

    return CategoryArcSelector(
      selectedCategory: selectedCategory,
      onSelectCategory: onSelectCategory,
      currentLanguage: currentLanguage,
      progress: progress,
    );
  }

  @override
  bool shouldRebuild(covariant MorphingCategoryHeaderDelegate oldDelegate) {
    return oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.currentLanguage != currentLanguage;
  }
}

class ArcBackgroundPainter extends CustomPainter {
  final bool isDark;
  final double progress;

  ArcBackgroundPainter({
    this.isDark = false,
    this.progress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final topColor = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final bottomColor = isDark ? const Color(0xFF0F0F12) : const Color(0xFFF7F8FA);
    final currentColor = Color.lerp(bottomColor, topColor, progress)!;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          topColor,
          topColor,
          currentColor,
        ],
        stops: const [0.0, 0.70, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity((isDark ? 0.25 : 0.035) * (1.0 - progress * 0.5))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16 * (1.0 - progress * 0.5));

    final path = Path();
    final double peakY = lerpDouble(-18.0, 0.0, progress)!;
    final double cornerY = lerpDouble(38.0, 0.0, progress)!;

    path.moveTo(-20, size.height);
    path.lineTo(-20, cornerY);
    path.quadraticBezierTo(
      size.width * 0.5,
      peakY,
      size.width + 20,
      cornerY,
    );
    path.lineTo(size.width + 20, size.height);
    path.close();

    canvas.drawPath(path.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant ArcBackgroundPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.progress != progress;
}
