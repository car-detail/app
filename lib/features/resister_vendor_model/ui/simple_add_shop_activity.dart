import 'dart:convert';
import 'dart:io';

import 'package:car_app/Common/BaseActivity.dart';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:car_app/features/home_module/model/category_model_data.dart';
import 'package:car_app/features/log_in/data_manager/LoginDataManager.dart';
import 'package:car_app/features/log_in/ui/new_login_activity.dart';
import 'package:car_app/features/resister_vendor_model/datamanager/add_shop_data_manager.dart';
import 'package:car_app/features/services_model/data_manager/services_data_manager.dart';
import 'package:car_app/features/resister_vendor_model/ui/widgets/shop_form_fields.dart';
import 'package:car_app/design_system/components/timeout_network_image.dart';
import 'package:car_app/Models/image_module_data.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_places_autocomplete_widgets/widgets/address_autocomplete_textfield.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleAddShopActivity extends StatefulWidget {
  const SimpleAddShopActivity({super.key});

  @override
  State<SimpleAddShopActivity> createState() => _SimpleAddShopActivityState();
}

// Class to hold time slots for each day
class DayTimeSlot {
  final String day;
  bool isSelected;
  String openTime;
  String closeTime;
  Map<String, bool> timeSlotSelections; // Kept for backward compatibility but not used in UI

  DayTimeSlot({
    required this.day,
    this.isSelected = false,
    this.openTime = "",
    this.closeTime = "",
    Map<String, bool>? timeSlotSelections,
  }) : timeSlotSelections = timeSlotSelections ?? <String, bool>{
          "(3:00 AM) - (2:00 PM)": false,
          "(2:00 PM) - (10:00 PM)": false,
          "(10:00 PM) - (6:00 AM)": false,
        };
  
  // Initialize timeSlotSelections if it's empty
  void ensureTimeSlotSelections() {
    if (timeSlotSelections.isEmpty) {
      timeSlotSelections = <String, bool>{
        "(3:00 AM) - (2:00 PM)": false,
        "(2:00 PM) - (10:00 PM)": false,
        "(10:00 PM) - (6:00 AM)": false,
      };
    }
  }
}

