import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:car_app/features/log_in/ui/iotp_screen_activity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Api/ApiFuntion.dart';
import '../../../Common/BaseActivity.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../data_manager/LoginDataManager.dart';
import '../model/GenerateOTPModelBean.dart';

class LoginActivity extends StatefulWidget {
  String title;

  LoginActivity(this.title, {super.key});

  @override
  State<LoginActivity> createState() => _LoginActivityState();
}

class _LoginActivityState extends State<LoginActivity> {
  var mobileController = TextEditingController();

  ApiFuntions apiFuntions = ApiFuntions();
  LoginDataManager? loginDataManager;
  late SharedPreferences? sharedPreferences;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    loginDataManager = LoginDataManager(sharedPreferences!);
    var possition = await _determinePosition();
    print(
        "============================================================= ${possition.toString()}");
    List<Placemark> placemarks =
        await placemarkFromCoordinates(possition.latitude, possition.longitude);
    print("========================= ${placemarks?[0].locality}");
    sharedPreferences!
        .setString(Constant.location, placemarks?[0].locality ?? "");
    sharedPreferences!
        .setString(Constant.lat, possition.latitude.toString());
    sharedPreferences!
        .setString(Constant.long, possition.longitude.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/login_image.png'),
              fit: BoxFit.cover)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          margin: Platform.isIOS
              ? EdgeInsets.only(top: 320)
              : EdgeInsets.only(top: 250),
          child: Column(
            children: [
              //Image(image: AssetImage('assets/images/login_image.png')),
              Expanded(
                  child: Container(
                margin: EdgeInsets.only(left: 20, right: 20),
                child: SingleChildScrollView(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CommonWidget.getTextWidgetTitle(widget.title,
                            color: ColorClass.base_color, textsize: 22),
                        CommonWidget.getTextWidgetSubTitle(
                            "Enter your mobile number to login",
                            color: ColorClass.middel_gray_base,
                            textsize: 14),
                        SizedBox(
                          height: 10,
                        ),
                        CommonWidget.getTextFieldWithgrayboderWithIcon(
                            "Enter mobile number",
                            "mobile_phone_rect",
                            mobileController,
                            keytype: TextInputType.phone),
                        SizedBox(
                          height: 20,
                        ),
                        GestureDetector(
                            onTap: () {
                              //FocusManager.instance.primaryFocus?.unfocus();
                              if (BaseActivity.checkEmptyField(
                                  editingController: mobileController,
                                  message: "Please Enter Mobile Number",
                                  context: context)) {
                                return;
                              } else {
                                postLogin();
                              }
                            },
                            child: Container(
                              child: CommonWidget.getGradinetButton(
                                  "Generate OTP",
                                  startcolor: 0xff1CA669,
                                  endcolor: 0xff1CA669,
                                  height: 40),
                            )),
                      ]),
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    /*if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }*/

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        permission = await Geolocator.requestPermission();
//        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  postLogin() async {
    var response =
        await loginDataManager!.postlogin(mobileController.text, context);
    var data = GenerateOTPModelBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      //loginDataManager!.setDataInShared(data.data!);
      //CommonWidget.successShowSnackBarFor(context, data.message.toString());
      CommonWidget.navigateToScreen(
          context, OTPScreenActivity(data, mobileController.text));
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
}
