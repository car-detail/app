import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:car_app/Common/CommonPopUp.dart';
import 'package:car_app/features/resister_vendor_model/model/edit_vendor_bean.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_places_autocomplete_widgets/widgets/address_autocomplete_textfield.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/BaseActivity.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../../../Models/image_module_data.dart';
import '../datamanager/add_shop_data_manager.dart';
import '../model/capture_vendor_bean.dart';
class EditVendorActivity extends StatefulWidget {
  const EditVendorActivity({super.key});

  @override
  State<EditVendorActivity> createState() => _EditVendorActivityState();
}

// Class to hold time slots for each day
class DayTimeSlot {
  final String day;
  bool isSelected;
  String openTime;
  String closeTime;
  Map<String, bool> timeSlotSelections; // e.g., {"Morning": false, "Afternoon": false, "Evening": false}

  DayTimeSlot({
    required this.day,
    this.isSelected = false,
    this.openTime = "",
    this.closeTime = "",
    Map<String, bool>? timeSlotSelections,
  }) : timeSlotSelections = timeSlotSelections ?? <String, bool>{
          "Morning (9AM-12PM)": false,
          "Afternoon (12PM-5PM)": false,
          "Evening (5PM-9PM)": false,
        };
  
  // Initialize timeSlotSelections if it's empty
  void ensureTimeSlotSelections() {
    if (timeSlotSelections.isEmpty) {
      timeSlotSelections = <String, bool>{
        "Morning (9AM-12PM)": false,
        "Afternoon (12PM-5PM)": false,
        "Evening (5PM-9PM)": false,
      };
    }
  }
}

class _EditVendorActivityState extends State<EditVendorActivity> {
  var shopNameController = TextEditingController();
  var mobileController = TextEditingController();
  var emailController = TextEditingController();
  var profileController = TextEditingController();
  var addressController = TextEditingController();
  double long = 0.0;
  double late = 0.0;
  List<File> selectedFiles = [];
  String imageURl = "";
  String networkImage = "";
  final List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  
  // Time slot periods
  final List<String> timeSlotPeriods = [
    "Morning (9AM-12PM)",
    "Afternoon (12PM-5PM)",
    "Evening (5PM-9PM)",
  ];

  // Time slots for each day - initialize with default values
  List<DayTimeSlot> dayTimeSlots = [
    DayTimeSlot(
      day: 'Monday',
      isSelected: false,
      openTime: "09:00 AM",
      closeTime: "06:00 PM",
      timeSlotSelections: {
        "Morning (9AM-12PM)": false,
        "Afternoon (12PM-5PM)": false,
        "Evening (5PM-9PM)": false,
      },
    ),
    DayTimeSlot(
      day: 'Tuesday',
      isSelected: false,
      openTime: "09:00 AM",
      closeTime: "06:00 PM",
      timeSlotSelections: {
        "Morning (9AM-12PM)": false,
        "Afternoon (12PM-5PM)": false,
        "Evening (5PM-9PM)": false,
      },
    ),
    DayTimeSlot(
      day: 'Wednesday',
      isSelected: false,
      openTime: "09:00 AM",
      closeTime: "06:00 PM",
      timeSlotSelections: {
        "Morning (9AM-12PM)": false,
        "Afternoon (12PM-5PM)": false,
        "Evening (5PM-9PM)": false,
      },
    ),
    DayTimeSlot(
      day: 'Thursday',
      isSelected: false,
      openTime: "09:00 AM",
      closeTime: "06:00 PM",
      timeSlotSelections: {
        "Morning (9AM-12PM)": false,
        "Afternoon (12PM-5PM)": false,
        "Evening (5PM-9PM)": false,
      },
    ),
    DayTimeSlot(
      day: 'Friday',
      isSelected: false,
      openTime: "09:00 AM",
      closeTime: "06:00 PM",
      timeSlotSelections: {
        "Morning (9AM-12PM)": false,
        "Afternoon (12PM-5PM)": false,
        "Evening (5PM-9PM)": false,
      },
    ),
    DayTimeSlot(
      day: 'Saturday',
      isSelected: false,
      openTime: "09:00 AM",
      closeTime: "06:00 PM",
      timeSlotSelections: {
        "Morning (9AM-12PM)": false,
        "Afternoon (12PM-5PM)": false,
        "Evening (5PM-9PM)": false,
      },
    ),
    DayTimeSlot(
      day: 'Sunday',
      isSelected: false,
      openTime: "09:00 AM",
      closeTime: "06:00 PM",
      timeSlotSelections: {
        "Morning (9AM-12PM)": false,
        "Afternoon (12PM-5PM)": false,
        "Evening (5PM-9PM)": false,
      },
    ),
  ];

