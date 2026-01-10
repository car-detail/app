import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:car_app/features/log_in/model/user_detail_model_bean.dart';
import 'package:car_app/features/log_in/model/vendor_details_bean.dart';
import 'package:car_app/features/resister_vendor_model/ui/simple_add_shop_activity.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/BaseActivity.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Models/image_module_data.dart';
import '../data_manager/LoginDataManager.dart';

class EditUserDetailsActivity extends StatefulWidget {
  String type;
  EditUserDetailsActivity(this.type,{super.key});

  @override
  State<EditUserDetailsActivity> createState() =>
      _EditUserDetailsActivityState();
}

class _EditUserDetailsActivityState extends State<EditUserDetailsActivity> {
  var firstNameController = TextEditingController();
  var lastNameController = TextEditingController();
  var emailController = TextEditingController();
  var profileController = TextEditingController();
  var locationController = TextEditingController();
  List<File> selectedFiles = [];
  String imageURl  = "";
  double currentLat = 0.0;
  double currentLng = 0.0;

  ApiFuntions apiFuntions = ApiFuntions();
  LoginDataManager? loginDataManager;
  late SharedPreferences? sharedPreferences;

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
    
    // Load location from SharedPreferences (captured on login)
    setState(() {
      locationController.text = sharedPreferences!.getString(Constant.location) ?? "";
      currentLat = double.tryParse(sharedPreferences!.getString(Constant.lat) ?? "0.0") ?? 0.0;
      currentLng = double.tryParse(sharedPreferences!.getString(Constant.long) ?? "0.0") ?? 0.0;
    });
  }

  postUserDetails(BuildContext context) async {
    // Get location from controller or use current location
    String locationName = locationController.text.isNotEmpty 
        ? locationController.text 
        : sharedPreferences!.getString(Constant.location) ?? "";
    double lat = currentLat != 0.0 ? currentLat : (double.tryParse(sharedPreferences!.getString(Constant.lat) ?? "0.0") ?? 0.0);
    double lng = currentLng != 0.0 ? currentLng : (double.tryParse(sharedPreferences!.getString(Constant.long) ?? "0.0") ?? 0.0);
    
    var response = await loginDataManager!.postUserDetails(
        firstNameController.text,
        lastNameController.text,
        emailController.text,
        imageURl,
        sharedPreferences!.getString(Constant.id)??"",
        context,
        locationName: locationName.isNotEmpty ? locationName : null,
        lat: lat != 0.0 ? lat : null,
        lng: lng != 0.0 ? lng : null);
    var data = UserDetailsModelBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      sharedPreferences!
          .setString(Constant.firstName, data.data!.firstName ?? "");
      sharedPreferences!
          .setString(Constant.lastName, data.data!.lastName ?? "");
      sharedPreferences!.setString(Constant.email, data.data!.email ?? "");
      sharedPreferences!.setString(Constant.isEmailVerified,
          data.data!.isEmailVerified.toString() ?? "");
      sharedPreferences!.setString(Constant.mobile, data.data!.mobile ?? "");
      sharedPreferences!
          .setString(Constant.isNewUser, data.data!.isNewUser.toString() ?? "");
      sharedPreferences!
          .setString(Constant.roleName, data.data!.roleName ?? "");
      sharedPreferences!
          .setString(Constant.id, data.data!.sId.toString() ?? "");
      
      // Update location in SharedPreferences if location was updated
      if (locationName.isNotEmpty) {
        sharedPreferences!.setString(Constant.location, locationName);
        sharedPreferences!.setString(Constant.lat, lat.toString());
        sharedPreferences!.setString(Constant.long, lng.toString());
      }
      
      CommonWidget.successShowSnackBarFor(context, data.message??"");
      if(widget.type == "otp") {
        // After profile completion, check if user has vendor details
        await _checkVendorDetailsAndRedirect();
      } else {
        Navigator.pop(context, true);
      }
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Navigator.pop(context);
        CommonWidget.errorShowSnackBarFor(
            context, 'Location services are disabled. Please enable them.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Navigator.pop(context);
          CommonWidget.errorShowSnackBarFor(
              context, 'Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Navigator.pop(context);
        CommonWidget.errorShowSnackBarFor(
            context, 'Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        currentLat = position.latitude;
        currentLng = position.longitude;
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      
      String address = placemarks[0].locality ?? 
                      placemarks[0].subAdministrativeArea ?? 
                      placemarks[0].administrativeArea ?? 
                      "Current Location";
      
      setState(() {
        locationController.text = address;
      });
      
      sharedPreferences!.setString(Constant.location, address);
      sharedPreferences!.setString(Constant.lat, position.latitude.toString());
      sharedPreferences!.setString(Constant.long, position.longitude.toString());

      Navigator.pop(context);
      CommonWidget.successShowSnackBarFor(
          context, 'Location updated successfully!');
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      CommonWidget.errorShowSnackBarFor(
          context, 'Error getting location: ${e.toString()}');
    }
  }

  Future<void> _checkVendorDetailsAndRedirect() async {
    try {
      // Get updated user details to check for vendor information
      var response = await loginDataManager!.getUserDetails(context);
      
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        // If API error, go to dashboard
        CommonWidget.navigateToKillAllScreen(context, const DashboardActivity());
        return;
      }
      
      var data = VendorDetailBean.fromJson(jsonDecode(response.body));
      if (data.status == "success" && data.data != null && data.data!.isNotEmpty) {
        // Check if user has vendor details
        if (data.data![0].vendorDetails != null && data.data![0].vendorDetails!.isNotEmpty) {
          // User has vendor details, go to dashboard
          print("✅ User has vendor details, going to dashboard");
          CommonWidget.navigateToKillAllScreen(context, const DashboardActivity());
        } else {
          // User doesn't have vendor details, redirect to shop setup
          print("❌ User doesn't have vendor details, redirecting to shop setup");
          CommonWidget.navigateToKillAllScreen(context, const SimpleAddShopActivity());
        }
      } else {
        // Error getting user details, go to dashboard
        CommonWidget.navigateToKillAllScreen(context, const DashboardActivity());
      }
    } catch (e) {
      print("Error checking vendor details: $e");
      // On error, go to dashboard
      CommonWidget.navigateToKillAllScreen(context, const DashboardActivity());
    }
  }

  postImage(BuildContext context) async {
    List<File> image = [selectedFiles[0]];
    var response = await loginDataManager!.postImage(
        image,
        context);
    var data = ImageModuleData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      imageURl = data.data?.url??"";
      //CommonWidget.successShowSnackBarFor(context, data.message??"");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
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
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 45, left: 15),
              child: InkWell(
                onTap: (){
                  Navigator.pop(context, true);
                },
                child: Image.asset(
                  CommonWidget.getImagePath("backspace.png"),
                  height: 40,
                  width: 40,
                ),
              ),
            ),
            Expanded(child: Container(
              margin: kIsWeb
                  ? const EdgeInsets.only(top: 320)
                  : const EdgeInsets.only(top: 250),
              child: Column(
                children: [
                  //Image(image: AssetImage('assets/images/login_image.png')),
                  Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 20, right: 20),
                        child: SingleChildScrollView(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                CommonWidget.getTextWidget500("Profile Details",
                                    color: ColorClass.base_color, size: 20),
                                Container(
                                  alignment: Alignment.center,
                                  child: Stack(
                                    children: [
                                      if (selectedFiles.isEmpty)
                                        ClipOval(
                                          child: Image.asset(
                                            CommonWidget.getImagePath("chat_profile.png"),
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                      if (selectedFiles.isNotEmpty)
                                        ClipOval(
                                          child: CommonWidget.determineImageAsset(
                                              selectedFiles[0].path ?? ""),
                                        ),
                                      Positioned(
                                        bottom: 5,
                                        right: 0,
                                        child: SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: GestureDetector(
                                              child: Image.asset(
                                                  CommonWidget.getImagePath("add_image_icon.png")),
                                              // Icon color and size
                                              onTap: () async {
                                                var data = await BaseActivity.pickmedia(false);
                                                if (data != null) {
                                                  setState(() {
                                                    selectedFiles.clear();
                                                    for (int i = 0;
                                                    i < data.length;
                                                    i++) {
                                                      setState(() {
                                                        selectedFiles.add(data[i]);
                                                      });
                                                    }
                                                                                                    });
                                                }
                                                print(selectedFiles.length);
                                                postImage(context);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CommonWidget.getTextFieldWithgrayboder(
                                    "Enter First Name", firstNameController),
                                CommonWidget.getTextFieldWithgrayboder(
                                    "Enter Last Name", lastNameController),
                                CommonWidget.getTextFieldWithgrayboder(
                                    "Enter Email Address", emailController),
                                const SizedBox(height: 12),
                                // Location Section
                                Row(
                                  children: [
                                    Expanded(
                                      child: CommonWidget.getTextFieldWithgrayboder(
                                          "Location", locationController),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: ColorClass.base_color,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.my_location, color: Colors.white),
                                        onPressed: _getCurrentLocation,
                                        tooltip: "Get Current Location",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                GestureDetector(
                                    onTap: () {
                                      //FocusManager.instance.primaryFocus?.unfocus();
                                      if (BaseActivity.checkEmptyField(
                                          editingController: firstNameController,
                                          message: "Please Enter First Name.",
                                          context: context)) {
                                        return;
                                      } else if (BaseActivity.checkEmptyField(
                                          editingController: lastNameController,
                                          message: "Please Enter Last Name.",
                                          context: context)) {
                                        return;
                                      } /*else if (BaseActivity.checkEmptyField(
                                          editingController: emailController,
                                          message: "Please Enter Email Address.",
                                          context: context)) {
                                        return;
                                      }else if (imageURl == "") {
                                        CommonWidget.successShowSnackBarFor(context, "Please Select Profile Image");
                                        return;
                                      }*/ else {
                                        postUserDetails(context);
                                      }
                                    },
                                    child: Container(
                                      child: CommonWidget.getGradinetButton("Save",
                                          startcolor: 0xff1CA669,
                                          endcolor: 0xff1CA669,
                                          height: 40),
                                    )),
                              ]),
                        ),
                      ))
                ],
              ),
            ),)
          ],
        )



      ),
    );
  }
}
