import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:car_app/Api/ApiFuntion.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constants.dart';
import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:car_app/features/log_in/model/user_detail_model_bean.dart';
import 'package:car_app/features/log_in/ui/edit_user_details_activity.dart';
import 'package:car_app/features/resister_vendor_model/ui/simple_add_shop_activity.dart';
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
  
  // Resend OTP timer
  int _resendTimer = 60; // 60 seconds countdown
  bool _canResend = false;
  bool _isVerifying = false; // Loading state for verify button
  Timer? _timer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    init();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void init() async {
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    loginDataManager = LoginDataManager(sharedPreferences!);
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isResending) return;

    setState(() {
      _isResending = true;
      // Clear OTP field when resending
      _fieldOne.clear();
    });

    try {
      await loginDataManager!.sendFirebaseOTP(
        widget.mobileNo,
        (String verificationId) {
          // OTP sent successfully
          setState(() {
            // Update the verification ID in widget.data
            widget.data.data?.details = verificationId;
            _isResending = false;
          });
          _startResendTimer(); // Restart the timer
          CommonWidget.successShowSnackBarFor(context, "OTP has been resent successfully");
        },
        (String error) {
          // Error sending OTP
          setState(() {
            _isResending = false;
          });
          CommonWidget.errorShowSnackBarFor(context, error);
        },
      );
    } catch (e) {
      setState(() {
        _isResending = false;
      });
      CommonWidget.errorShowSnackBarFor(context, "Failed to resend OTP. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        CommonWidget.safePop(context, result: true);
        return false; // Prevent the default back button action
      },
      child: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/login_image.png'),
            fit: BoxFit.cover,
          ),
        ),
      child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Spacer for background illustration
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                  ),
                  
                  // Main content card - White card with rounded top corners
                  Container(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    decoration: const BoxDecoration(
              color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
            child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                        // Back button - Styled with proper alignment
                        Align(
                          alignment: Alignment.centerLeft,
                          child: CommonWidget.buildBackButton(
                            context,
                            backgroundColor: Colors.white,
                            iconColor: Colors.black87,
                            iconSize: 20,
                            onPressed: () => CommonWidget.safePop(context),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // SMS verification message - Split into two lines as per design
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            text: "SMS verification code has been sent to your\n",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              fontFamily: "Pop400",
                            ),
                        children: [
                              TextSpan(
                                text: "Register Mobile No.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: "Pop500",
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Resend OTP - Proper spacing
                          Center(
                          child: _canResend
                              ? GestureDetector(
                                  onTap: _isResending ? null : _resendOTP,
                              child: RichText(
                                    text: TextSpan(
                                      text: "OTP not received? ",
                                      style: const TextStyle(
                                        fontFamily: "Pop400",
                                        color: Colors.black87,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: _isResending ? "Resending..." : "Resend",
                                          style: TextStyle(
                                            fontFamily: "Pop600",
                                            color: _isResending 
                                                ? Colors.grey 
                                                : ColorClass.base_color,
                                            fontSize: 14,
                                            decoration: _isResending 
                                                ? TextDecoration.none 
                                                : TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : RichText(
                                  text: TextSpan(
                                    text: "OTP not received? ",
                                    style: const TextStyle(
                                        fontFamily: "Pop400",
                                      color: Colors.black87,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: "Resend in ${_resendTimer}s",
                                        style: TextStyle(
                                            fontFamily: "Pop600",
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 32),
                        
                        // Enter OTP label
                        const Text(
                          "Enter OTP",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            fontFamily: "Pop600",
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // OTP Input - Centered with proper spacing
                        Center(
                          child: Pinput(
                            controller: _fieldOne,
                            length: 6,
                            keyboardType: TextInputType.number,
                            defaultPinTheme: PinTheme(
                              width: 50,
                              height: 56,
                              textStyle: const TextStyle(
                                fontSize: 22,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: ColorClass.base_color, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            focusedPinTheme: PinTheme(
                              width: 50,
                              height: 56,
                              textStyle: const TextStyle(
                                fontSize: 22,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: ColorClass.base_color, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            submittedPinTheme: PinTheme(
                              width: 50,
                              height: 56,
                              textStyle: const TextStyle(
                                fontSize: 22,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: ColorClass.base_color, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Verify Button - Full width green button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isVerifying ? null : () {
                              if (_fieldOne.text.toString().length == 6) {
                                    postOTP(context);
                                  } else {
                                    CommonWidget.errorShowSnackBarFor(
                                        context, "Please Enter the valid OTP");
                                  }
                                },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorClass.base_color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              disabledBackgroundColor: ColorClass.base_color.withOpacity(0.6),
                            ),
                            child: _isVerifying
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    "Verify",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        ],
                    ),
                  ),
                ],
                ),
            ),
          ),
        ),
      ),
    );
  }

  postOTP(BuildContext context) async {
    if (_isVerifying) return; // Prevent multiple calls
    
    setState(() {
      _isVerifying = true;
    });
    
    try {
      
      // Get verificationId from widget.data.data?.details
      String verificationId = widget.data.data?.details ?? "";
      
      
      if (verificationId.isEmpty) {
        setState(() {
          _isVerifying = false;
        });
        CommonWidget.errorShowSnackBarFor(context, "Invalid verification ID. Please try again.");
        return;
      }
      
      if (_fieldOne.text.length != 6) {
        setState(() {
          _isVerifying = false;
        });
        CommonWidget.errorShowSnackBarFor(context, "Please enter a valid 6-digit OTP.");
        return;
      }
      
      var response = await loginDataManager!.postOTP(
          _fieldOne.text,
          verificationId, // Pass verificationId instead of sessionId
          widget.mobileNo,
          context);
      
      
      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        setState(() {
          _isVerifying = false;
        });
        CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        return;
      }
      
      var data = VerifyOtpModelBean.fromJson(jsonDecode(response.body));
      
      if (data.status == "success") {
        sharedPreferences!
            .setString(Constant.accessToken, data.data!.accessToken ?? "");
        sharedPreferences!
            .setString(Constant.refreshToken, data.data!.refreshToken ?? "");
        sharedPreferences!.setString(Constant.refreshTokenExpireTime,
            data.data!.refreshTokenExpireTime.toString() ?? "");
        setState(() {
          _isVerifying = false;
        });
        getUser(context);
      } else {
        setState(() {
          _isVerifying = false;
        });
        // Check if the error message indicates invalid OTP
        String errorMessage = data.message ?? "";
        if (errorMessage.toLowerCase().contains("invalid") || 
            errorMessage.toLowerCase().contains("incorrect") ||
            errorMessage.toLowerCase().contains("wrong") ||
            errorMessage.toLowerCase().contains("expired") ||
            errorMessage.toLowerCase().contains("code") && errorMessage.toLowerCase().contains("expired")) {
          CommonWidget.errorShowSnackBarFor(context, "Invalid OTP. Please check and try again.");
        } else if (errorMessage.isNotEmpty) {
          CommonWidget.errorShowSnackBarFor(context, errorMessage);
        } else {
          CommonWidget.errorShowSnackBarFor(context, "Invalid OTP. Please check and try again.");
        }
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      CommonWidget.errorShowSnackBarFor(context, "OTP verification failed: ${e.toString()}");
    }
  }

  getUser(BuildContext context) async {
    var response = await loginDataManager!.getUserDetails(context);
    
    // Check if response is HTML (error page) instead of JSON
    if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
      CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
      return;
    }
    
    try {
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
      
      // Debug vendor details
      bool hasVendorDetails = data.data?[0].vendorDetails != null && data.data![0].vendorDetails!.isNotEmpty;
      bool isVendorRole = data.data?[0].roleName?.toLowerCase() == "vendor" || 
                          data.data?[0].roleName?.toLowerCase() == "vendors";
      
      if(hasVendorDetails) {
        sharedPreferences!
          .setString(Constant.vendorId, data.data?[0].vendorDetails![0].sId.toString() ?? "");
      } else {
      }
      
      if (data.data?[0].isNewUser == true) {
        // For vendors, skip profile details and go directly to shop creation
        // Only navigate to shop creation if they are a vendor AND don't have vendor details yet
        if (isVendorRole && !hasVendorDetails) {
          CommonWidget.navigateToKillAllScreen(context, const SimpleAddShopActivity());
        } else if (isVendorRole && hasVendorDetails) {
          // Vendor with existing shop - should not be new user, but handle gracefully
          CommonWidget.navigateToKillAllScreen(context, const DashboardActivity());
        } else {
          // Regular user - show profile details
          CommonWidget.navigateToScreen(context, EditUserDetailsActivity("otp"));
        }
      } else {
        // Existing user - always go to dashboard
        CommonWidget.navigateToKillAllScreen(context, const DashboardActivity());
      }
      //CommonWidget.navigateToScreen(context, OTPScreenActivity());
      } else {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      }
    } catch (e) {
      CommonWidget.errorShowSnackBarFor(context, "Error parsing user details. Please try again.");
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
            border: const OutlineInputBorder(
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
