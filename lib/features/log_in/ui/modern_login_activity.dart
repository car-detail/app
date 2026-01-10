import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:car_app/features/SplashScreenActivity.dart';
import 'package:car_app/features/log_in/ui/iotp_screen_activity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
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

/// Modern, consistent login screen for vendor app
class ModernLoginActivity extends StatefulWidget {
  final bool isSignUp;
  
  const ModernLoginActivity({super.key, this.isSignUp = false});

  @override
  State<ModernLoginActivity> createState() => _ModernLoginActivityState();
}

class _ModernLoginActivityState extends State<ModernLoginActivity> {
  var mobileController = TextEditingController();
  ApiFuntions apiFuntions = ApiFuntions();
  LoginDataManager? loginDataManager;
  late SharedPreferences? sharedPreferences;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    loginDataManager = LoginDataManager(sharedPreferences!);
    
    try {
      if (kIsWeb) {
        sharedPreferences!.setString(Constant.location, "Web Location");
        sharedPreferences!.setString(Constant.lat, "0.0");
        sharedPreferences!.setString(Constant.long, "0.0");
        return;
      }
      
      var possition = await _determinePosition();
      List<Placemark> placemarks =
          await placemarkFromCoordinates(possition.latitude, possition.longitude);
      sharedPreferences!
          .setString(Constant.location, placemarks[0].locality ?? "");
      sharedPreferences!
          .setString(Constant.lat, possition.latitude.toString());
      sharedPreferences!
          .setString(Constant.long, possition.longitude.toString());
    } catch (e) {
      print("Error getting location: $e");
      sharedPreferences!.setString(Constant.location, "Unknown Location");
      sharedPreferences!.setString(Constant.lat, "0.0");
      sharedPreferences!.setString(Constant.long, "0.0");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          CommonWidget.safePop(context);
          return false;
        }
        // If no route to pop, navigate to splash screen
        CommonWidget.navigateToKillAllScreen(context, const SplashScreenActivity());
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Modern Header with gradient
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorClass.base_color,
                        ColorClass.base_color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            // Back button
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  CommonWidget.safePop(context);
                                } else {
                                  // If no route to pop, navigate to splash screen
                                  CommonWidget.navigateToKillAllScreen(
                                      context, const SplashScreenActivity());
                                }
                              },
                            ),
                          const Spacer(),
                          // Title
                          Text(
                            widget.isSignUp ? "Create Account" : "Welcome Back",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isSignUp
                                ? "Start your business journey with us"
                                : "Sign in to continue to your account",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Login Form
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Mobile Number Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter mobile number",
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.phone_android,
                            color: ColorClass.base_color,
                            size: 24,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Generate OTP Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleGenerateOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorClass.base_color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              "Generate OTP",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Info text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "We'll send you a verification code",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _handleGenerateOTP() {
    if (BaseActivity.checkEmptyField(
        editingController: mobileController,
        message: "Please Enter Mobile Number",
        context: context)) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    postLogin();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }

  postLogin() async {
    try {
      var response =
          await loginDataManager!.postlogin(mobileController.text, context);
      var data = GenerateOTPModelBean.fromJson(jsonDecode(response.body));
      
      setState(() {
        _isLoading = false;
      });
      
      if (data.status == "success") {
        CommonWidget.navigateToScreen(
            context, OTPScreenActivity(data, mobileController.text));
      } else {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      CommonWidget.errorShowSnackBarFor(context, "Something went wrong. Please try again.");
    }
  }
}

