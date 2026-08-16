import 'package:flutter/material.dart';

/// Design-system color tokens. Wraps the existing brand colors from
/// `Common/Color.dart` so new screens have one source of truth instead of
/// each screen picking its own `Colors.grey[...]` / `Colors.black87` shade.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xff192028);
  static const primaryLight = Color(0xffE6E7E9);
  static const secondary = Color(0xff3F51B5);

  // Semantic
  static const success = Color(0xff192028);
  static const warning = Color(0xffFFA000);
  static const error = Color(0xffC41618);
  static const info = Color(0xff008FF1);

  // Neutrals
  static const textPrimary = Color(0xff1A1A1A);
  static const textSecondary = Color(0xff6B6B6B);
  static const textDisabled = Color(0xff9D9E9E);

  static const surface = Colors.white;
  static const background = Color(0xffF6F6F6);
  static const border = Color(0xffEBECEC);
  static const divider = Color(0xffCACACA);
}
