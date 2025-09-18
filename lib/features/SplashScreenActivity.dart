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
import 'home_module/data_manager/home_data_manager.dart';
import 'log_in/ui/LoginActivity.dart';

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
    print("Under Splash start Screen ");
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersionCode = packageInfo.buildNumber;
    appVersionName = packageInfo.version;
    print("appVersionCode:-$appVersionCode");
    print("appVersionName:-$appVersionName");
    print("Under Splash start Screen ");
    setState(() {
      userid = sharedPreferences!.getString(Constant.id) ?? "";
      venderId = sharedPreferences!.getString(Constant.vendorId) ?? "";

    });
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
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/first_image.png'),
              fit: BoxFit.cover)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          padding: const EdgeInsets.fromLTRB(15, 30, 15, 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // if(userid == "" || userid == null  || venderId != "" || venderId != null)
              // GestureDetector(
              //     onTap: () {
              //       FocusManager.instance.primaryFocus?.unfocus();
              //       Navigator.pushAndRemoveUntil(
              //         context,
              //         MaterialPageRoute(
              //           //builder: (BuildContext context) => DashboardActivity(data:data),
              //           builder: (BuildContext context) => LoginActivity("Login"),
              //         ),
              //             (route) => false,
              //       );
              //     },
              //     child: Container(
              //       margin: EdgeInsets.only(left: 30, right: 30),
              //       child: CommonWidget.getGradinetButton(
              //           "Sign in",
              //           startcolor: 0xff006538,
              //           endcolor: 0xff006538,
              //           height: 40
              //       ),
              //     )),
              // if(userid == "" || userid == null|| venderId != "" || venderId != null)
              // SizedBox(height: 20,),
              if(userid == "" || userid == null|| venderId != "" || venderId != null)
              GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        //builder: (BuildContext context) => DashboardActivity(data:data),
                        builder: (BuildContext context) => LoginActivity("Get Started"),
                      ),
                          (route) => false,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 30, right: 30),
                    child: CommonWidget.getGradinetButton(
                        "Get Started",
                        startcolor: 0xffE8F7F1,
                        endcolor: 0xffE8F7F1,
                        textColor: 0xff1CA669,
                        height: 40
                    ),
                  )),
              if(userid == "" || userid == null|| venderId != "" || venderId != null)
              const SizedBox(height: 120,)
            ],
          ),

        ),
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
        Future.delayed(const Duration(milliseconds: 100), () {
          if (userid != null && userid != "") {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                //builder: (BuildContext context) => DashboardActivity(data:data),
                //builder: (BuildContext context) => DashboardActivity(),
                builder: (BuildContext context) => const DashboardActivity(),
              ),
                  (route) => false,
            );
          }
        });
      }
    } else if (!kIsWeb) {
      if (double.parse(appVersionName) < double.parse(data.ios!.name!)) {
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
        Future.delayed(const Duration(milliseconds: 100), () {
          if (userid != null && userid != "") {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                //builder: (BuildContext context) => DashboardActivity(data:data),
                //builder: (BuildContext context) => DashboardActivity(),
                builder: (BuildContext context) => const DashboardActivity(),
              ),
                  (route) => false,
            );
          }
        });
      }
    } else if (kIsWeb) {
      // For web, just navigate to dashboard after a delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (userid != null && userid != "") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const DashboardActivity(),
            ),
            (route) => false,
          );
        }
      });
    }
  }

}
