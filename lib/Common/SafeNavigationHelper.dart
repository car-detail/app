import 'package:flutter/material.dart';

/// Helper class for safe navigation that prevents black screens
/// Use this instead of direct Navigator calls throughout the app
class SafeNavigationHelper {
  /// Safely pop the current route
  /// Checks if context is mounted and if navigation is possible
  static void safePop(BuildContext? context, {dynamic result}) {
    if (context == null || !context.mounted) {
      return;
    }
    
    try {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop(result);
      } else {
      }
    } catch (e) {
    }
  }

  /// Safely push a new route
  static Future<T?>? safePush<T extends Object?>(
    BuildContext? context,
    Widget screen,
  ) {
    if (context == null || !context.mounted) {
      return null;
    }

    try {
      return Navigator.of(context).push<T>(
        MaterialPageRoute(
          builder: (context) => screen,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Safely push and replace current route
  static Future<T?>? safePushReplacement<T extends Object?, TO extends Object?>(
    BuildContext? context,
    Widget screen, {
    TO? result,
  }) {
    if (context == null || !context.mounted) {
      return null;
    }

    try {
      return Navigator.of(context).pushReplacement<T, TO>(
        MaterialPageRoute(
          builder: (context) => screen,
        ),
        result: result,
      );
    } catch (e) {
      return null;
    }
  }

  /// Safely push and remove all previous routes
  static Future<T?>? safePushAndRemoveUntil<T extends Object?>(
    BuildContext? context,
    Widget screen,
    bool Function(Route<dynamic>) predicate,
  ) {
    if (context == null || !context.mounted) {
      return null;
    }

    try {
      return Navigator.of(context).pushAndRemoveUntil<T>(
        MaterialPageRoute(
          builder: (context) => screen,
        ),
        predicate,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if navigation is possible
  static bool canPop(BuildContext? context) {
    if (context == null || !context.mounted) {
      return false;
    }
    try {
      return Navigator.of(context).canPop();
    } catch (e) {
      return false;
    }
  }
}







