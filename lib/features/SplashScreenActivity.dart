import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;


import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:car_app/features/version_model_bean.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Common/CommonWidget.dart';
import '../Common/Constant.dart';
import '../Common/Color.dart';
import '../design_system/components/car_wash_icon.dart';
import '../design_system/car_assets.dart';
import 'home_module/data_manager/home_data_manager.dart';
import 'log_in/ui/new_login_activity.dart';
import 'log_in/data_manager/LoginDataManager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SplashScreenActivity extends StatefulWidget {
  const SplashScreenActivity({super.key});

  @override
  State<SplashScreenActivity> createState() => _SplashScreenActivityState();
}

class _SplashScreenActivityState extends State<SplashScreenActivity>
    with SingleTickerProviderStateMixin {
  SharedPreferences? sharedPreferences;
  String? userid;
  String? venderId;
  HomeDataManager? dataManager;
  String appVersionCode = "";
  String appVersionName = "";
  @override
  void initState() {
    start();
    super.initState();
  }
  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = HomeDataManager(sharedPreferences!);
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersionCode = packageInfo.buildNumber;
    appVersionName = packageInfo.version;

    // Initialize Firebase Messaging and get token
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Request permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      print('User granted permission: ${settings.authorizationStatus}');

      // Get Token
      if (Platform.isIOS) {
        String? apnsToken = await messaging.getAPNSToken();
        print("🔔 iOS APNS Token: $apnsToken");
        if (apnsToken == null) {
          print("⚠️ APNS token is null. FCM registration might fail. Ensure Push Notifications capability is added in Xcode.");
        }
      }

      String? token = await messaging.getToken();
      print("🔔 FCM Token: $token");

      if (token != null) {
        sharedPreferences!.setString(Constant.fbtoken, token);
      } else {
        print("❌ FCM Token is null!");
      }

      // Listen to token refresh
      messaging.onTokenRefresh.listen((fcmToken) {
        sharedPreferences!.setString(Constant.fbtoken, fcmToken);
      }).onError((err) {
        print("Error getting token refresh");
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          if (context.mounted) {
            CommonWidget.successShowSnackBarFor(context, "${message.notification?.title}: ${message.notification?.body}");
          }
        }
      });

      // Handle message when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from a background notification!');
        // Navigation logic can go here if needed
      });

      // Handle message when app is opened from terminated state
      messaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          print('App opened from a terminated notification!');
          // Navigation logic can go here if needed
        }
      });
      
    } catch (e) {
      print("Error in Firebase Messaging init: $e");
    }
    
    final userIdValue = sharedPreferences!.getString(Constant.id) ?? "";
    final vendorIdValue = sharedPreferences!.getString(Constant.vendorId) ?? "";
    final accessTokenValue = sharedPreferences!.getString(Constant.accessToken) ?? "";
    
    print("=== SPLASH SCREEN DEBUG ===");
    print("User ID from storage: '$userIdValue'");
    print("Vendor ID from storage: '$vendorIdValue'");
    print("Access Token from storage: ${accessTokenValue.isNotEmpty ? '${accessTokenValue.substring(0, 20)}...' : 'empty'}");
    print("User ID is empty: ${userIdValue.isEmpty}");
    print("===========================");
    
    setState(() {
      userid = userIdValue;
      venderId = vendorIdValue;
    });
    
    // Check if user is logged in - navigate immediately if yes
    if (userIdValue.isNotEmpty) {
      // Sync FCM token with backend in background
      try {
        final loginDataManager = LoginDataManager(sharedPreferences!);
        await loginDataManager.syncFcmToken(context);
      } catch (e) {
        print("Error syncing FCM token: $e");
      }

      // Small delay for splash screen visibility, then navigate
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const DashboardActivity(),
            ),
            (route) => false,
          );
        }
      });
      return; // Don't show login buttons or check version if user is logged in
    }
    
    // Only check version and show login screen if user is NOT logged in
    getForceVersion(context);
    // Future.delayed(const Duration(milliseconds: 1000), () {
    //    if (userid != null && userid != "" && venderId != "" && venderId != null) {
    //     Navigator.pushAndRemoveUntil(
    //       context,
    //       MaterialPageRoute(
    //         //builder: (BuildContext context) => DashboardActivity(data:data),
    //         //builder: (BuildContext context) => DashboardActivity(),
    //         builder: (BuildContext context) => DashboardActivity(),
    //       ),
    //           (route) => false,
    //     );
    //   } /*else {
    //     Navigator.pushAndRemoveUntil(
    //       context,
    //       MaterialPageRoute(
    //         //builder: (BuildContext context) => DashboardActivity(data:data),
    //         builder: (BuildContext context) => LoginActivity("Login"),
    //       ),
    //           (route) => false,
    //     );
    //   }*/
    // });
  }

  @override
  Widget build(BuildContext context) {
    final loggedOut = userid == null || userid!.isEmpty;
    return Scaffold(
      backgroundColor: ColorClass.dark_bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Illustration blob
            Expanded(
              flex: 5,
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(28),
                      child: Image.asset(
                        CarAssets.carWashHose,
                        fit: BoxFit.contain,
                        color: ColorClass.base_color,
                        colorBlendMode: BlendMode.srcIn,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: CarWashIcon(size: 170, color: ColorClass.base_color),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Pagination dots (decorative)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dot(false),
                _dot(true),
                _dot(false),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Cahrz for Vendors",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Manage your car wash business, bookings and offers all in one place.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.4),
              ),
            ),
            const Spacer(),
            if (loggedOut)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => NewLoginActivity(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF0D1526), Color(0xFF192028), Color(0xFF3F5A85)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF192028).withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Get Started",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 20 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
  getForceVersion(BuildContext context) async {
    var response = await dataManager!.getForceUpdate(context);
    var data = VersionModelBean.fromJson(jsonDecode(response.body));

    if (!kIsWeb && Platform.isAndroid) {
      if (3 < int.parse(data.android!.code!)) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Update Required'),
              content: const Text(
                  'A new version of the app is available. Please update to continue.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Update Now'),
                  onPressed: () async {
                    if (await canLaunchUrl(Uri.parse(
                        "https://play.google.com/store/apps/details?id=com.car.carAdmin"))) {
                      await launchUrl(Uri.parse(
                          "https://play.google.com/store/apps/details?id=com.car.carAdminr"));
                    }
                  },
                ),
              ],
            );
          },
          barrierDismissible: false, // This is key to forcing the update
        );
      } else {
        // Only navigate if user is logged in and not already navigated
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && context.mounted && (userid == null || userid!.isEmpty)) {
            // User is not logged in, stay on splash screen (buttons already shown)
            // Don't navigate - let user choose sign in or sign up
          }
        });
      }
    } else if (!kIsWeb) {
      // Compare semantic versions properly
      if (_compareVersions(appVersionName, data.ios!.name ?? "0.0.0") < 0) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Update Required'),
              content: const Text(
                  'A new version of the app is available. Please update to continue.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Update Now'),
                  onPressed: () async {
                    if (await canLaunchUrl(
                        Uri.parse("https://apps.apple.com/app/id6749635800"))) {
                      await launchUrl(
                          Uri.parse("https://apps.apple.com/app/id6749635800"));
                    }
                  },
                ),
              ],
            );
          },
          barrierDismissible: false, // This is key to forcing the update
        );
      } else {
        // Only navigate if user is logged in and not already navigated
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && context.mounted && (userid == null || userid!.isEmpty)) {
            // User is not logged in, stay on splash screen (buttons already shown)
            // Don't navigate - let user choose sign in or sign up
          }
        });
      }
    } else if (kIsWeb) {
      // For web, only navigate if user is logged in and not already navigated
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && context.mounted && (userid == null || userid == "" || userid!.isEmpty)) {
          // User is not logged in, stay on splash screen (buttons already shown)
          // Don't navigate - let user choose sign in or sign up
        }
      });
    }
  }

  // Helper function to compare semantic versions (e.g., "1.6.0" vs "1.0.0")
  // Returns: -1 if version1 < version2, 0 if equal, 1 if version1 > version2
  int _compareVersions(String version1, String version2) {
    try {
      List<int> v1Parts = version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> v2Parts = version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      
      // Pad shorter version with zeros
      while (v1Parts.length < v2Parts.length) {
        v1Parts.add(0);
      }
      while (v2Parts.length < v1Parts.length) {
        v2Parts.add(0);
      }
      
      for (int i = 0; i < v1Parts.length; i++) {
        if (v1Parts[i] < v2Parts[i]) return -1;
        if (v1Parts[i] > v2Parts[i]) return 1;
      }
      return 0;
    } catch (e) {
      return 0; // If comparison fails, assume versions are equal
    }
  }

}