class _SimpleAddShopActivityState extends State<SimpleAddShopActivity> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 2; // Reduced from 3 to 2 steps

  // Form controllers
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  // Mobile number is not needed in UI - it comes from OTP verification (SharedPreferences)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _serviceAboutController = TextEditingController();

  // Service images (Multi-image support)
  final List<String> _detailImages = [];
  final List<File> _selectedDetailFiles = [];
  bool _isUploadingDetailImages = false;

  // Location data
  double _currentLat = 0.0;
  double _currentLng = 0.0;
  String? _selectedPlaceId; // Store Google Places place_id
  bool _isGettingLocation = false;

  // Shop image
  final List<File> _shopImageFiles = [];
  String _shopImageUrl = "";
  bool _isUploadingImage = false;

  // Data managers
  AddShopDataManager? addShopDataManager;
  LoginDataManager? loginDataManager;
  SharedPreferences? sharedPreferences;
  ServicesDataManager? servicesDataManager;

  // Selected values with smart defaults - now supports multiple selections
  final List<String> _selectedBusinessTypes = [];
  final List<String> _selectedBusinessTypeIds = [];
  String _selectedServiceDuration = "30-60 minutes";
  String _selectedCapacity = "5-8 cars per hour";
  String _selectedOperatingHours = "9 AM - 6 PM";
  final List<String> _selectedDays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday"
  ];
  bool _useSmartDefaults = true; // Default to using smart defaults
  bool _isAdvancedSettingsExpanded = false; // Track expansion state of advanced settings
  bool _smartDefaultsAcknowledged = false; // Track if user has acknowledged smart defaults

  // Time slot periods based on the grid image (3 time slots as shown)
  final List<String> _timeSlotPeriods = [
    "(3:00 AM) - (2:00 PM)",
    "(2:00 PM) - (10:00 PM)",
    "(10:00 PM) - (6:00 AM)",
  ];

  // Day-time slot grid data structure - initialize with all days
  final List<DayTimeSlot> _dayTimeSlots = [
    DayTimeSlot(day: "Mon"),
    DayTimeSlot(day: "Tue"),
    DayTimeSlot(day: "Wed"),
    DayTimeSlot(day: "Thu"),
    DayTimeSlot(day: "Fri"),
    DayTimeSlot(day: "Sat"),
    DayTimeSlot(day: "Sun"),
  ];

  // Dynamic categories from database
  List<CategoryData> _categories = [];
  bool _isLoadingCategories = false;

  final List<String> _serviceDurations = [
    "15-30 minutes",
    "30-60 minutes",
    "1-2 hours",
    "2-4 hours",
    "Half day (4-6 hours)",
    "Full day (6+ hours)",
  ];

  final List<String> _capacityOptions = [
    "1-2 cars per hour",
    "3-4 cars per hour",
    "5-8 cars per hour",
    "9+ cars per hour",
  ];

  final List<String> _operatingHours = [
    "6 AM - 10 PM",
    "7 AM - 9 PM",
    "8 AM - 8 PM",
    "9 AM - 6 PM",
    "10 AM - 7 PM",
    "Custom hours",
  ];

  String _customOpenTime = "9:00 AM";
  String _customCloseTime = "6:00 PM";

  final List<String> _workingDays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    addShopDataManager = AddShopDataManager(sharedPreferences!);
    loginDataManager = LoginDataManager(sharedPreferences!);
    servicesDataManager = ServicesDataManager(sharedPreferences!);

    // Day-time slots are already initialized in the state variable
    // Just ensure they have the correct time slot selections
    for (var daySlot in _dayTimeSlots) {
      daySlot.ensureTimeSlotSelections();
    }

    // Auto-populate user details
    _populateUserDetails();

    // Fetch categories from database
    await _fetchCategories();
  }

  void _populateUserDetails() {
    // Auto-populate shop name from user's name
    final firstName = sharedPreferences?.getString(Constant.firstName) ?? "";
    final lastName = sharedPreferences?.getString(Constant.lastName) ?? "";
    if (firstName.isNotEmpty) {
      String businessTypeText = _selectedBusinessTypes.isNotEmpty 
          ? _selectedBusinessTypes.join(" & ")
          : 'Business';
      _shopNameController.text = "$firstName's $businessTypeText";
    }
    
    // Load location from step 1 (user account creation) if available
    final savedLocation = sharedPreferences?.getString(Constant.location) ?? "";
    final savedLat = double.tryParse(sharedPreferences?.getString(Constant.lat) ?? "0.0") ?? 0.0;
    final savedLng = double.tryParse(sharedPreferences?.getString(Constant.long) ?? "0.0") ?? 0.0;
    
    if (savedLocation.isNotEmpty && savedLat != 0.0 && savedLng != 0.0) {
      // Use location from step 1
      setState(() {
        _shopAddressController.text = savedLocation;
        _currentLat = savedLat;
        _currentLng = savedLng;
      });
    } else {
      // If no saved location, get current GPS location
      _getCurrentLocation();
    }
  }

  void _updateShopNameWithCategory() {
    // Update shop name if it was auto-populated with category
    final firstName = sharedPreferences?.getString(Constant.firstName) ?? "";
    if (firstName.isNotEmpty && _shopNameController.text.contains("'s")) {
      // Only update if it looks like our auto-generated format
      String businessTypeText = _selectedBusinessTypes.isNotEmpty 
          ? _selectedBusinessTypes.join(" & ")
          : 'Business';
      _shopNameController.text = "$firstName's $businessTypeText";
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      if (addShopDataManager == null) {
        return;
      }

      var response = await addShopDataManager!.getcategory(context);

      if (response.statusCode != 200) {
        throw Exception("API returned status ${response.statusCode}");
      }

      var data = CategoryModelData.fromJson(jsonDecode(response.body));

      if (mounted && data.status == "success" && data.data != null) {
        setState(() {
          _categories = data.data!;
          for (var cat in _categories) {
          }
          if (_categories.isNotEmpty) {
            // Auto-select first category (optional - user can change)
            final firstCategory = _categories.first;
            if (!_selectedBusinessTypes.contains(firstCategory.categoryTitle ?? "")) {
              _selectedBusinessTypes.add(firstCategory.categoryTitle ?? "");
              _selectedBusinessTypeIds.add(firstCategory.sId ?? "");
              // Update shop name if it was auto-populated
              _updateShopNameWithCategory();
            }
          }
        });
      } else {
        throw Exception("API returned error: ${data.message}");
      }
    } catch (e) {
      // Don't show error snackbar as it might cause issues
      // CommonWidget.errorShowSnackBarFor(context, "Failed to load categories");

      // Set fallback categories to prevent white screen
      setState(() {
        _categories = [
          CategoryData(sId: "fallback1", categoryTitle: "Car Wash"),
          CategoryData(sId: "fallback2", categoryTitle: "Car Detailing"),
          CategoryData(sId: "fallback3", categoryTitle: "Maintenance"),
        ];
        if (_categories.isNotEmpty) {
          // Auto-select first category (optional - user can change)
          final firstCategory = _categories.first;
          if (!_selectedBusinessTypes.contains(firstCategory.categoryTitle ?? "")) {
            _selectedBusinessTypes.add(firstCategory.categoryTitle ?? "");
            _selectedBusinessTypeIds.add(firstCategory.sId ?? "");
            _updateShopNameWithCategory();
          }
        }
      });
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {

      return GestureDetector(
        onTap: () {
          // Tap outside handler - no longer needed with Google Places autocomplete
        },
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: _currentStep > 0
                ? CommonWidget.buildAppBarBackButton(
                    context,
                    iconColor: Colors.black87,
                    onPressed: _previousStep,
                  )
                : CommonWidget.buildAppBarBackButton(
                    context,
                    iconColor: Colors.black87,
                  ),
            title: const Text(
              "Add Your Shop",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Progress indicator
                  _buildProgressIndicator(),
                  // Page content with bottom padding for fixed button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80), // Space for fixed button
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentStep = index;
                          });
                        },
                        children: [
                          _buildBusinessTypeStep(),
                          _buildBasicInfoStep(), // Combined with optional operating details
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Fixed navigation buttons at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _buildNavigationButtons(),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: CommonWidget.buildAppBarBackButton(
            context,
            iconColor: Colors.black,
          ),
          title: const Text(
            "Add Your Shop",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                "Something went wrong",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please try again or contact support",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    // Reset state and try again
                    _categories = [];
                    _isLoadingCategories = false;
                  });
                  _fetchCategories();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorClass.base_color,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  "Try Again",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin:
                      EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? ColorClass.base_color
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _currentStep == 0 
                ? "Step 1 of 2: Choose your business type"
                : "Step 2 of 2: Tell us about your business",
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

  Widget _buildBusinessTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "You can select multiple business types if you offer both services. Don't worry, you can change this later from your dashboard.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "What type of business do you run?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap to select one or more types that describe your business",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoadingCategories)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading business types..."),
                ],
              ),
            )
          else if (_categories.isEmpty)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No categories available"),
                  SizedBox(height: 8),
                  Text("Please check your internet connection", style: TextStyle(fontSize: 12)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryCard(category);
              },
            ),
          const SizedBox(height: 24),
          // Service Gallery (Multi-image)
          const Text(
            "Service Gallery Photos (Optional)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Add up to 5 photos of your previous work",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailImageUploadArea(),
          const SizedBox(height: 20),

          ShopInputField(
            controller: _serviceAboutController,
            label: "Service Description",
            icon: Icons.description_outlined,
            hint: "Describe your main service...",
            maxLines: 2,
            isRequired: false,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorClass.base_color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorClass.base_color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: ColorClass.base_color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Almost done! Just fill in your business details and you're ready to go.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ShopInputField(
              controller: _shopNameController,
              label: "Business Name",
              icon: Icons.store,
              hint: "e.g., Mike's Car Wash",
              isRequired: true,
            ),
            const SizedBox(height: 20),
            ShopInputField(
              controller: _emailController,
              label: "Email Address (Optional)",
              icon: Icons.email,
              hint: "e.g., business@example.com",
              keyboardType: TextInputType.emailAddress,
              isRequired: false,
            ),
            const SizedBox(height: 20),
            _buildShopImageField(),
            const SizedBox(height: 20),
            _buildAddressField(),
            const SizedBox(height: 24),
            
            // Smart Defaults Option
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _useSmartDefaults && !_smartDefaultsAcknowledged
                      ? Colors.orange[400]!
                      : Colors.blue[200]!,
                  width: _useSmartDefaults && !_smartDefaultsAcknowledged ? 2 : 1,
                ),
                boxShadow: _useSmartDefaults && !_smartDefaultsAcknowledged
                    ? [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Smart Defaults (Recommended)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                      if (_useSmartDefaults && !_smartDefaultsAcknowledged)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[400],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Please review",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "We'll set operating hours, service duration, and capacity automatically. You can change these later from your dashboard.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[800],
                            height: 1.4,
                          ),
                        ),
                      ),
                      Switch(
                        value: _useSmartDefaults,
                        onChanged: (value) {
                          setState(() {
                            _useSmartDefaults = value;
                            if (!value) {
                              _smartDefaultsAcknowledged = false;
                              _isAdvancedSettingsExpanded = true;
                            }
                          });
                        },
                        activeThumbColor: Colors.blue[700],
                      ),
                    ],
                  ),
                  if (_useSmartDefaults) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          ShopDefaultPreviewRow(label: "Hours", value: "9 AM - 6 PM (Monday-Saturday)"),
                          const SizedBox(height: 8),
                          ShopDefaultPreviewRow(label: "Service Duration", value: "30-60 minutes"),
                          const SizedBox(height: 8),
                          ShopDefaultPreviewRow(label: "Capacity", value: "5-8 cars per hour"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _smartDefaultsAcknowledged
                            ? Colors.green[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _smartDefaultsAcknowledged
                              ? Colors.green[300]!
                              : Colors.orange[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _smartDefaultsAcknowledged,
                            onChanged: (value) {
                              setState(() {
                                _smartDefaultsAcknowledged = value ?? false;
                              });
                            },
                            activeColor: Colors.green[700],
                            checkColor: Colors.white,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _smartDefaultsAcknowledged = !_smartDefaultsAcknowledged;
                                });
                              },
                              child: Text(
                                "I understand and accept these smart defaults. I can change these settings later from my dashboard.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                  fontWeight: _smartDefaultsAcknowledged
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Optional: Advanced Settings (only shown if smart defaults is off)
            if (!_useSmartDefaults) ...[
              const SizedBox(height: 24),
              ExpansionTile(
                initiallyExpanded: _isAdvancedSettingsExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _isAdvancedSettingsExpanded = expanded;
                  });
                },
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 16),
                title: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Advanced Settings (Optional)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                children: [
                  ShopDropdownField(
                    label: "Service Duration",
                    value: _selectedServiceDuration,
                    options: _serviceDurations,
                    onChanged: (value) {
                      setState(() {
                        _selectedServiceDuration = value!;
                      });
                    },
                    icon: Icons.schedule,
                  ),
                  const SizedBox(height: 16),
                  ShopDropdownField(
                    label: "Capacity",
                    value: _selectedCapacity,
                    options: _capacityOptions,
                    onChanged: (value) {
                      setState(() {
                        _selectedCapacity = value!;
                      });
                    },
                    icon: Icons.directions_car,
                  ),
                  const SizedBox(height: 16),
                  _buildWorkingDaysField(),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildOperatingDetailsStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Operating Details",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Set up your service details",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            // Service Duration
            ShopDropdownField(
              label: "How long does each service take?",
              value: _selectedServiceDuration,
              options: _serviceDurations,
              onChanged: (value) {
                setState(() {
                  _selectedServiceDuration = value!;
                });
              },
              icon: Icons.schedule,
            ),
            const SizedBox(height: 20),
            // Capacity
            ShopDropdownField(
              label: "How many cars can you handle per hour?",
              value: _selectedCapacity,
              options: _capacityOptions,
              onChanged: (value) {
                setState(() {
                  _selectedCapacity = value!;
                });
              },
              icon: Icons.directions_car,
            ),
            const SizedBox(height: 20),
            // Working Days and Time Slots
            _buildWorkingDaysField(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryData category) {
    final categoryTitle = category.categoryTitle ?? "";
    final categoryId = category.sId ?? "";
    final isSelected = _selectedBusinessTypes.contains(categoryTitle);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              // Remove from selection
              _selectedBusinessTypes.remove(categoryTitle);
              _selectedBusinessTypeIds.remove(categoryId);
            } else {
              // Add to selection
              _selectedBusinessTypes.add(categoryTitle);
              _selectedBusinessTypeIds.add(categoryId);
            }
            _updateShopNameWithCategory();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorClass.base_color.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? ColorClass.base_color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorClass.base_color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: category.logoImage != null &&
                        category.logoImage!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TimeoutNetworkImage(
                          url: category.logoImage!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          fallback: Icon(
                            Icons.category,
                            color: ColorClass.base_color,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(Icons.category,
                        color: ColorClass.base_color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.categoryTitle ?? "",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? ColorClass.base_color : Colors.black87,
                      ),
                    ),
                    if (category.categoryDescription != null &&
                        category.categoryDescription!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          category.categoryDescription!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: ColorClass.base_color,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDetailImageUploadArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _isUploadingDetailImages ? null : _pickDetailImages,
          child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorClass.base_color.withOpacity(0.3),
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: _isUploadingDetailImages
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: ColorClass.base_color, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        "Tap to select images",
                        style: TextStyle(
                          color: ColorClass.base_color,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_detailImages.isNotEmpty || _selectedDetailFiles.isNotEmpty)
          Container(
            height: 110,
            margin: const EdgeInsets.only(top: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _detailImages.length + _selectedDetailFiles.length,
              itemBuilder: (context, index) {
                if (index < _detailImages.length) {
                  return _buildDetailImagePreview(index, true, _detailImages[index]);
                } else {
                  int fileIndex = index - _detailImages.length;
                  return _buildDetailImagePreview(index, false, "", _selectedDetailFiles[fileIndex]);
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDetailImagePreview(int index, bool isUploaded, String url, [File? file]) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isUploaded
                ? Image.network(url, fit: BoxFit.cover)
                : Image.file(file!, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isUploaded) {
                    _detailImages.removeAt(index);
                  } else {
                    _selectedDetailFiles.remove(file);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          if (!isUploaded)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_upload, color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDetailImages() async {
    try {
      final List<File>? pickedFiles = await BaseActivity.pickImage(true);
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        if (_detailImages.length + _selectedDetailFiles.length + pickedFiles.length > 5) {
          if (mounted) {
            CommonWidget.errorShowSnackBarFor(context, "You can only upload up to 5 images");
          }
          return;
        }
        
        setState(() {
          _selectedDetailFiles.addAll(pickedFiles);
        });
        
        // Auto-upload
        await _uploadDetailImages();
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  Future<void> _uploadDetailImages() async {
    if (_selectedDetailFiles.isEmpty) return;
    
    setState(() {
      _isUploadingDetailImages = true;
    });

    try {
      // Upload files one by one to match the single-file backend API
      for (int i = 0; i < _selectedDetailFiles.length; i++) {
        File file = _selectedDetailFiles[i];
        
        if (mounted) {
          // You could show specific progress here if needed
          debugPrint("Uploading image ${i + 1} of ${_selectedDetailFiles.length}");
        }

        var response = await addShopDataManager!.postImage([file], context, skipAutoNavigation: true);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          var data = ImageModuleData.fromJson(jsonDecode(response.body));
          if (data.status == "success" && data.data?.url != null) {
            setState(() {
              _detailImages.add(data.data!.url!);
            });
          }
        } else {
          debugPrint("Failed to upload image $i: ${response.statusCode}");
          if (mounted) {
            CommonWidget.errorShowSnackBarFor(context, "Failed to upload image ${i + 1}");
          }
        }
      }
      
      setState(() {
        _selectedDetailFiles.clear();
      });
    } catch (e) {
      debugPrint("Error uploading detail images: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingDetailImages = false;
        });
      }
    }
  }

  Widget _buildShopImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              "Shop Image",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              " *",
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isUploadingImage ? null : _pickShopImage,
          child: Container(
            width: double.infinity,
            height: _shopImageUrl.isNotEmpty || _shopImageFiles.isNotEmpty ? 250 : 150,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _shopImageUrl.isNotEmpty || _shopImageFiles.isNotEmpty
                    ? ColorClass.base_color
                    : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _isUploadingImage
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text(
                            "Uploading...",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _shopImageUrl.isNotEmpty || _shopImageFiles.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            _shopImageFiles.isNotEmpty
                                ? Image.file(
                                    _shopImageFiles[0],
                                    fit: BoxFit.cover,
                                  )
                                : _shopImageUrl.isNotEmpty
                                    ? Image.network(
                                        _shopImageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(
                                                Icons.error_outline,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : const SizedBox(),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _shopImageFiles.clear();
                                    _shopImageUrl = "";
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap to add shop image",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickShopImage() async {
    var data = await BaseActivity.pickmedia(false);
    if (data != null && data.isNotEmpty) {
      setState(() {
        _shopImageFiles.clear();
        _shopImageFiles.addAll(data);
      });
      await _uploadShopImage();
    }
  }

  Future<void> _uploadShopImage() async {
    if (_shopImageFiles.isEmpty) return;

    if (!mounted || !context.mounted) return;

    setState(() {
      _isUploadingImage = true;
    });

    // Store dialog context to prevent navigation issues
    BuildContext? dialogContext;

    try {
      // Check if access token exists before uploading
      String? accessToken = sharedPreferences?.getString(Constant.accessToken);
      if (accessToken == null || accessToken.isEmpty) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Session expired. Please login again.");
        }
        return;
      }

      var response = await addShopDataManager!.postImage(
        _shopImageFiles,
        context,
        skipAutoNavigation: true, // Prevent auto-navigation
      );

      // Close any loading dialog that might have been shown
      if (mounted && dialogContext != null && dialogContext.mounted) {
        try {
          Navigator.of(dialogContext).pop();
        } catch (e) {
        }
      }

      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          var data = ImageModuleData.fromJson(jsonDecode(response.body));
          if (data.status == "success" && data.data?.url != null) {
            setState(() {
              _shopImageUrl = data.data!.url ?? "";
              _shopImageFiles.clear(); // Clear files after successful upload
            });
            if (mounted && context.mounted) {
              CommonWidget.successShowSnackBarFor(context, "Shop image uploaded successfully!");
            }
          } else {
            if (mounted && context.mounted) {
              CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to upload image");
            }
          }
        } catch (e) {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, "Error parsing upload response");
          }
        }
      } else if (response.statusCode == 401) {
        // Handle 401 without navigating away
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Session expired. Please login again.");
        }
      } else {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Failed to upload image. Status code: ${response.statusCode}");
        }
      }
    } catch (e) {
      // sendMultipartRequest already shows an error snackbar before re-throwing,
      // so we avoid showing a duplicate. We only show a message here for the
      // specific case where the server may have received the image but the
      // response could not be read (network drop after upload).
      if (mounted && context.mounted) {
        final msg = e.toString();
        if (!msg.contains('Failed to upload') &&
            !msg.contains('File not found') &&
            !msg.contains('File size exceeds') &&
            !msg.contains('Unsupported file format') &&
            !msg.contains('Error reading file')) {
          // Unexpected error not already surfaced by sendMultipartRequest
          CommonWidget.errorShowSnackBarFor(
              context,
              "Upload status unknown — please check your connection and verify the image before retrying.");
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              "Business Address",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              " *",
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AddressAutocompleteTextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.location_on, color: ColorClass.base_color),
                  hintText: "Start typing your address...",
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
                    borderSide: BorderSide(color: ColorClass.base_color, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                mapsApiKey: 'AIzaSyBFtrosISezP-8z2NwTWKhD_5pNHoi0wRw',
                controller: _shopAddressController,
                onSuggestionClick: (place) {
                  setState(() {
                    final address = place.formattedAddress ?? place.name ?? '';
                    _shopAddressController.text = address;
                    _currentLat = place.lat ?? 0.0;
                    _currentLng = place.lng ?? 0.0;
                    // Use formattedAddress as identifier - backend can search by location.name
                    // Note: To get actual place_id, we'd need to make an additional Google Places API call
                    _selectedPlaceId = address.isNotEmpty ? address : null;
                  });
                },
                language: 'en-US',
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGettingLocation ? null : () => _getCurrentLocation(showLoading: true),
                icon: _isGettingLocation 
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: const Text("Current"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorClass.base_color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Type to search for addresses or use current location",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Removed unused address search methods - now using Google Places autocomplete

  String _formatReadableAddress(Placemark place) {
    List<String> addressParts = [];

    // Build a natural, readable address like normal people write
    // Start with building number and street
    if (place.subThoroughfare?.isNotEmpty == true &&
        place.thoroughfare?.isNotEmpty == true) {
      addressParts.add('${place.subThoroughfare} ${place.thoroughfare}');
    } else if (place.thoroughfare?.isNotEmpty == true) {
      addressParts.add(place.thoroughfare!);
    } else if (place.street?.isNotEmpty == true) {
      addressParts.add(place.street!);
    }

    // Add area/neighborhood
    if (place.subLocality?.isNotEmpty == true) {
      addressParts.add(place.subLocality!);
    }

    // Add city
    if (place.locality?.isNotEmpty == true) {
      addressParts.add(place.locality!);
    }

    // Add state/province
    if (place.administrativeArea?.isNotEmpty == true) {
      addressParts.add(place.administrativeArea!);
    }

    // Add postal code if available
    if (place.postalCode?.isNotEmpty == true) {
      addressParts.add(place.postalCode!);
    }

    // Add country
    if (place.country?.isNotEmpty == true) {
      addressParts.add(place.country!);
    }

    // Remove duplicates and empty strings
    addressParts =
        addressParts.where((part) => part.isNotEmpty).toSet().toList();

    if (addressParts.isNotEmpty) {
      return addressParts.join(', ');
    } else {
      return 'Current Location';
    }
  }

  Future<String> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      // First attempt: Try to get placemarks
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        // Try to find the best placemark with the most complete address
        Placemark? bestPlace;
        int maxScore = 0;

        for (Placemark place in placemarks) {
          int score = 0;
          if (place.street?.isNotEmpty == true) score += 3;
          if (place.locality?.isNotEmpty == true) score += 2;
          if (place.administrativeArea?.isNotEmpty == true) score += 2;
          if (place.country?.isNotEmpty == true) score += 1;
          if (place.postalCode?.isNotEmpty == true) score += 1;

          if (score > maxScore) {
            maxScore = score;
            bestPlace = place;
          }
        }

        if (bestPlace != null) {
          String address = _formatReadableAddress(bestPlace);

          // If we got a good address, return it
          if (address.isNotEmpty && address != 'Current Location') {
            return address;
          }
        }
      }

      // Second attempt: Try to build address from any available data
      if (placemarks.isNotEmpty) {
        for (Placemark place in placemarks) {
          List<String> parts = [];

          // Try different combinations
          if (place.street?.isNotEmpty == true) parts.add(place.street!);
          if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
          if (place.administrativeArea?.isNotEmpty == true) {
            parts.add(place.administrativeArea!);
          }
          if (place.country?.isNotEmpty == true) parts.add(place.country!);

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      }

      // Third attempt: Try with a more general search
      try {
        List<Placemark> placemarks2 = await placemarkFromCoordinates(
          latitude,
          longitude,
        );

        for (Placemark place in placemarks2) {
          if (place.locality?.isNotEmpty == true ||
              place.administrativeArea?.isNotEmpty == true) {
            List<String> parts = [];
            if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
            if (place.administrativeArea?.isNotEmpty == true) {
              parts.add(place.administrativeArea!);
            }
            if (place.country?.isNotEmpty == true) parts.add(place.country!);

            if (parts.isNotEmpty) {
              return parts.join(', ');
            }
          }
        }
      } catch (e) {
        // Continue to fallback
      }

      // Final fallback: Return a simple, readable address
      return 'Business Location, GPS Coordinates (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
    } catch (e) {
      // If all attempts fail, return a simple, readable address
      return 'Business Location, GPS Coordinates (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
    }
  }

  Future<void> _getCurrentLocation({bool showLoading = false, bool forceGPS = false}) async {
    // If not forcing GPS, check for saved location from step 1 first
    if (!forceGPS) {
      final savedLocation = sharedPreferences?.getString(Constant.location) ?? "";
      final savedLat = double.tryParse(sharedPreferences?.getString(Constant.lat) ?? "0.0") ?? 0.0;
      final savedLng = double.tryParse(sharedPreferences?.getString(Constant.long) ?? "0.0") ?? 0.0;
      
      if (savedLocation.isNotEmpty && savedLat != 0.0 && savedLng != 0.0) {
        // Use location from step 1
        if (mounted) {
          setState(() {
            _shopAddressController.text = savedLocation;
            _currentLat = savedLat;
            _currentLng = savedLng;
          });
        }
        if (context.mounted && showLoading) {
          CommonWidget.successShowSnackBarFor(
              context, 'Location loaded from your profile!');
        }
        return;
      }
    }
    
    // If no saved location or forceGPS is true, get current GPS location
    if (_isGettingLocation) return; // Prevent multiple simultaneous calls
    
    setState(() {
      _isGettingLocation = true;
    });
    
    try {
      if (showLoading) {
        // Only show loading dialog if explicitly requested (user clicked button)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showLoading && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        if (context.mounted && showLoading) {
          CommonWidget.errorShowSnackBarFor(
              context, 'Location services are disabled. Please enable them.');
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (showLoading && context.mounted && Navigator.canPop(context)) {
            CommonWidget.safePop(context);
          }
          // Don't show error if auto-fetching, just return silently
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (showLoading && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Changed to medium for faster response
        timeLimit: const Duration(seconds: 5), // Reduced timeout
      );

      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });

      // Get address from coordinates with multiple attempts
      String address = await _getAddressFromCoordinates(
          position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _shopAddressController.text = address;
        });
      }

      if (showLoading && context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
      if (context.mounted && showLoading) {
        CommonWidget.successShowSnackBarFor(
            context, 'Location updated successfully!');
      }
    } catch (e) {
      if (showLoading && context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
      // Don't show error if auto-fetching failed, user can manually enter address
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }


  Widget _buildOperatingHoursField() {
    // Create a dynamic list that includes custom hours if set
    List<String> dropdownItems = List.from(_operatingHours);

    // If we have custom hours, add them to the list
    if (_selectedOperatingHours != "Custom hours" &&
        _selectedOperatingHours.contains(":") &&
        !_operatingHours.contains(_selectedOperatingHours)) {
      // Insert custom hours at the beginning (after "Custom hours")
      int customIndex = dropdownItems.indexOf("Custom hours");
      if (customIndex != -1) {
        dropdownItems.insert(customIndex + 1, _selectedOperatingHours);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What are your operating hours?",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedOperatingHours,
              isExpanded: true,
              icon:
                  Icon(Icons.keyboard_arrow_down, color: ColorClass.base_color),
              items: dropdownItems.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                          option == "Custom hours"
                              ? Icons.settings
                              : option.contains(":")
                                  ? Icons.schedule
                                  : Icons.access_time,
                          color: ColorClass.base_color,
                          size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            color: option == "Custom hours"
                                ? Colors.orange
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == "Custom hours") {
                  _openCustomTimeDialog();
                } else {
                  setState(() {
                    _selectedOperatingHours = value!;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void _openCustomTimeDialog() {
    TimeOfDay? selectedOpenTime;
    TimeOfDay? selectedCloseTime;

    // Parse current custom times
    try {
      selectedOpenTime = _parseTimeString(_customOpenTime);
      selectedCloseTime = _parseTimeString(_customCloseTime);
    } catch (e) {
      selectedOpenTime = const TimeOfDay(hour: 9, minute: 0);
      selectedCloseTime = const TimeOfDay(hour: 18, minute: 0);
    }

    showDialog(
      context: context,
      builder: (context) => _CustomTimeDialog(
        initialOpenTime: selectedOpenTime!,
        initialCloseTime: selectedCloseTime!,
        onTimeSelected: (openTime, closeTime) {
          setState(() {
            _customOpenTime = _formatTimeOfDay(openTime);
            _customCloseTime = _formatTimeOfDay(closeTime);
            _selectedOperatingHours = "$_customOpenTime - $_customCloseTime";
          });
        },
      ),
    );
  }

  TimeOfDay _parseTimeString(String timeString) {
    try {
      final parts = timeString.replaceAll(RegExp(r'\s'), '').split(':');
      final timePart = parts[1].split('M')[0];
      final period = parts[1].contains('PM') ? 'PM' : 'AM';

      int hour = int.parse(parts[0]);
      int minute = int.parse(timePart);

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Widget _buildWorkingDaysField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Opening Hours",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
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
            children: _dayTimeSlots.map((daySlot) {
              final isLast = _dayTimeSlots.indexOf(daySlot) == _dayTimeSlots.length - 1;
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
                                // Update _selectedDays based on daySlot.isSelected
                                final fullDayName = _getFullDayName(daySlot.day);
                                if (daySlot.isSelected && !_selectedDays.contains(fullDayName)) {
                                  _selectedDays.add(fullDayName);
                                } else if (!daySlot.isSelected && _selectedDays.contains(fullDayName)) {
                                  _selectedDays.remove(fullDayName);
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
      ],
    );
  }

  String _getFullDayName(String shortDay) {
    final dayMap = {
      "Mon": "Monday",
      "Tue": "Tuesday",
      "Wed": "Wednesday",
      "Thu": "Thursday",
      "Fri": "Friday",
      "Sat": "Saturday",
      "Sun": "Sunday",
    };
    return dayMap[shortDay] ?? shortDay;
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

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: ColorClass.base_color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Previous",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep == _totalSteps - 1
                  ? _saveShopDetails
                  : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorClass.base_color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? "Complete Setup ✨" : "Next",
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
      ),
    );
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_selectedBusinessTypes.isEmpty || _selectedBusinessTypeIds.isEmpty) {
          CommonWidget.errorShowSnackBarFor(
              context, "Please select at least one business category to continue");
          return false;
        }
        return true;
      case 1:
        if (_shopNameController.text.trim().isEmpty) {
          CommonWidget.errorShowSnackBarFor(
              context, "Please enter your business name");
          return false;
        }
        if (_shopAddressController.text.trim().isEmpty) {
          CommonWidget.errorShowSnackBarFor(
              context, "Please enter your business address. You can use the 'Current' button or type it in.");
          return false;
        }
        // Mobile number is not required in UI - it comes from OTP verification (SharedPreferences)
        // Validation for mobile number is done in _saveShopDetails method
        // Email address is optional - no validation needed
        // Validate smart defaults acknowledgment if enabled
        if (_useSmartDefaults && !_smartDefaultsAcknowledged) {
          CommonWidget.errorShowSnackBarFor(
              context, "Please acknowledge the smart defaults by checking the confirmation box");
          return false;
        }
        // Validate that at least one day is selected with valid times (if not using smart defaults)
        if (!_useSmartDefaults) {
          bool hasValidDay = _dayTimeSlots.any((slot) => 
            slot.isSelected && 
            slot.openTime.isNotEmpty && 
            slot.closeTime.isNotEmpty
          );
          if (!hasValidDay) {
            CommonWidget.errorShowSnackBarFor(
                context, "Please select at least one day and set its opening hours");
            return false;
          }
        }
        // Location coordinates are optional - user can enter address manually
        // If they have coordinates, validate them, but don't require them
        return true;
      default:
        return true;
    }
  }

  void _saveShopDetails() async {
    if (!_validateCurrentStep()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get mobile number from SharedPreferences (stored during OTP verification)
      final userMobile = sharedPreferences?.getString(Constant.mobile) ?? "";
      final userEmail = _emailController.text.trim(); // Email is optional
      
      // Validate required fields
      if (userMobile.isEmpty) {
        if (context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context); // Close loading
        }
        CommonWidget.errorShowSnackBarFor(context, "Mobile number not found. Please verify OTP again.");
        return;
      }

      // Parse operating hours - use smart defaults if enabled
      String openTime, closeTime;
      List<String> workingDays;
      
      if (_useSmartDefaults) {
        // Use smart defaults
        openTime = "9:00 AM";
        closeTime = "6:00 PM";
        workingDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
      } else {
        // Use user-selected values from day time slots
        // Get the first selected day's times, or use defaults
        DayTimeSlot? firstSelected = _dayTimeSlots.firstWhere(
          (slot) => slot.isSelected && slot.openTime.isNotEmpty && slot.closeTime.isNotEmpty,
          orElse: () => _dayTimeSlots.firstWhere(
            (slot) => slot.isSelected,
            orElse: () => _dayTimeSlots[0],
          ),
        );
        
        if (firstSelected.isSelected && firstSelected.openTime.isNotEmpty && firstSelected.closeTime.isNotEmpty) {
          openTime = firstSelected.openTime;
          closeTime = firstSelected.closeTime;
        } else {
          // Fallback to defaults
          openTime = "9:00 AM";
          closeTime = "6:00 PM";
        }
        
        // Build working days list from selected day slots
        workingDays = _dayTimeSlots
            .where((slot) => slot.isSelected && slot.openTime.isNotEmpty && slot.closeTime.isNotEmpty)
            .map((slot) => _getFullDayName(slot.day))
            .toList();
        
        // If no days selected, use fallback
        if (workingDays.isEmpty) {
          workingDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        }
      }

      // Prepare address for API - prioritize place_id for backend lookup
      String apiAddress;
      if (_selectedPlaceId != null && _selectedPlaceId!.isNotEmpty) {
        // Use place_id so backend can look up vendor by place_id
        apiAddress = _selectedPlaceId!;
      } else {
        // Fallback to formatted address
        apiAddress = _shopAddressController.text;
        
        // If the address contains coordinates, try to get a better address
        if (apiAddress.contains("Lat:") ||
            apiAddress.contains("Current Location") ||
            apiAddress.contains("GPS Coordinates")) {
          try {
            // Try to get a better address from coordinates
            String betterAddress =
                await _getAddressFromCoordinates(_currentLat, _currentLng);
            if (!betterAddress.contains("Lat:") &&
                !betterAddress.contains("Current Location") &&
                !betterAddress.contains("GPS Coordinates")) {
              apiAddress = betterAddress;
            } else {
              // If we still can't get a good address, create a simple one
              apiAddress =
                  'Business Location, GPS Coordinates (${_currentLat.toStringAsFixed(4)}, ${_currentLng.toStringAsFixed(4)})';
            }
          } catch (e) {
            // Fallback to a simple coordinate format
            apiAddress =
                'Business Location, GPS Coordinates (${_currentLat.toStringAsFixed(4)}, ${_currentLng.toStringAsFixed(4)})';
          }
        }
      }

      // Debug: Print selected category details
      
      // Use first selected category for API (backend currently accepts single category)
      // TODO: Update backend to accept multiple categories
      String primaryCategoryName = _selectedBusinessTypes.isNotEmpty 
          ? _selectedBusinessTypes.first 
          : "";
      String primaryCategoryId = _selectedBusinessTypeIds.isNotEmpty 
          ? _selectedBusinessTypeIds.first 
          : "";

      // Call the API to save shop details
      var response = await addShopDataManager!.captureVendor(
        _shopNameController.text,
        userEmail,
        userMobile,
        _shopImageUrl.isNotEmpty ? _shopImageUrl : "",
        // profile image URL (shop image)
        openTime,
        // open time
        closeTime,
        // close time
        _shopNameController.text,
        // title
        _serviceAboutController.text.isEmpty ? "Professional car service" : _serviceAboutController.text.trim(),
        // about
        _useSmartDefaults ? "5-8 cars per hour" : _selectedCapacity,
        // time slot (capacity)
        "0",
        // price
        _useSmartDefaults ? "30-60 minutes" : _selectedServiceDuration,
        // duration
        primaryCategoryName,
        // category name (first selected)
        primaryCategoryId,
        // category ID (first selected)
        _detailImages,
        // detail images
        _shopImageUrl.isNotEmpty ? _shopImageUrl : "",
        // cover image (shop image)
        workingDays,
        // working days
        _currentLng,
        // longitude
        _currentLat,
        // latitude
        apiAddress,
        // address name - now guaranteed to be readable
        context,
      );

      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context); // Close loading dialog
      }

      // Parse the response

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update user profile image as well to ensure it's saved with "all three" (vendor, user, service)
        try {
          final userId = sharedPreferences?.getString(Constant.id) ?? "";
          final firstName = sharedPreferences?.getString(Constant.firstName) ?? "";
          final lastName = sharedPreferences?.getString(Constant.lastName) ?? "";
          
          if (userId.isNotEmpty && _shopImageUrl.isNotEmpty) {
            await loginDataManager?.postUserDetails(
              firstName,
              lastName,
              userEmail.isNotEmpty ? userEmail : (sharedPreferences?.getString(Constant.email) ?? ""),
              _shopImageUrl,
              userId,
              context,
            );
            // Save to local storage as well
            await sharedPreferences?.setString(Constant.image, _shopImageUrl);
          }
        } catch (userUpdateError) {
          debugPrint("Note: User profile image sync failed, but shop was created: $userUpdateError");
        }

        if (mounted) {
          CommonWidget.successShowSnackBarFor(
              context, "Shop details saved successfully!");
        }


        // Parse response to get vendorId and save it
        try {
          final responseData = jsonDecode(response.body);

          if (responseData['status'] == 'success' &&
              responseData['data'] != null) {
            final vendorData = responseData['data'];

            if (vendorData['newBusinessData'] != null) {
              final businessData = vendorData['newBusinessData'];

              // Try different possible field names for the vendor ID
              String? vendorId;
              if (businessData['_id'] != null) {
                vendorId = businessData['_id'].toString();
              } else if (businessData['id'] != null) {
                vendorId = businessData['id'].toString();
              } else if (businessData['vendorId'] != null) {
                vendorId = businessData['vendorId'].toString();
              }

              if (vendorId != null && vendorId.isNotEmpty) {
                await sharedPreferences?.setString(Constant.vendorId, vendorId);

                // Create additional services for remaining categories
                // First category was already created with the vendor
                if (_selectedBusinessTypes.length > 1) {
                  await _createAdditionalServices(
                    vendorId,
                    userMobile,
                    _useSmartDefaults ? "5-8 cars per hour" : _selectedCapacity,
                    _useSmartDefaults ? "30-60 minutes" : _selectedServiceDuration,
                    _shopImageUrl.isNotEmpty ? _shopImageUrl : "",
                  );
                }

                // Debug: Print all SharedPreferences values
                final keys = sharedPreferences?.getKeys() ?? {};
                for (String key in keys) {
                  final value = sharedPreferences?.getString(key);
                }
              } else {
              }
            } else {
            }
          } else {
          }
        } catch (e) {
        }

        // Navigate to dashboard instead of popping
        // Use a small delay to ensure proper navigation and allow dashboard to initialize
        await Future.delayed(const Duration(milliseconds: 300));
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardActivity()),
            (route) => false, // Remove all previous routes
          );
        }
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Session Expired"),
            content: const Text(
                "Your session has expired. Please login again to continue."),
            actions: [
              TextButton(
                onPressed: () => CommonWidget.safePop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  CommonWidget.safePop(context); // Close dialog
                  if (context.mounted) {
                    CommonWidget.navigateToKillAllScreen(
                      context,
                      const NewLoginActivity(),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorClass.base_color,
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      } else {
        // Other errors
        try {
          final responseData = jsonDecode(response.body);
          final errorMessage =
              responseData['message'] ?? 'Failed to save shop details';
          CommonWidget.errorShowSnackBarFor(context, errorMessage);
        } catch (e) {
          CommonWidget.errorShowSnackBarFor(
              context, "Failed to save shop details. Please try again.");
        }
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context); // Close loading dialog
      }
      CommonWidget.errorShowSnackBarFor(context, "Error: ${e.toString()}");
    }
  }

  // Create additional services for remaining categories
  Future<void> _createAdditionalServices(
    String vendorId,
    String mobile,
    String capacity,
    String duration,
    String coverImage,
  ) async {
    if (servicesDataManager == null) {
      return;
    }

    // Skip first category as it was already created with the vendor
    for (int i = 1; i < _selectedBusinessTypes.length; i++) {
      final categoryName = _selectedBusinessTypes[i];
      final categoryId = _selectedBusinessTypeIds[i];
      
      
      try {
        final response = await servicesDataManager!.postServies(
          context,
          _shopNameController.text, // serviceTitle
          "Business description", // about
          capacity, // timeSlotCapacity
          "0", // price
          duration, // serviceDuration
          categoryName, // categoryName
          categoryId, // categoryId
          coverImage, // coverImage
          _detailImages, // detailImages
          mobile, // mobile
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
        } else {
        }
      } catch (e) {
        // Continue with next category even if one fails
      }
    }
    
  }
}

class BusinessTypeOption {
  final String name;
  final IconData icon;
  final Color color;

  BusinessTypeOption(this.name, this.icon, this.color);
}

class _CustomTimeDialog extends StatefulWidget {
  final TimeOfDay initialOpenTime;
  final TimeOfDay initialCloseTime;
  final Function(TimeOfDay openTime, TimeOfDay closeTime) onTimeSelected;

  const _CustomTimeDialog({
    required this.initialOpenTime,
    required this.initialCloseTime,
    required this.onTimeSelected,
  });

  @override
  State<_CustomTimeDialog> createState() => _CustomTimeDialogState();
}

class _CustomTimeDialogState extends State<_CustomTimeDialog> {
  late TimeOfDay _openTime;
  late TimeOfDay _closeTime;

  @override
  void initState() {
    super.initState();
    _openTime = widget.initialOpenTime;
    _closeTime = widget.initialCloseTime;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Set Custom Hours",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => CommonWidget.safePop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Opening Time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Opening Time",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: _openTime,
                          );
                          if (picked != null) {
                            setState(() {
                              _openTime = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(_openTime),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Closing Time",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: _closeTime,
                          );
                          if (picked != null) {
                            setState(() {
                              _closeTime = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(_closeTime),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Selected Hours: ${_formatTime(_openTime)} - ${_formatTime(_closeTime)}",
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => CommonWidget.safePop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onTimeSelected(_openTime, _closeTime);
                      CommonWidget.safePop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorClass.base_color,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Set Hours",
                      style: TextStyle(color: Colors.white),
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

  String _formatTime(TimeOfDay time) {
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
