import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// import 'package:bot_toast/bot_toast.dart';
import 'features/SplashScreenActivity.dart';
import 'features/dashboard_module/ui/dashboard_activity.dart';
import 'features/onboarding/ui/vendor_onboarding_activity.dart';
import 'features/resister_vendor_model/ui/simple_registor_vendor_activity.dart';
import 'Common/Color.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set global status bar style to green - called before build
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
        primarySwatch: Colors.blue,
        // fontFamily: 'PopReg',
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
        '/register': (context) => const SafeArea(child: SimpleRegistorVendorActivity()),
      },
      // builder: BotToast.init(),
      // navigatorObservers: [BotToastNavigatorObserver()],
      builder: (context, child) {
        // Wrap with error boundary to prevent black screens
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child ?? const SizedBox(),
        );
      },
      ),
    );
  }
}


