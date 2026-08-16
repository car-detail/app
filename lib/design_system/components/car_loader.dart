import 'package:flutter/material.dart';
import '../../Common/ModernDesignSystem.dart';
import 'car_silhouette.dart';
import '../car_assets.dart';

/// Car-themed replacement for CircularProgressIndicator: a small car
/// drives back and forth above a dashed "road" line. Uses the real,
/// properly-licensed side-view car line art (assets/vetor/), tinted to
/// match the loader's color, falling back to the hand-drawn silhouette
/// if the asset can't load. Drop-in for any loading spot in the app —
/// `CarLoader()` instead of `const CircularProgressIndicator()`.
class CarLoader extends StatefulWidget {
  const CarLoader({super.key, this.color, this.width = 110, this.carSize = 52});

  final Color? color;
  final double width;
  final double carSize;

  @override
  State<CarLoader> createState() => _CarLoaderState();
}

class _CarLoaderState extends State<CarLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? ModernDesignSystem.accentFor(1);
    final travel = widget.width - widget.carSize;
    return SizedBox(
      width: widget.width,
      height: widget.carSize + 14,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 2,
            width: widget.width,
            child: ModernDesignSystem.roadDivider(height: 4, color: color.withOpacity(0.25)),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final dx = Curves.easeInOut.transform(_controller.value) * travel;
              return Positioned(
                left: dx,
                bottom: 8,
                child: child!,
              );
            },
            child: SizedBox(
              width: widget.carSize,
              height: widget.carSize * 0.55,
              child: Image.asset(
                CarAssets.muscleCarLineArt,
                fit: BoxFit.contain,
                color: color,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (context, error, stackTrace) =>
                    CustomPaint(painter: CarSilhouettePainter(color: color)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
