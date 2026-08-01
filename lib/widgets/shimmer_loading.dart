import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-2.0 + (_controller.value * 4.0), -0.2),
              end: Alignment(-1.0 + (_controller.value * 4.0), 0.2),
              colors: const [
                Color(0xFFEBEBF4),
                Color(0xFFF6F6FC),
                Color(0xFFEBEBF4),
              ],
              stops: const [0.15, 0.5, 0.85],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 16,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// Product Grid Card Skeleton
class FrameCardSkeleton extends StatelessWidget {
  const FrameCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Box Skeleton
            ShimmerBox(
              height: 120,
              borderRadius: 18,
            ),
            SizedBox(height: 12),
            // Title Pill Skeleton
            ShimmerBox(
              width: 110,
              height: 14,
              borderRadius: 6,
            ),
            SizedBox(height: 6),
            // Brand & Price Subtitle Pill
            ShimmerBox(
              width: 70,
              height: 12,
              borderRadius: 6,
            ),
            SizedBox(height: 10),
            // Rating & Price Bottom Row Skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(
                  width: 50,
                  height: 18,
                  borderRadius: 10,
                ),
                ShimmerBox(
                  width: 32,
                  height: 32,
                  borderRadius: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Main Home Screen Skeleton Grid Layout
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        // Header & Search Skeleton
        const ShimmerLoading(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 140, height: 22, borderRadius: 8),
                  SizedBox(height: 6),
                  ShimmerBox(width: 90, height: 12, borderRadius: 6),
                ],
              ),
              ShimmerBox(width: 44, height: 44, borderRadius: 22),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Search Bar Skeleton
        const ShimmerLoading(
          child: ShimmerBox(height: 52, borderRadius: 26),
        ),
        const SizedBox(height: 24),

        // Category Arc Skeleton
        const ShimmerLoading(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 75, height: 36, borderRadius: 18),
              ShimmerBox(width: 75, height: 36, borderRadius: 18),
              ShimmerBox(width: 75, height: 36, borderRadius: 18),
              ShimmerBox(width: 75, height: 36, borderRadius: 18),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Grid of Frame Cards Skeletons
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => const FrameCardSkeleton(),
        ),
      ],
    );
  }
}

// Hub Screen Skeleton
class HubScreenSkeleton extends StatelessWidget {
  const HubScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: const [
        ShimmerLoading(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: 180, height: 26, borderRadius: 8),
              SizedBox(height: 6),
              ShimmerBox(width: 240, height: 14, borderRadius: 6),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Main Overview Card Skeleton
        ShimmerLoading(
          child: ShimmerBox(height: 190, borderRadius: 28),
        ),
        SizedBox(height: 28),

        ShimmerLoading(
          child: ShimmerBox(width: 160, height: 14, borderRadius: 6),
        ),
        SizedBox(height: 12),

        // Card List Skeletons
        ShimmerLoading(child: ShimmerBox(height: 72, borderRadius: 24)),
        SizedBox(height: 12),
        ShimmerLoading(child: ShimmerBox(height: 72, borderRadius: 24)),
        SizedBox(height: 12),
        ShimmerLoading(child: ShimmerBox(height: 72, borderRadius: 24)),
      ],
    );
  }
}
