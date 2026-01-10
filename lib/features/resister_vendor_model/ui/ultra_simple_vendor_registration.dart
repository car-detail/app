import 'dart:convert';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/Common/UXHelperWidget.dart';
import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:car_app/features/home_module/model/category_model_data.dart';
import 'package:car_app/features/resister_vendor_model/datamanager/add_shop_data_manager.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_places_autocomplete_widgets/widgets/address_autocomplete_textfield.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

/// Ultra-simplified vendor registration - designed for layman users
/// Only 2 steps: Basic Info + Location
class UltraSimpleVendorRegistration extends StatefulWidget {
  const UltraSimpleVendorRegistration({super.key});

  @override
  State<UltraSimpleVendorRegistration> createState() => _UltraSimpleVendorRegistrationState();
}

class _UltraSimpleVendorRegistrationState extends State<UltraSimpleVendorRegistration> {
  int _currentStep = 0;
  final int _totalSteps = 2;
  late final PageController _pageController;

  // Only essential fields
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Auto-filled or smart defaults
  String _selectedCategory = "Car Wash"; // Default
  String _selectedCategoryId = "";
  double _currentLat = 0.0;
  double _currentLng = 0.0;
  String? _selectedPlaceId;

  // Data managers
  AddShopDataManager? addShopDataManager;
  SharedPreferences? sharedPreferences;
  List<CategoryData> _categories = [];

