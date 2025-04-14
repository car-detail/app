import 'dart:convert';
import 'dart:io';

import 'package:car_app/Api/ApiFuntion.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constants.dart';
import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:car_app/features/log_in/model/user_detail_model_bean.dart';
import 'package:car_app/features/log_in/ui/edit_user_details_activity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Common/Color.dart';
import '../../../Common/Constant.dart';
import '../data_manager/LoginDataManager.dart';
import '../model/GenerateOTPModelBean.dart';
import '../model/VerifyOtpModelBean.dart';
import '../model/vendor_details_bean.dart';

class OTPScreenActivity extends StatefulWidget {
  GenerateOTPModelBean data;
  String mobileNo;

  OTPScreenActivity(this.data, this.mobileNo, {super.key});

  @override
  State<OTPScreenActivity> createState() => _OTPScreenActivityState();
}

class _OTPScreenActivityState extends State<OTPScreenActivity> {
  final TextEditingController _fieldOne = TextEditingController();
  final TextEditingController _fieldTwo = TextEditingController();
  final TextEditingController _fieldThree = TextEditingController();
  final TextEditingController _fieldFour = TextEditingController();
  final TextEditingController _fieldFive = TextEditingController();
  final TextEditingController _fieldSix = TextEditingController();

  ApiFuntions apiFuntions = ApiFuntions();
  LoginDataManager? loginDataManager;
  late SharedPreferences? sharedPreferences;
  final bool _isPasswordVisible = false;
  int maxLength = 10;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    loginDataManager = LoginDataManager(sharedPreferences!);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(true);
        return false; // Prevent the default back button action
      },
      child: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/login_image.png'),
                fit: BoxFit.cover)),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            margin: Platform.isAndroid
                ? EdgeInsets.only(top: 260)
                : EdgeInsets.only(top: 310),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //Image(image: AssetImage('assets/images/login_image.png')),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          CommonWidget.getTextWidget500(
                              "Sms verification code has been sent to your Register Mobile No.",
                              size: 16),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                // Navigator.pop(context);
                              },
                              child: RichText(
                                text: const TextSpan(
                                    text: "OTP not received? ",
                                    style: TextStyle(
                                        fontFamily: "Pop400",
                                        color: Colors.black,
                                        fontSize: 15),
                                    children: [
                                      TextSpan(
                                        text: "Resend",
                                        style: TextStyle(
                                            fontFamily: "Pop600",
                                            color: Color(0xff0E3AA6),
                                            fontSize: 15),
                                      ),
                                    ]),
                              ),
                            ),
                          ),
                          Container(
                              margin: const EdgeInsets.only(left: 10, top: 20),
                              child:
                                  CommonWidget.getTextWidget500("Enter OTP")),
                          const SizedBox(height: 20),
                          Pinput(
                            controller: _fieldOne,
                            length: 6,
                            keyboardType: TextInputType.number,
                            defaultPinTheme: PinTheme(
                              width: 56,
                              height: 56,
                              textStyle: TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              /*Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ResetPasswordActivity()),
                                );*/
                            },
                            child: Container(
                              margin: const EdgeInsets.only(top: 30),
                              child: GestureDetector(
                                onTap: () {
                                  if (_fieldOne.length == 6) {
                                    postOTP(context);
                                  } else {
                                    //Navigator.pop(context); //for testing
                                    CommonWidget.errorShowSnackBarFor(
                                        context, "Please Enter the valid OTP");
                                  }
                                },
                                child: CommonWidget.getGradinetButton("Verify",
                                    startcolor: 0xff1CA669,
                                    endcolor: 0xff1CA669,
                                    height: 40),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  postOTP(BuildContext context) async {
    var response = await loginDataManager!.postOTP(
        _fieldOne.text,
        widget.data.data!.details ?? "",
        widget.mobileNo,
        context);
    var data = VerifyOtpModelBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      //loginDataManager!.setDataInShared(data.data!);
      sharedPreferences!
          .setString(Constant.accessToken, data.data!.accessToken ?? "");
      sharedPreferences!
          .setString(Constant.refreshToken, data.data!.refreshToken ?? "");
      sharedPreferences!.setString(Constant.refreshTokenExpireTime,
          data.data!.refreshTokenExpireTime.toString() ?? "");
      //CommonWidget.successShowSnackBarFor(context, data.message.toString());
      getUser(context);
      //CommonWidget.navigateToScreen(context, OTPScreenActivity());
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  getUser(BuildContext context) async {
    var response = await loginDataManager!.getUserDetails(context);
    var data = VendorDetailBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      sharedPreferences!
          .setString(Constant.firstName, data.data?[0].firstName ?? "");
      sharedPreferences!
          .setString(Constant.lastName, data.data?[0].lastName ?? "");
      sharedPreferences!.setString(Constant.email, data.data?[0].email ?? "");
      /*sharedPreferences!.setString(Constant.isEmailVerified,
          data.data?[0].isEmailVerified.toString() ?? "");*/
      sharedPreferences!.setString(Constant.mobile, data.data?[0].mobile ?? "");
      sharedPreferences!
          .setString(Constant.isNewUser, data.data?[0].isNewUser.toString() ?? "");
      sharedPreferences!
          .setString(Constant.roleName, data.data?[0].roleName ?? "");
      sharedPreferences!
          .setString(Constant.id, data.data?[0].sId.toString() ?? "");
      if(data.data![0].vendorDetails!.isNotEmpty)
      sharedPreferences!
          .setString(Constant.vendorId, data.data?[0].vendorDetails![0].sId.toString() ?? "");
      if (data.data?[0].isNewUser == true) {
        CommonWidget.navigateToScreen(context, EditUserDetailsActivity("otp"));
      } else {
        CommonWidget.navigateToKillAllScreen(context, DashboardActivity());
      }
      //CommonWidget.navigateToScreen(context, OTPScreenActivity());
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
}

class OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final bool autoFocus;
  final String type;

  const OtpInput(this.controller, this.autoFocus, this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 50,
      child: TextField(
        autofocus: autoFocus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        controller: controller,
        maxLength: 1,
        cursorColor: Colors.purple,
        decoration: InputDecoration(
            focusColor: Colors.purple,
            hintText: "*",
            hintFadeDuration: Duration.zero,
            focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                borderSide: BorderSide(
                    color: ColorClass.base_color,
                    width: 1,
                    style: BorderStyle.solid)),
            enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                borderSide: BorderSide(
                    color: Color(0xffdedede),
                    width: 1,
                    style: BorderStyle.solid)),
            counterText: '',
            hintStyle: const TextStyle(color: Colors.black, fontSize: 20.0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                borderSide: BorderSide(color: Color(0xffdedede)))),
        onChanged: (value) {
          if (value.length == 1 && type != "six") {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && type != "one") {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }
}
