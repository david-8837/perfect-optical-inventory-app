import 'package:flutter/material.dart';

class CustomGlassesIcon extends StatelessWidget {
  final Color color;
  final double size;
  final double strokeWidth;

  const CustomGlassesIcon({
    super.key,
    this.color = const Color(0xFFDC2626),
    this.size = 48.0,
    this.strokeWidth = 3.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.55),
      painter: _GlassesPainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _GlassesPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _GlassesPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final width = size.width;
    final height = size.height;

    final lensWidth = width * 0.38;
    final lensHeight = height * 0.72;
    final lensY = height * 0.2;
    final cornerRadius = lensWidth * 0.35;

    // Left Lens
    final leftLensRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.08, lensY, lensWidth, lensHeight),
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(leftLensRect, paint);

    // Right Lens
    final rightLensRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.54, lensY, lensWidth, lensHeight),
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(rightLensRect, paint);

    // Nose Bridge (curved top arc between lenses)
    final bridgePath = Path();
    bridgePath.moveTo(width * 0.46, lensY + lensHeight * 0.25);
    bridgePath.quadraticBezierTo(
      width * 0.50,
      lensY - lensHeight * 0.1,
      width * 0.54,
      lensY + lensHeight * 0.25,
    );
    canvas.drawPath(bridgePath, paint);

    // Left hinge tip
    canvas.drawLine(
      Offset(width * 0.08, lensY + lensHeight * 0.2),
      Offset(width * 0.02, lensY + lensHeight * 0.25),
      paint,
    );

    // Right hinge tip
    canvas.drawLine(
      Offset(width * 0.92, lensY + lensHeight * 0.2),
      Offset(width * 0.98, lensY + lensHeight * 0.25),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassesPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
