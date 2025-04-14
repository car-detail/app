import 'dart:async';


import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/CommonWidget.dart';
import '../Common/Constant.dart';
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

  @override
  void initState() {
    start();
    super.initState();
  }
  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    print("Under Splash start Screen ");
    setState(() {
      userid = sharedPreferences!.getString(Constant.id) ?? "";
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
       if (userid != null && userid != "") {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            //builder: (BuildContext context) => DashboardActivity(data:data),
            //builder: (BuildContext context) => DashboardActivity(),
            builder: (BuildContext context) => DashboardActivity(),
          ),
              (route) => false,
        );
      } /*else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            //builder: (BuildContext context) => DashboardActivity(data:data),
            builder: (BuildContext context) => LoginActivity("Login"),
          ),
              (route) => false,
        );
      }*/
    });
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
          padding: EdgeInsets.fromLTRB(15, 30, 15, 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if(userid == "" || userid == null)
              GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        //builder: (BuildContext context) => DashboardActivity(data:data),
                        builder: (BuildContext context) => LoginActivity("Login"),
                      ),
                          (route) => false,
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(left: 30, right: 30),
                    child: CommonWidget.getGradinetButton(
                        "Sign in",
                        startcolor: 0xff006538,
                        endcolor: 0xff006538,
                        height: 40
                    ),
                  )),
              if(userid == "" || userid == null)
              SizedBox(height: 20,),
              if(userid == "" || userid == null)
              GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        //builder: (BuildContext context) => DashboardActivity(data:data),
                        builder: (BuildContext context) => LoginActivity("Sign Up"),
                      ),
                          (route) => false,
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(left: 30, right: 30),
                    child: CommonWidget.getGradinetButton(
                        "Sign Up",
                        startcolor: 0xffE8F7F1,
                        endcolor: 0xffE8F7F1,
                        textColor: 0xff1CA669,
                        height: 40
                    ),
                  )),
              if(userid == "" || userid == null)
              SizedBox(height: 20,)
            ],
          ),

        ),
      ),
    );
  }
}
