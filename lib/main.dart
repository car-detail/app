import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:car_app/Common/NotificationService.dart';
import 'package:bot_toast/bot_toast.dart';
import 'features/SplashScreenActivity.dart';
import 'features/dashboard_module/ui/dashboard_activity.dart';
import 'features/onboarding/ui/vendor_onboarding_activity.dart';
import 'features/log_in/ui/new_login_activity.dart';
import 'Common/Color.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background processing
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set the background messaging handler early on
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Show the UI immediately -- don't hold the native launch screen up
  // while a notification-permission dialog is pending. Give the engine
  // a beat to present its first frame before requesting anything.
  runApp(const ProviderScope(child: MyApp()));

  Future.delayed(const Duration(milliseconds: 1200), () {
    unawaited(NotificationService.initialize());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set global status bar style - called before build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: ColorClass.base_color,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: ColorClass.base_color,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    });
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Transparent so background shows through
        statusBarIconBrightness: Brightness.light, // White icons for visibility on green
        statusBarBrightness: Brightness.dark, // For iOS
        systemNavigationBarColor: ColorClass.base_color,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MaterialApp(
      title: 'Cahrz Vendor App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorClass.base_color),
        useMaterial3: true,
          appBarTheme: AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: ColorClass.base_color,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
          ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SafeArea(
        child: SplashScreenActivity(),
      ),
      routes: {
        '/dashboard': (context) => const SafeArea(child: DashboardActivity()),
        '/onboarding': (context) => const SafeArea(child: VendorOnboardingActivity()),
        '/login': (context) => const SafeArea(child: NewLoginActivity()),
      },
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      ),
    );
  }
}


