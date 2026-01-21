import 'dart:convert';
import 'dart:io';

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
import 'package:google_maps_places_autocomplete_widgets/widgets/address_autocomplete_textfield.dart';
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
    if (!mounted || !context.mounted) return;
    
    try {
      // Check if user ID exists
      String userId = sharedPreferences!.getString(Constant.id) ?? "";
      if (userId.isEmpty) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "User session expired. Please login again.");
        }
        return;
      }
      
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
          userId,
          context,
          locationName: locationName.isNotEmpty ? locationName : null,
          lat: lat != 0.0 ? lat : null,
          lng: lng != 0.0 ? lng : null);
      
      if (!mounted || !context.mounted) return;
      
      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        return;
      }
      
      // Check response status code
      if (response.statusCode != 200 && response.statusCode != 201) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to update profile. Please check your connection and try again.");
        }
        return;
      }
      
      try {
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
          
          if (mounted && context.mounted) {
            CommonWidget.successShowSnackBarFor(context, data.message??"");
            if(widget.type == "otp") {
              // After profile completion, check if user has vendor details
              await _checkVendorDetailsAndRedirect();
            } else {
              Navigator.pop(context, true);
            }
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error parsing response. Please try again.");
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error updating profile. Please check your connection and try again.");
      }
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
    if (!mounted || !context.mounted) return;
    
    try {
      // Get updated user details to check for vendor information
      var response = await loginDataManager!.getUserDetails(context);
      
      if (!mounted || !context.mounted) return;
      
      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
          // Still redirect to shop setup for new users
          CommonWidget.navigateToKillAllScreen(context, const SimpleAddShopActivity());
        }
        return;
      }
      
      // Check response status code
      if (response.statusCode == 401 || response.statusCode == 403) {
        // Authentication error - user might be logged out
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Session expired. Please login again.");
          // Don't navigate to login - let the app handle it
          return;
        }
        return;
      }
      
      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to load user details. Redirecting to shop setup.");
          CommonWidget.navigateToKillAllScreen(context, const SimpleAddShopActivity());
        }
        return;
      }
      
      try {
        var data = VendorDetailBean.fromJson(jsonDecode(response.body));
        if (data.status == "success" && data.data != null && data.data!.isNotEmpty) {
          // Check if user has vendor details
          if (data.data![0].vendorDetails != null && data.data![0].vendorDetails!.isNotEmpty) {
            // User has vendor details, go to dashboard
            if (mounted && context.mounted) {
              CommonWidget.navigateToKillAllScreen(context, const DashboardActivity());
            }
          } else {
            // User doesn't have vendor details, redirect to shop setup
            if (mounted && context.mounted) {
              CommonWidget.navigateToKillAllScreen(context, const SimpleAddShopActivity());
            }
          }
        } else {
          // Error getting user details, redirect to shop setup for new users
          if (mounted && context.mounted) {
            CommonWidget.navigateToKillAllScreen(context, const SimpleAddShopActivity());
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error parsing response. Redirecting to shop setup.");
          CommonWidget.navigateToKillAllScreen(context, const SimpleAddShopActivity());
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        // On error, redirect to shop setup for new users
        CommonWidget.navigateToKillAllScreen(context, const SimpleAddShopActivity());
      }
    }
  }

  postImage(BuildContext context) async {
    if (!mounted || !context.mounted) return;
    
    // Store a reference to close the dialog later
    BuildContext? dialogContext;
    
    try {
      // Check if access token exists before uploading
      String? accessToken = sharedPreferences!.getString(Constant.accessToken);
      if (accessToken == null || accessToken.isEmpty) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Session expired. Please login again.");
        }
        return;
      }
      
      List<File> image = [selectedFiles[0]];
      
      // Show loading indicator and capture dialog context
      if (!mounted || !context.mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogBuildContext) {
          dialogContext = dialogBuildContext;
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      
      var response = await loginDataManager!.postImage(
          image,
          context,
          skipAutoNavigation: true); // Skip auto-navigation to handle 401 ourselves
      
      // Close loading indicator using the dialog's context
      if (mounted && dialogContext != null && dialogContext!.mounted) {
        try {
          Navigator.of(dialogContext!).pop();
        } catch (e) {
          // Fallback: try with main context if dialog context fails
          if (mounted && context.mounted && Navigator.of(context).canPop()) {
            try {
              Navigator.of(context).pop();
            } catch (e2) {
            }
          }
        }
      }
      
      if (!mounted || !context.mounted) return;
      
      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        return;
      }
      
      // Check response status code
      if (response.statusCode == 401) {
        // 401 means unauthorized - token might be expired or missing
        // Since we skipped auto-navigation, handle it here
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Session expired. Please save your profile details and login again.");
        }
        return;
      }
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to upload image. Please try again.");
        }
        return;
      }
      
      try {
        var data = ImageModuleData.fromJson(jsonDecode(response.body));
        if (data.status == "success") {
          if (mounted) {
            setState(() {
              imageURl = data.data?.url ?? "";
            });
          }
          if (mounted && context.mounted) {
            CommonWidget.successShowSnackBarFor(context, "Image uploaded successfully!");
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to upload image. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error processing image upload. Please try again.");
        }
      }
    } catch (e) {
      // Close loading indicator if still open
      if (mounted && dialogContext != null && dialogContext!.mounted) {
        try {
          Navigator.of(dialogContext!).pop();
        } catch (popError) {
          // Fallback: try with main context
          if (mounted && context.mounted && Navigator.of(context).canPop()) {
            try {
              Navigator.of(context).pop();
            } catch (e2) {
            }
          }
        }
      }
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error uploading image. Please check your connection and try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // White Header with Green Back Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Centered Title
                  Center(
                    child: Text(
                      "Profile Details",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ColorClass.base_color,
                        fontFamily: "Pop600",
                      ),
                    ),
                  ),
                  // Back Button with uniform design
                  CommonWidget.buildHeaderBackButton(
                    context,
                    backgroundColor: ColorClass.base_color.withOpacity(0.15),
                    iconColor: ColorClass.base_color,
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
                ],
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Profile Image Section
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            border: Border.all(
                              color: ColorClass.base_color.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: selectedFiles.isEmpty
                              ? ClipOval(
                                  child: Image.asset(
                                    CommonWidget.getImagePath("chat_profile.png"),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : ClipOval(
                                  child: CommonWidget.determineImageAsset(
                                    selectedFiles[0].path ?? "",
                                  ),
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              var data = await BaseActivity.pickmedia(false);
                              if (data != null) {
                                setState(() {
                                  selectedFiles.clear();
                                  for (int i = 0; i < data.length; i++) {
                                    selectedFiles.add(data[i]);
                                  }
                                });
                                postImage(context);
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: ColorClass.base_color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Optional text for new users
                    FutureBuilder<SharedPreferences?>(
                      future: SharedPreferences.getInstance(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          String? isNewUser = snapshot.data!.getString(Constant.isNewUser);
                          bool isNewUserFlag = isNewUser == "true" || isNewUser == null;
                          
                          if (isNewUserFlag) {
                            return Text(
                              "Profile image is required",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontFamily: "Pop400",
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Form Fields with labels above
                    _buildTextField(
                      controller: firstNameController,
                      label: "First Name",
                      hint: "Enter your first name",
                      icon: Icons.person_outline,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: lastNameController,
                      label: "Last Name",
                      hint: "Enter your last name",
                      icon: Icons.person_outline,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: emailController,
                      label: "Email Address (Optional)",
                      hint: "Enter your email",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      isOptional: true,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Location Field with Google Places Autocomplete
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Location",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            fontFamily: "Pop500",
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: AddressAutocompleteTextField(
                                  decoration: InputDecoration(
                                    hintText: "Search location...",
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                      fontFamily: "Pop400",
                                    ),
                                    prefixIcon: Icon(
                                      Icons.location_on_outlined,
                                      color: ColorClass.base_color,
                                      size: 22,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: ColorClass.base_color,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  mapsApiKey: 'AIzaSyBFtrosISezP-8z2NwTWKhD_5pNHoi0wRw',
                                  controller: locationController,
                                  onSuggestionClick: (place) {
                                    final address = place.formattedAddress ?? place.name ?? '';
                                    final lat = place.lat ?? 0.0;
                                    final lng = place.lng ?? 0.0;
                                    setState(() {
                                      locationController.text = address;
                                      currentLat = lat;
                                      currentLng = lng;
                                    });
                                    // Save to shared preferences
                                    if (sharedPreferences != null) {
                                      sharedPreferences!.setString(Constant.location, address);
                                      sharedPreferences!.setString(Constant.lat, lat.toString());
                                      sharedPreferences!.setString(Constant.long, lng.toString());
                                    }
                                  },
                                  language: 'en-US',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _getCurrentLocation,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: ColorClass.base_color,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ColorClass.base_color.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.gps_fixed,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          if (BaseActivity.checkEmptyField(
                            editingController: firstNameController,
                            message: "Please enter first name",
                            context: context,
                          )) {
                            return;
                          } else if (BaseActivity.checkEmptyField(
                            editingController: lastNameController,
                            message: "Please enter last name",
                            context: context,
                          )) {
                            return;
                          } else if (selectedFiles.isEmpty && imageURl.isEmpty) {
                            CommonWidget.errorShowSnackBarFor(
                              context,
                              "Please upload a profile image. This is required for vendors.",
                            );
                            return;
                          } else {
                            // Email is optional, no validation needed
                            postUserDetails(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorClass.base_color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Pop600",
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            fontFamily: "Pop500",
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontFamily: "Pop400",
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontFamily: "Pop400",
              ),
              prefixIcon: Icon(
                icon,
                color: ColorClass.base_color,
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
