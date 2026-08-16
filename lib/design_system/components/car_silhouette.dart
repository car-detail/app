import 'package:flutter/material.dart';

/// Draws a simple flat-design side-profile car silhouette from primitive
/// shapes (no external image assets) — a low cabin roof, wider lower body,
/// two wheels, and a window cutout. Used both as a static background
/// watermark ([CarSilhouette]) and as the shape driven across the screen
/// by [CarLoader].
class CarSilhouettePainter extends CustomPainter {
  CarSilhouettePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // Lower body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.45, w, h * 0.32),
      Radius.circular(h * 0.1),
    );
    canvas.drawRRect(bodyRect, paint);

    // Cabin (roof)
    final cabinPath = Path()
      ..moveTo(w * 0.18, h * 0.45)
      ..lineTo(w * 0.28, h * 0.18)
      ..quadraticBezierTo(w * 0.32, h * 0.12, w * 0.4, h * 0.12)
      ..lineTo(w * 0.72, h * 0.12)
      ..quadraticBezierTo(w * 0.8, h * 0.12, w * 0.83, h * 0.2)
      ..lineTo(w * 0.88, h * 0.45)
      ..close();
    canvas.drawPath(cabinPath, paint);

    // Window cutout
    final windowPaint = Paint()..color = Colors.white.withOpacity(0.35);
    final windowPath = Path()
      ..moveTo(w * 0.32, h * 0.4)
      ..lineTo(w * 0.38, h * 0.22)
      ..lineTo(w * 0.6, h * 0.22)
      ..lineTo(w * 0.62, h * 0.4)
      ..close();
    canvas.drawPath(windowPath, windowPaint);
    final windowPath2 = Path()
      ..moveTo(w * 0.65, h * 0.4)
      ..lineTo(w * 0.64, h * 0.22)
      ..lineTo(w * 0.78, h * 0.22)
      ..lineTo(w * 0.83, h * 0.4)
      ..close();
    canvas.drawPath(windowPath2, windowPaint);

    // Wheels
    final wheelPaint = Paint()..color = color.withOpacity(0.9);
    final wheelRadius = h * 0.16;
    canvas.drawCircle(Offset(w * 0.26, h * 0.8), wheelRadius, wheelPaint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.8), wheelRadius, wheelPaint);
    final hubPaint = Paint()..color = Colors.white.withOpacity(0.5);
    canvas.drawCircle(Offset(w * 0.26, h * 0.8), wheelRadius * 0.4, hubPaint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.8), wheelRadius * 0.4, hubPaint);
  }

  @override
  bool shouldRepaint(covariant CarSilhouettePainter oldDelegate) => oldDelegate.color != color;
}

/// Static, low-opacity decorative car shape meant to sit behind content
/// (e.g. in a header or empty state) — not tappable, purely texture.
class CarSilhouette extends StatelessWidget {
  const CarSilhouette({
    super.key,
    this.size = 120,
    this.color = Colors.white,
    this.opacity = 0.08,
    this.rotation = 0,
  });

  final double size;
  final Color color;
  final double opacity;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: rotation,
        child: SizedBox(
          width: size,
          height: size * 0.55,
          child: CustomPaint(painter: CarSilhouettePainter(color: color)),
        ),
      ),
    );
  }
}
