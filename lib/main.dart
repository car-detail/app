import 'package:flutter/material.dart';
// import 'package:bot_toast/bot_toast.dart';
import 'features/SplashScreenActivity.dart';
import 'features/dashboard_module/ui/dashboard_activity.dart';
import 'features/onboarding/ui/vendor_onboarding_activity.dart';
import 'features/resister_vendor_model/ui/simple_registor_vendor_activity.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cahrz Vendor App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // fontFamily: 'PopReg',
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
    );
  }
}


