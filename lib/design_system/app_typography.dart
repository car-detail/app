import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Text-style tokens built on the Poppins family already bundled in
/// pubspec.yaml (PopReg/Pop400/Pop500/Pop600/Pop700/Popbold), so this
/// doesn't introduce a second font system alongside the existing one.
class AppTypography {
  AppTypography._();

  static const _base = TextStyle(color: AppColors.textPrimary);

  static final displayLarge = _base.copyWith(
    fontFamily: 'Popbold',
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static final headline = _base.copyWith(
    fontFamily: 'Pop700',
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static final title = _base.copyWith(
    fontFamily: 'Pop600',
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static final body = _base.copyWith(
    fontFamily: 'Pop400',
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static final bodyMedium = _base.copyWith(
    fontFamily: 'Pop500',
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static final caption = _base.copyWith(
    fontFamily: 'PopReg',
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static final button = const TextStyle(
    fontFamily: 'Pop600',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
