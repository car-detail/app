import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/BaseActivity.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../../../Models/image_module_data.dart';
import '../../dashboard_module/ui/dashboard_activity.dart';
import '../data_manager/LoginDataManager.dart';
import '../model/user_detail_model_bean.dart';
import '../model/vendor_details_bean.dart';

class ProfileActivity extends StatefulWidget {
  const ProfileActivity({super.key});

  @override
  State<ProfileActivity> createState() => _ProfileActivityState();
}

class _ProfileActivityState extends State<ProfileActivity> {
  var firstNameController = TextEditingController();
  var lastNameController = TextEditingController();
  var emailController = TextEditingController();
  var profileController = TextEditingController();
  var locationController = TextEditingController();
  List<File> selectedFiles = [];
  String imageURl = "";
  String profileurl = "";
  double currentLat = 0.0;
  double currentLng = 0.0;

  ApiFuntions apiFunction = ApiFuntions();
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
    getUser(context);
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
      sharedPreferences!.setString(Constant.mobile, data.data?[0].mobile ?? "");
      sharedPreferences!.setString(
          Constant.isNewUser, data.data?[0].isNewUser.toString() ?? "");
      sharedPreferences!
          .setString(Constant.roleName, data.data?[0].roleName ?? "");
      sharedPreferences!
          .setString(Constant.id, data.data?[0].sId.toString() ?? "");
      if (data.data![0].vendorDetails!.isNotEmpty) {
        sharedPreferences!.setString(Constant.vendorId,
            data.data?[0].vendorDetails![0].sId.toString() ?? "");
      }
      setState(() {
        firstNameController.text = data.data?[0].firstName ?? "";
        lastNameController.text = data.data?[0].lastName ?? "";
        emailController.text = data.data?[0].email ?? "";
        profileurl = data.data?[0].image ?? "";
        imageURl = data.data?[0].image ?? "";
        
        // Load location from user data or SharedPreferences
        if (data.data?[0].location?.name != null && (data.data![0].location!.name?.isNotEmpty ?? false)) {
          locationController.text = data.data![0].location!.name ?? "";
          currentLat = data.data![0].location!.coordinates?.lat?.toDouble() ?? 0.0;
          currentLng = data.data![0].location!.coordinates?.long?.toDouble() ?? 0.0;
        } else {
          // Load from SharedPreferences (captured on login)
          locationController.text = sharedPreferences!.getString(Constant.location) ?? "";
          currentLat = double.tryParse(sharedPreferences!.getString(Constant.lat) ?? "0.0") ?? 0.0;
          currentLng = double.tryParse(sharedPreferences!.getString(Constant.long) ?? "0.0") ?? 0.0;
        }
      });
      print("Profile image url  $profileurl");
      //CommonWidget.navigateToScreen(context, OTPScreenActivity());
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
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
        sharedPreferences!.getString(Constant.id) ?? "",
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
      
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      Navigator.pop(context, true);
      //CommonWidget.navigateToKillAllScreen(context, DashboardActivity());
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

  postImage(BuildContext context) async {
    List<File> image = [selectedFiles[0]];
    var response = await loginDataManager!.postImage(image, context);
    var data = ImageModuleData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      imageURl = data.data?.url ?? "";
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
            Expanded(
              child: Container(
                  margin: !kIsWeb
                      ? const EdgeInsets.only(top: 245,)
                      : const EdgeInsets.only(
                    top: 165,),
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
                                        if (profileurl != "" && selectedFiles.isEmpty)
                                          ClipOval(
                                            child: /*Image.asset(
                                          CommonWidget.getImagePath("chat_profile.png"),
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.fill,
                                        ),*/
                                            Image.network(
                                              profileurl,
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        if (profileurl == "")
                                          ClipOval(
                                            child: Image.asset(
                                              CommonWidget.getImagePath(
                                                  "chat_profile.png"),
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
                                                    CommonWidget.getImagePath(
                                                        "add_image_icon.png")),
                                                // Icon color and size
                                                onTap: () async {
                                                  var data =
                                                  await BaseActivity.pickmedia(false);
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
                                        } else if (BaseActivity.checkEmptyField(
                                            editingController: emailController,
                                            message: "Please Enter Email Address.",
                                            context: context)) {
                                          return;
                                        } else if (imageURl == "") {
                                          CommonWidget.successShowSnackBarFor(
                                              context, "Please Select Profile Image");
                                          return;
                                        } else {
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
              ),
            ),
          ],
        )



      ),
    );
  }

}
