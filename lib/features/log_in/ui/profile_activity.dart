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
import '../../../Common/ModernDesignSystem.dart';
import '../../../Models/image_module_data.dart';
import '../../dashboard_module/ui/dashboard_activity.dart';
import '../data_manager/LoginDataManager.dart';
import '../model/user_detail_model_bean.dart';
import '../model/vendor_details_bean.dart';
import '../../packages_model/ui/package_list_activity.dart';
import '../../packages_model/data_manager/package_data_manager.dart';
import '../../packages_model/model/package_model_data.dart';
import '../../offer_model/ui/enhanced_offer_list_screen.dart';
import '../../offer_model/data_manager/offer_data_manager.dart';
import '../../offer_model/model/offer_list_model_bean.dart';

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
  PackageDataManager? packageDataManager;
  OfferDataManager? offerDataManager;
  List<PackageData> packages = [];
  List<OfferListModelData> offers = [];
  bool isLoadingPackages = false;
  bool isLoadingOffers = false;

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
    if (!mounted) return;
    loginDataManager = LoginDataManager(sharedPreferences!);
    packageDataManager = PackageDataManager(sharedPreferences!);
    offerDataManager = OfferDataManager(sharedPreferences!);
    getUser(context);
    // Fetch packages and offers if vendor exists
    String? vendorId = sharedPreferences!.getString(Constant.vendorId);
    if (vendorId != null && vendorId.isNotEmpty) {
      getPackages(context);
      getOffers(context);
    }
  }

  getUser(BuildContext context) async {
    var response = await loginDataManager!.getUserDetails(context);
    if (!mounted) return;
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
      sharedPreferences!
          .setString(Constant.UserID, data.data?[0].sId.toString() ?? "");
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
      //CommonWidget.navigateToScreen(context, OTPScreenActivity());
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  postUserDetails(BuildContext context) async {
    if (!mounted || !context.mounted) return;
    
    // Store a reference to close the dialog later
    BuildContext? dialogContext;
    
    try {
      // Show loading indicator
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
      
      if (!mounted) return;
      
      // Close loading indicator
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
      sharedPreferences!
          .setString(Constant.UserID, data.data!.sId.toString() ?? "");
      
      // Update location in SharedPreferences if location was updated
      if (locationName.isNotEmpty) {
        sharedPreferences!.setString(Constant.location, locationName);
        sharedPreferences!.setString(Constant.lat, lat.toString());
        sharedPreferences!.setString(Constant.long, lng.toString());
      }

      // Sync image URL in SharedPreferences
      sharedPreferences!.setString(Constant.image, data.data!.image ?? "");
      
          if (mounted && context.mounted) {
            CommonWidget.successShowSnackBarFor(context, data.message ?? "Profile updated successfully!");
            // Use safe navigation to go back - wait a bit for snackbar to show
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && context.mounted) {
                try {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(true);
                  } else {
                    // If we can't pop, navigate to dashboard instead
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardActivity()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  // Fallback: navigate to dashboard
                  if (mounted && context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardActivity()),
                      (route) => false,
                    );
                  }
                }
              }
            });
          }
    } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to update profile. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error parsing response. Please try again.");
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
      if (!mounted) return;
      if (!serviceEnabled) {
        if (mounted && context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        CommonWidget.errorShowSnackBarFor(
            context, 'Location services are disabled. Please enable them.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted && context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          CommonWidget.errorShowSnackBarFor(
              context, 'Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted && context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        CommonWidget.errorShowSnackBarFor(
            context, 'Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;

      setState(() {
        currentLat = position.latitude;
        currentLng = position.longitude;
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      
      if (!mounted) return;
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

      if (mounted && context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      CommonWidget.successShowSnackBarFor(
          context, 'Location updated successfully!');
    } catch (e) {
      if (mounted && context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      CommonWidget.errorShowSnackBarFor(
          context, 'Error getting location: ${e.toString()}');
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
        skipAutoNavigation: true, // Skip auto-navigation to handle 401 ourselves
      );
      
      if (!mounted) return;
      
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
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
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
                  // Back Button
                  CommonWidget.buildHeaderBackButton(
                    context,
                    onPressed: () => CommonWidget.safePop(context, result: true),
                  ),
                ],
              ),
            ),
            
            // Main Content Card
                    Expanded(
              child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: ModernDesignSystem.spacingL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(ModernDesignSystem.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                          child: SingleChildScrollView(
                    padding: const EdgeInsets.all(ModernDesignSystem.spacingXL),
                            child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                        // Title
                        // Text(
                        //   "Profile Details",
                        //   style: ModernDesignSystem.heading2(
                        //     color: ColorClass.base_color,
                        //   ),
                        // ),
                        const SizedBox(height: ModernDesignSystem.spacingXL),
                        
                        // Profile Picture
                        Center(
                                    child: Stack(
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
                                child: ClipOval(
                                  child: profileurl != "" && selectedFiles.isEmpty
                                      ? Image.network(
                                          profileurl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.asset(
                                              CommonWidget.getImagePath("chat_profile.png"),
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        )
                                      : selectedFiles.isNotEmpty
                                          ? CommonWidget.determineImageAsset(
                                              selectedFiles[0].path ?? "")
                                          : Image.asset(
                                          CommonWidget.getImagePath("chat_profile.png"),
                                              fit: BoxFit.cover,
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
                                      if (mounted) {
                                                    setState(() {
                                                      selectedFiles.clear();
                                          selectedFiles.addAll(data);
                                                        });
                                                      }
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
                                      boxShadow: ModernDesignSystem.shadowMedium,
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
                                  ),
                        const SizedBox(height: ModernDesignSystem.spacingXL),
                        
                        // Input Fields
                        _buildModernTextField(
                          "First Name",
                          firstNameController,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingM),
                        _buildModernTextField(
                          "Last Name",
                          lastNameController,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingM),
                        _buildModernTextField(
                          "Email Address (Optional)",
                          emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingM),
                        
                        // Location Field with button
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
                                    child: TextField(
                                      controller: locationController,
                                      readOnly: true,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontFamily: "Pop400",
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "Location",
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
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
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
                                  child: IconButton(
                                    icon: const Icon(Icons.gps_fixed, color: Colors.white),
                                    onPressed: _getCurrentLocation,
                                    tooltip: "Get Current Location",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingXL),
                        
                        // Packages Section
                        _buildPackagesSection(context),
                        const SizedBox(height: ModernDesignSystem.spacingM),
                        
                        // Offers Section
                        _buildOffersSection(context),
                        const SizedBox(height: ModernDesignSystem.spacingXL),
                        
                        // Save Button
                        ElevatedButton(
                          onPressed: () {
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
                            } else if (imageURl == "" && selectedFiles.isEmpty && profileurl == "") {
                                          CommonWidget.successShowSnackBarFor(
                                              context, "Please Select Profile Image");
                                          return;
                                        } else {
                                          postUserDetails(context);
                                        }
                                      },
                          style: ModernDesignSystem.modernButtonStyle(
                            backgroundColor: ColorClass.base_color,
                            borderRadius: ModernDesignSystem.radiusM,
                            padding: const EdgeInsets.symmetric(vertical: ModernDesignSystem.spacingL),
                          ),
                          child: Text(
                            "Save",
                            style: ModernDesignSystem.bodyLarge(
                              color: Colors.white,
                            ).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingL),
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

  Widget _buildModernTextField(
    String hint,
    TextEditingController controller, {
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint,
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
            readOnly: readOnly,
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
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: ColorClass.base_color,
                      size: 22,
                    )
                  : null,
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
          ),
        ),
      ],
    );
  }

  // Fetch packages
  Future<void> getPackages(BuildContext context) async {
    if (packageDataManager == null) return;
    
    setState(() {
      isLoadingPackages = true;
    });
    
    try {
      var response = await packageDataManager!.getAllPackages(context);
      if (!mounted) return;
      if (response.statusCode == 200) {
        var data = PackageModelData.fromJson(jsonDecode(response.body));
        if (data.status == "success" && data.data != null) {
          setState(() {
            packages = data.data!;
            isLoadingPackages = false;
          });
        } else {
          setState(() {
            packages = [];
            isLoadingPackages = false;
          });
        }
      } else {
        setState(() {
          packages = [];
          isLoadingPackages = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          packages = [];
          isLoadingPackages = false;
        });
      }
    }
  }

  // Fetch offers
  Future<void> getOffers(BuildContext context) async {
    if (offerDataManager == null) return;
    
    setState(() {
      isLoadingOffers = true;
    });
    
    try {
      var response = await offerDataManager!.getOfferList(context);
      if (!mounted) return;
      if (response.statusCode == 200) {
        var data = OfferListModelBean.fromJson(jsonDecode(response.body));
        if (data.status == "success" && data.data != null) {
          setState(() {
            offers = data.data!;
            isLoadingOffers = false;
          });
        } else {
          setState(() {
            offers = [];
            isLoadingOffers = false;
          });
        }
      } else {
        setState(() {
          offers = [];
          isLoadingOffers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          offers = [];
          isLoadingOffers = false;
        });
      }
    }
  }

  // Build Packages Section
  Widget _buildPackagesSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Packages",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: "Pop600",
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PackageListActivity(),
                      ),
                    ).then((_) {
                      // Refresh packages when returning
                      String? vendorId = sharedPreferences!.getString(Constant.vendorId);
                      if (vendorId != null && vendorId.isNotEmpty) {
                        getPackages(context);
                      }
                    });
                  },
                  child: Text(
                    "See All",
                    style: TextStyle(
                      color: ColorClass.base_color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoadingPackages)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (packages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.grey[400], size: 48),
                    const SizedBox(height: 8),
                    Text(
                      "No packages yet",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: packages.length > 3 ? 3 : packages.length,
                itemBuilder: (context, index) {
                  return _buildPackageCard(packages[index]);
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Build Package Card
  Widget _buildPackageCard(PackageData package) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.packageName ?? "Package",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: "Pop600",
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              package.packageDescription ?? "",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "\$${package.packagePrice ?? "0"}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorClass.base_color,
                    fontFamily: "Pop600",
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (package.isActive ?? true) ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (package.isActive ?? true) ? "Active" : "Inactive",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build Offers Section
  Widget _buildOffersSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Offers",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: "Pop600",
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EnhancedOfferListScreen(),
                      ),
                    ).then((_) {
                      // Refresh offers when returning
                      String? vendorId = sharedPreferences!.getString(Constant.vendorId);
                      if (vendorId != null && vendorId.isNotEmpty) {
                        getOffers(context);
                      }
                    });
                  },
                  child: Text(
                    "See All",
                    style: TextStyle(
                      color: ColorClass.base_color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoadingOffers)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (offers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.local_offer, color: Colors.grey[400], size: 48),
                    const SizedBox(height: 8),
                    Text(
                      "No offers yet",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: offers.length > 3 ? 3 : offers.length,
                itemBuilder: (context, index) {
                  return _buildOfferCard(offers[index]);
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Build Offer Card
  Widget _buildOfferCard(OfferListModelData offer) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    offer.title ?? "Offer",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: "Pop600",
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              offer.description ?? "",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${offer.discount ?? 0}% OFF",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (offer.isActive ?? true) ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (offer.isActive ?? true) ? "Active" : "Inactive",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
