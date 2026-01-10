import 'package:flutter/material.dart';
import 'Color.dart';

/// Modern Design System for jaw-dropping minimal UI
class ModernDesignSystem {
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusRound = 999.0;

  // Shadows - Modern, soft shadows
  static List<BoxShadow> get shadowSmall => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowLarge => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowXLarge => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];

  // Colored shadows for cards
  static List<BoxShadow> getColoredShadow(Color color, {double opacity = 0.15}) => [
        BoxShadow(
          color: color.withOpacity(opacity),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: color.withOpacity(opacity * 0.5),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ];

  // Modern Card Decoration
  static BoxDecoration modernCard({
    Color? color,
    double? borderRadius,
    List<BoxShadow>? shadows,
    Border? border,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(borderRadius ?? radiusL),
      boxShadow: shadows ?? shadowMedium,
      border: border,
      gradient: gradient,
    );
  }

  // Glassmorphism effect
  static BoxDecoration glassmorphism({
    double opacity = 0.1,
    double blur = 10.0,
    Color? color,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withOpacity(opacity),
      borderRadius: BorderRadius.circular(radiusL),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: blur,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Modern Button Style
  static ButtonStyle modernButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? ColorClass.base_color,
      foregroundColor: foregroundColor ?? Colors.white,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? radiusM),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
    );
  }

  // Text Styles
  static TextStyle heading1({Color? color}) {
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      color: color ?? Colors.black87,
      height: 1.2,
    );
  }

  static TextStyle heading2({Color? color}) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.3,
      color: color ?? Colors.black87,
      height: 1.3,
    );
  }

  static TextStyle heading3({Color? color}) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: color ?? Colors.black87,
      height: 1.4,
    );
  }

  static TextStyle bodyLarge({Color? color}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color ?? Colors.black87,
      height: 1.5,
    );
  }

  static TextStyle bodyMedium({Color? color}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color ?? Colors.black87,
      height: 1.5,
    );
  }

  static TextStyle bodySmall({Color? color}) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color ?? Colors.grey[600],
      height: 1.4,
    );
  }

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Animation Curves
  static const Curve animationCurve = Curves.easeOutCubic;
  static const Curve springCurve = Curves.easeOutBack;
}







