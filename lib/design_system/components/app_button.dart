import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

enum AppButtonVariant { primary, secondary, danger }

/// Standard full-width button used across onboarding, booking, and
/// management screens, so button style/height/loading-state stop being
/// reimplemented per-screen.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  Color get _background {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.surface;
      case AppButtonVariant.danger:
        return AppColors.error;
    }
  }

  Color get _foreground {
    return variant == AppButtonVariant.secondary
        ? AppColors.textPrimary
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _background,
          disabledBackgroundColor: _background.withOpacity(0.5),
          elevation: variant == AppButtonVariant.secondary ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: variant == AppButtonVariant.secondary
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _foreground,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: _foreground),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(label, style: AppTypography.button.copyWith(color: _foreground)),
                ],
              ),
      ),
    );
  }
}
