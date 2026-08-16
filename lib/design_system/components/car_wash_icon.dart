import 'package:flutter/material.dart';

/// Front-facing car silhouette, flat-icon style — matches the reference
/// style the user provided (rounded hood arc, two headlights, split
/// windshield, wing mirrors). Original artwork drawn with CustomPainter,
/// not a copy of any stock asset. This is the "clean, ready-to-wash car"
/// icon used across the app's car-wash-themed decoration.
class CarFrontPainter extends CustomPainter {
  CarFrontPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color..style = PaintingStyle.fill;

    // Body: wide rounded arc (hood) merging into a lower body band.
    final body = Path()
      ..moveTo(w * 0.06, h * 0.95)
      ..lineTo(w * 0.06, h * 0.55)
      ..cubicTo(w * 0.06, h * 0.22, w * 0.28, h * 0.06, w * 0.5, h * 0.06)
      ..cubicTo(w * 0.72, h * 0.06, w * 0.94, h * 0.22, w * 0.94, h * 0.55)
      ..lineTo(w * 0.94, h * 0.95)
      ..close();
    canvas.drawPath(body, paint);

    // Windshield split (two trapezoid panes with a thin gap = wipers line)
    final glass = Paint()..color = Colors.white.withOpacity(0.4);
    final laneGap = w * 0.03;
    final leftPane = Path()
      ..moveTo(w * 0.22, h * 0.5)
      ..lineTo(w * 0.3, h * 0.22)
      ..lineTo(w * 0.5 - laneGap, h * 0.22)
      ..lineTo(w * 0.5 - laneGap, h * 0.5)
      ..close();
    final rightPane = Path()
      ..moveTo(w * 0.5 + laneGap, h * 0.22)
      ..lineTo(w * 0.7, h * 0.22)
      ..lineTo(w * 0.78, h * 0.5)
      ..lineTo(w * 0.5 + laneGap, h * 0.5)
      ..close();
    canvas.drawPath(leftPane, glass);
    canvas.drawPath(rightPane, glass);

    // Headlights
    final headlight = Paint()..color = Colors.white.withOpacity(0.55);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.14, h * 0.62), width: w * 0.12, height: h * 0.1), headlight);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.86, h * 0.62), width: w * 0.12, height: h * 0.1), headlight);

    // Wing mirrors
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.0, h * 0.42, w * 0.06, h * 0.08), Radius.circular(w * 0.02)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.94, h * 0.42, w * 0.06, h * 0.08), Radius.circular(w * 0.02)),
      paint,
    );

    // Grille slats
    final grille = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = h * 0.02;
    for (final f in [0.68, 0.76, 0.84]) {
      canvas.drawLine(Offset(w * 0.36, h * f), Offset(w * 0.64, h * f), grille);
    }
  }

  @override
  bool shouldRepaint(covariant CarFrontPainter oldDelegate) => oldDelegate.color != color;
}

/// Four-pointed sparkle/shine mark, the "freshly cleaned" motif from the
/// reference icons.
class SparklePainter extends CustomPainter {
  SparklePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final cx = size.width / 2, cy = size.height / 2;
    final path = Path()
      ..moveTo(cx, 0)
      ..quadraticBezierTo(cx, cy, size.width, cy)
      ..quadraticBezierTo(cx, cy, cx, size.height)
      ..quadraticBezierTo(cx, cy, 0, cy)
      ..quadraticBezierTo(cx, cy, cx, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklePainter oldDelegate) => oldDelegate.color != color;
}

/// Small sparkle widget, sized for scattering around a car icon.
class Sparkle extends StatelessWidget {
  const Sparkle({super.key, this.size = 14, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: SparklePainter(color: color)));
}

/// Static front-facing car icon with a couple of sparkles, used as a
/// themed illustration for headers/empty-states/banners (a static
/// "just detailed" look, distinct from CarLoader's driving motion).
class CarWashIcon extends StatelessWidget {
  const CarWashIcon({
    super.key,
    this.size = 100,
    this.color = Colors.white,
    this.opacity = 1.0,
    this.showSparkles = true,
  });

  final double size;
  final Color color;
  final double opacity;
  final bool showSparkles;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size * 0.82,
              height: size * 0.82,
              child: CustomPaint(painter: CarFrontPainter(color: color)),
            ),
            if (showSparkles) ...[
              Positioned(top: 0, left: size * 0.06, child: Sparkle(size: size * 0.16, color: color)),
              Positioned(top: size * 0.14, right: 0, child: Sparkle(size: size * 0.11, color: color)),
            ],
          ],
        ),
      ),
    );
  }
}