  ApiFuntions apiFuntions = ApiFuntions();
  AddShopDataManager? dataManager;
  late SharedPreferences? sharedPreferences;
  bool _isGettingLocation = false;

  Future<void> _getCurrentLocation() async {
    if (!mounted || _isGettingLocation) return;
    
    setState(() {
      _isGettingLocation = true;
    });
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Location services are disabled.");
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, "Location permission denied.");
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Location permission permanently denied.");
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (mounted) {
        setState(() {
          late = position.latitude;
          long = position.longitude;
        });
      }
      
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks[0];
          final street = place.street ?? "";
          final locality = place.locality ?? "";
          final area = place.administrativeArea ?? "";
          final address = [street, locality, area].where((s) => s.isNotEmpty).join(", ");
          if (address.isNotEmpty) {
            setState(() {
              addressController.text = address;
            });
          }
        }
      } catch (e) {
        // Handle geocoding error gracefully
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Unable to get your location. Please type your address manually.");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

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
    dataManager = AddShopDataManager(sharedPreferences!);
    // Ensure dayTimeSlots is initialized
    if (dayTimeSlots.isEmpty) {
      dayTimeSlots = weekdays.map((day) => DayTimeSlot(
        day: day,
        isSelected: false,
        openTime: "09:00 AM",
        closeTime: "06:00 PM",
        timeSlotSelections: {
          "Morning (9AM-12PM)": false,
          "Afternoon (12PM-5PM)": false,
          "Evening (5PM-9PM)": false,
        },
      )).toList();
    }
    getEditVendorDetails();
  }

  captureVendor(BuildContext context) async {
    List<String> weekdaysSeleted = [];
    String defaultOpenTime = "09:00 AM";
    String defaultCloseTime = "06:00 PM";
    
    // Get selected days based on isSelected flag
    for (var daySlot in dayTimeSlots) {
      if (daySlot.isSelected) {
        weekdaysSeleted.add(daySlot.day);
        // Use first selected day's time as default, or use the day's specific time
        if (defaultOpenTime == "09:00 AM" && daySlot.openTime.isNotEmpty) {
          defaultOpenTime = daySlot.openTime;
        }
        if (defaultCloseTime == "06:00 PM" && daySlot.closeTime.isNotEmpty) {
          defaultCloseTime = daySlot.closeTime;
        }
      }
    }
    
    // If no days selected, use first day's time or default
    if (weekdaysSeleted.isEmpty) {
      CommonWidget.errorShowSnackBarFor(context, "Please select at least one time slot");
      return;
    }
    
    // Use the most common time or first selected day's time
    // For now, using the first selected day's time slots
    DayTimeSlot? firstSelected = dayTimeSlots.firstWhere(
      (slot) => slot.isSelected,
      orElse: () => dayTimeSlots[0],
    );
    
    var response = await dataManager!.editCaptureVendor(
        shopNameController.text,
        emailController.text,
        mobileController.text,
        imageURl,
        firstSelected.openTime,
        firstSelected.closeTime,
        weekdaysSeleted,
        long,
        late,
        addressController.text,
        context);
    var data = CaptureVendorBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      sharedPreferences!
          .setString(Constant.vendorId, data.data?.newBusinessData?.sId ?? "");
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      CommonWidget.safePop(context, result: true);
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  postImage(BuildContext context) async {
    if (!mounted || !context.mounted) return;
    
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
      
      // Show loading indicator
      if (!mounted || !context.mounted) return;
      
      // Store navigator state before showing dialog
      final navigator = Navigator.of(context);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      var response = await dataManager!.postImage(
        image,
        context,
        skipAutoNavigation: true, // Skip auto-navigation to handle 401 ourselves
      );
      
      // Close loading indicator - pop the dialog route
      if (mounted && context.mounted) {
        try {
          // Use the navigator to pop the dialog (most recent route)
          if (navigator.canPop()) {
            navigator.pop();
          }
        } catch (e) {
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
          CommonWidget.errorShowSnackBarFor(context, "Session expired. Please save your shop details and login again.");
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
      // Close loading indicator if still open - find and close any open dialogs
      if (mounted) {
        try {
          // Try to find and close the dialog by checking if we can pop
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } catch (popError) {
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: CommonWidget.buildAppBarBackButton(
          context,
          iconColor: Colors.black87,
          onPressed: () => CommonWidget.safePop(context, result: true),
        ),
        title: const Text(
          "Edit Shop Details",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: "Pop600",
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info text
            Text(
              "Please add the shop details for user better experience.",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontFamily: "Pop400",
              ),
            ),
            const SizedBox(height: 24),
            // Profile Picture Section
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
                        color: Colors.grey[300]!,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: selectedFiles.isNotEmpty
                          ? CommonWidget.determineImageAsset(selectedFiles[0].path ?? "")
                          : networkImage.isNotEmpty
                              ? CommonWidget.determineImageInternetNew(networkImage)
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
                                                  setState(() {
                                                    selectedFiles.clear();
                            selectedFiles.addAll(data);
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
                              color: Colors.black.withOpacity(0.1),
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
                                ),
            const SizedBox(height: 32),
            // Shop Name
            _buildTextFieldWithLabel(
              label: "Shop Name",
              controller: shopNameController,
              hint: "Enter shop name",
              icon: Icons.store_outlined,
            ),
            const SizedBox(height: 20),
            
            // Email
            _buildTextFieldWithLabel(
              label: "Email Address (Optional)",
              controller: emailController,
              hint: "Enter email address",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              isOptional: true,
            ),
            const SizedBox(height: 20),
            
            // Mobile
            _buildTextFieldWithLabel(
              label: "Mobile Number",
              controller: mobileController,
              hint: "Enter mobile number",
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            // Address
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Address",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    fontFamily: "Pop500",
                  ),
                ),
                const SizedBox(height: 8),
                                AddressAutocompleteTextField(
                                    decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      color: ColorClass.base_color,
                      size: 22,
                    ),
                                        focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: ColorClass.base_color,
                        width: 2,
                      ),
                    ),
                                        enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(
                        color: Colors.grey[300]!,
                                                width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                                        filled: true,
                    fillColor: Colors.white,
                    hintText: "Search location...",
                                        hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontFamily: "Pop400",
                    ),
                    suffixIcon: IconButton(
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.my_location,
                              color: ColorClass.base_color,
                            ),
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                    ),
                                        border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                                    mapsApiKey: 'AIzaSyBFtrosISezP-8z2NwTWKhD_5pNHoi0wRw',
                                    controller: addressController,
                  onSuggestionClick: (place) {
                                      setState(() {
                                        final address = place.formattedAddress ?? place.name ?? '';
                                        addressController.text = address;
                                        long = place.lng ?? 0.0;
                                        late = place.lat ?? 0.0;
                                      });
                                    },
                  language: 'en-US',
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Opening Hours - Custom Time Range Pickers
            Text(
              "Opening Hours",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontFamily: "Pop500",
              ),
            ),
            const SizedBox(height: 16),
            // Days with custom time range pickers
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: dayTimeSlots.map((daySlot) {
                  final isLast = dayTimeSlots.indexOf(daySlot) == dayTimeSlots.length - 1;
                  return Container(
                    decoration: BoxDecoration(
                      border: isLast ? null : Border(
                        bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day Checkbox Row
                          Row(
                            children: [
                              Checkbox(
                                value: daySlot.isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    daySlot.isSelected = value ?? false;
                                    // Set default times when selecting a day
                                    if (daySlot.isSelected && daySlot.openTime.isEmpty) {
                                      daySlot.openTime = "09:00 AM";
                                    }
                                    if (daySlot.isSelected && daySlot.closeTime.isEmpty) {
                                      daySlot.closeTime = "06:00 PM";
                                    }
                                  });
                                },
                                activeColor: ColorClass.base_color,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                daySlot.day,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  fontFamily: "Pop600",
                                ),
                              ),
                            ],
                          ),
                          // Time Range Pickers (shown when day is selected)
                          if (daySlot.isSelected) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTimeFieldForDay(
                                    daySlot: daySlot,
                                    isOpenTime: true,
                                    onTap: () => _selectTime(context, daySlot, true),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTimeFieldForDay(
                                    daySlot: daySlot,
                                    isOpenTime: false,
                                    onTap: () => _selectTime(context, daySlot, false),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                                      if (BaseActivity.checkEmptyField(
                                          editingController: shopNameController,
                                          message: "Please Enter Shop Name.",
                    context: context,
                  )) {
                                        return;
                  } else if (BaseActivity.checkEmptyField(
                                          editingController: mobileController,
                                          message: "Please Enter Mobile.",
                    context: context,
                  )) {
                                        return;
                  } else if (BaseActivity.checkEmptyField(
                                          editingController: addressController,
                                          message: "Please Enter Address.",
                    context: context,
                  )) {
                                        return;
                  } else if (selectedFiles.isEmpty && imageURl.isEmpty && networkImage.isEmpty) {
                    CommonWidget.errorShowSnackBarFor(
                      context,
                      "Please upload a vendor profile image. This is required.",
                    );
                    return;
                  } else {
                    // Validate time slots for selected days
                    bool hasInvalidTimeSlot = false;
                    for (var daySlot in dayTimeSlots) {
                      if (daySlot.isSelected) {
                        if (daySlot.openTime.isEmpty || daySlot.closeTime.isEmpty) {
                          CommonWidget.errorShowSnackBarFor(
                            context,
                            "Please set opening hours for ${daySlot.day}",
                          );
                          hasInvalidTimeSlot = true;
                          break;
                        }
                      }
                    }
                    if (hasInvalidTimeSlot) {
                                        return;
                    }
                                        captureVendor(context);
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
                  "Save Changes",
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
    );
  }

  Widget _buildTextFieldWithLabel({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            if (isOptional)
              Text(
                " (Optional)",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontFamily: "Pop400",
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: "Pop400",
            color: Colors.black87,
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
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ColorClass.base_color,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFieldForDay({
    required DayTimeSlot daySlot,
    required bool isOpenTime,
    required VoidCallback onTap,
  }) {
    String timeValue = isOpenTime ? daySlot.openTime : daySlot.closeTime;
    String label = isOpenTime ? "Open Time" : "Close Time";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            fontFamily: "Pop500",
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ColorClass.base_color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: ColorClass.base_color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    timeValue.isEmpty ? "Select time" : timeValue,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: "Pop400",
                      color: timeValue.isEmpty ? Colors.grey[400] : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, DayTimeSlot daySlot, bool isOpenTime) async {
    // Parse current time if available
    TimeOfDay? initialTime;
    String currentTime = isOpenTime ? daySlot.openTime : daySlot.closeTime;
    
    if (currentTime.isNotEmpty) {
      try {
        // Parse time string like "09:00 AM" or "06:00 PM"
        bool isPM = currentTime.toUpperCase().contains('PM');
        String timePart = currentTime.replaceAll(RegExp(r'[^\d:]'), '');
        List<String> parts = timePart.split(':');
        if (parts.length == 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);
          if (isPM && hour != 12) hour += 12;
          if (!isPM && hour == 12) hour = 0;
          initialTime = TimeOfDay(hour: hour, minute: minute);
        }
      } catch (e) {
        // If parsing fails, use default time
        initialTime = isOpenTime ? const TimeOfDay(hour: 9, minute: 0) : const TimeOfDay(hour: 18, minute: 0);
      }
    } else {
      // Default time based on open/close
      initialTime = isOpenTime ? const TimeOfDay(hour: 9, minute: 0) : const TimeOfDay(hour: 18, minute: 0);
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime!,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorClass.base_color,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format time as "HH:MM AM/PM"
        String hour = picked.hour.toString().padLeft(2, '0');
        String minute = picked.minute.toString().padLeft(2, '0');
        String period = picked.hour >= 12 ? 'PM' : 'AM';
        int displayHour = picked.hour;
        if (displayHour > 12) displayHour -= 12;
        if (displayHour == 0) displayHour = 12;
        
        String formattedTime = "${displayHour.toString().padLeft(2, '0')}:$minute $period";
        
        if (isOpenTime) {
          daySlot.openTime = formattedTime;
        } else {
          daySlot.closeTime = formattedTime;
        }
      });
    }
  }

  getEditVendorDetails()async{
    var response = await dataManager!.getVendorDetails(context);
    var data = EditVendorBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      shopNameController.text = data.data![0].displayName??"";
      emailController.text = data.data![0].officialEmail??"";
      mobileController.text = data.data![0].mobile??"";
      
      // Get default times from vendor data
      String defaultOpenTime = CommonWidget.convertToLocalTimeWithAMPM(data.data![0].openTime??"09:00 AM");
      String defaultCloseTime = CommonWidget.convertToLocalTimeWithAMPM(data.data![0].closeTime??"06:00 PM");
      
      setState(() {
        addressController.text = data.data![0].location!.name??"";
        long = data.data![0].location!.coordinates!.long??0.0;
        late = data.data![0].location!.coordinates!.lat??0.0;
        networkImage = data.data![0].displayPicture??"";
        imageURl = data.data![0].displayPicture??"";
        
        // Ensure dayTimeSlots is initialized before updating
        if (dayTimeSlots.isEmpty || dayTimeSlots.length != weekdays.length) {
          dayTimeSlots = weekdays.map((day) => DayTimeSlot(
            day: day,
            isSelected: false,
            openTime: defaultOpenTime,
            closeTime: defaultCloseTime,
            timeSlotSelections: {
              "Morning (9AM-12PM)": false,
              "Afternoon (12PM-5PM)": false,
              "Evening (5PM-9PM)": false,
            },
          )).toList();
        }
        
        // Update day time slots with vendor's data
        for(int i = 0; i < weekdays.length && i < dayTimeSlots.length; i++){
          bool isDaySelected = data.data![0].daysAvailable.contains(weekdays[i]);
          dayTimeSlots[i].isSelected = isDaySelected;
          // Set default times for selected days (from account creation)
          if (isDaySelected) {
            dayTimeSlots[i].openTime = defaultOpenTime;
            dayTimeSlots[i].closeTime = defaultCloseTime;
          }
        }
      });
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

}