  // Smart defaults - no need for user to configure
  final String _defaultOpenTime = "9:00 AM";
  final String _defaultCloseTime = "6:00 PM";
  final List<String> _defaultDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  final String _defaultCapacity = "5-8 cars per hour";
  final String _defaultDuration = "30-60 minutes";

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializeData();
  }

  void _initializeData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    addShopDataManager = AddShopDataManager(sharedPreferences!);
    
    // Auto-fill shop name from user's name if available
    final firstName = sharedPreferences?.getString(Constant.firstName) ?? "";
    final lastName = sharedPreferences?.getString(Constant.lastName) ?? "";
    if (firstName.isNotEmpty) {
      _shopNameController.text = "$firstName's Car Service";
    }

    // Fetch categories and auto-select first one
    await _fetchCategories();
    
    // Auto-get current location
    await _getCurrentLocation();
  }

  Future<void> _fetchCategories() async {
    try {
      var response = await addShopDataManager!.getcategory(context);
      if (response.statusCode == 200) {
        var data = CategoryModelData.fromJson(jsonDecode(response.body));
        if (data.status == "success" && data.data != null && data.data!.isNotEmpty) {
          setState(() {
            _categories = data.data!;
            _selectedCategory = _categories.first.categoryTitle ?? "Car Wash";
            _selectedCategoryId = _categories.first.sId ?? "";
          });
        }
      }
    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });
      
      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final address = "${place.street}, ${place.locality}, ${place.administrativeArea}";
        _addressController.text = address;
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step >= 0 && step < _totalSteps) {
      setState(() {
        _currentStep = step;
      });
      _pageController.jumpToPage(step);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          // Go back to previous step
          _goToStep(_currentStep - 1);
          return false; // Don't pop the route
        }
        return true; // Pop the route (go back to previous screen)
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              if (_currentStep > 0) {
                _goToStep(_currentStep - 1);
              } else {
                CommonWidget.safePop(context);
              }
            },
          ),
          title: Text(
            "Register Your Business",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Simple progress indicator
            _buildSimpleProgress(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildStep1BasicInfo(),
                  _buildStep2Location(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? ColorClass.base_color
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _currentStep == 0 ? "Step 1: Tell us about your business" : "Step 2: Where is your business?",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ColorClass.base_color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: ColorClass.base_color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Just 2 simple steps! We'll set everything else up for you.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // Shop Name
          Text(
            "What's your business name?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This is what customers will see",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _shopNameController,
            decoration: InputDecoration(
              hintText: "Example: John's Car Wash",
              prefixIcon: Icon(Icons.store, color: ColorClass.base_color),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          
          // Business Type - Visual selection
          Text(
            "What type of business?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap to select (we'll set up services automatically)",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _categories.isEmpty
              ? Center(child: CircularProgressIndicator())
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _categories.take(6).map((category) {
                    final isSelected = _selectedCategory == category.categoryTitle;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category.categoryTitle ?? "";
                          _selectedCategoryId = category.sId ?? "";
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? ColorClass.base_color : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? ColorClass.base_color : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          category.categoryTitle ?? "",
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 20),
          UXHelperWidget.buildInfoBanner(
            message: "💡 Don't worry! You can add more services and change settings later from your dashboard.",
            icon: Icons.lightbulb_outline,
            backgroundColor: Colors.amber[50],
            iconColor: Colors.amber[700],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Where is your business located?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll use this to help customers find you",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          
          // Auto-location button
          if (_currentLat == 0.0 || _currentLng == 0.0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: Icon(Icons.my_location),
                label: Text("Use My Current Location"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorClass.base_color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          
          // Address field with Google Places
          Text(
            "Business Address",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          AddressAutocompleteTextField(
            mapsApiKey: "AIzaSyBFtrosISezP-8z2NwTWKhD_5pNHoi0wRw",
            controller: _addressController,
            onSuggestionClick: (place) {
              setState(() {
                _addressController.text = place.formattedAddress ?? place.name ?? "";
                // Note: Place model doesn't have placeId, using name as identifier if needed
                _selectedPlaceId = place.name ?? place.formattedAddress;
                if (place.lat != null && place.lng != null) {
                  _currentLat = place.lat!;
                  _currentLng = place.lng!;
                }
              });
            },
            decoration: InputDecoration(
              hintText: "Type your business address or tap 'Use My Location' above",
              prefixIcon: Icon(Icons.location_on, color: ColorClass.base_color),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          // Smart defaults info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "We'll set these for you:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDefaultInfo("Hours", "$_defaultOpenTime - $_defaultCloseTime"),
                _buildDefaultInfo("Days Open", _defaultDays.join(", ")),
                _buildDefaultInfo("Service Duration", _defaultDuration),
                const SizedBox(height: 8),
                Text(
                  "You can change all of these later!",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _goToStep(_currentStep - 1);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: ColorClass.base_color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Back",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _currentStep == _totalSteps - 1 ? _completeRegistration : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorClass.base_color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? "Complete Registration" : "Next",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      _goToStep(_currentStep + 1);
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_shopNameController.text.trim().isEmpty) {
        UXHelperWidget.showFriendlyError(
          context,
          "Please enter your business name. This is what customers will see!",
        );
        return false;
      }
      if (_selectedCategory.isEmpty) {
        UXHelperWidget.showFriendlyError(
          context,
          "Please select your business type by tapping on one of the options above!",
        );
        return false;
      }
    } else if (_currentStep == 1) {
      if (_addressController.text.trim().isEmpty) {
        UXHelperWidget.showFriendlyError(
          context,
          "Please enter your business address. You can use the 'Use My Location' button or type it in!",
        );
        return false;
      }
      if (_currentLat == 0.0 || _currentLng == 0.0) {
        UXHelperWidget.showFriendlyError(
          context,
          "Please make sure we have your location. Tap 'Use My Location' or select an address!",
        );
        return false;
      }
    }
    return true;
  }

  void _completeRegistration() async {
    if (!_validateCurrentStep()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Setting up your business...",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    try {
      final userEmail = sharedPreferences?.getString(Constant.email) ?? "";
      final userMobile = sharedPreferences?.getString(Constant.mobile) ?? "";

      // Call API to create vendor with service
      var response = await addShopDataManager!.captureVendor(
        _shopNameController.text.trim(),
        userEmail,
        userMobile,
        "", // profile image
        _defaultOpenTime,
        _defaultCloseTime,
        _shopNameController.text.trim(), // service title
        "Professional car service", // about
        _defaultCapacity,
        "0", // price - can be set later
        _defaultDuration,
        _selectedCategory,
        _selectedCategoryId,
        [], // detail images
        "", // cover image
        _defaultDays,
        _currentLng,
        _currentLat,
        _addressController.text.trim(),
        context,
      );

      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context); // Close loading
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final vendorData = responseData['data'];
          String? vendorId;
          
          if (vendorData['newBusinessData'] != null) {
            final businessData = vendorData['newBusinessData'];
            vendorId = businessData['_id']?.toString() ?? 
                      businessData['id']?.toString() ?? 
                      businessData['vendorId']?.toString();
          }
          
          if (vendorId != null && vendorId.isNotEmpty) {
            await sharedPreferences?.setString(Constant.vendorId, vendorId);
          }
        }

        UXHelperWidget.showSuccessMessage(
          context,
          "🎉 Success! Your business is now registered! You can start adding services and packages from your dashboard.",
        );

        // Navigate to dashboard
        CommonWidget.navigateToKillAllScreen(context, const DashboardActivity());
      } else {
        UXHelperWidget.showFriendlyError(
          context,
          "Something went wrong. Please check your internet connection and try again.",
        );
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
      if (context.mounted) {
        UXHelperWidget.showFriendlyError(
          context,
          "Error: ${e.toString()}. Please try again or contact support.",
        );
      }
    }
  }
}

