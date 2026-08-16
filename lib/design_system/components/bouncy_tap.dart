import 'package:flutter/material.dart';

/// Wraps any widget with a tactile scale-down-on-press animation.
/// Buttons that just fire onPressed with zero visual feedback are a big
/// part of why a screen reads as "static" instead of "interactive" — this
/// is the cheapest fix with the highest felt impact.
class BouncyTap extends StatefulWidget {
  const BouncyTap({super.key, required this.child, required this.onTap, this.scale = 0.95});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
