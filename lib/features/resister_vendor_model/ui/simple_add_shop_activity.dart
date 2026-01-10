import 'dart:convert';

import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:car_app/features/home_module/model/category_model_data.dart';
import 'package:car_app/features/log_in/data_manager/LoginDataManager.dart';
import 'package:car_app/features/log_in/ui/modern_login_activity.dart';
import 'package:car_app/features/resister_vendor_model/datamanager/add_shop_data_manager.dart';
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

class _SimpleAddShopActivityState extends State<SimpleAddShopActivity> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 2; // Reduced from 3 to 2 steps

  // Form controllers
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();

  // Location data
  double _currentLat = 0.0;
  double _currentLng = 0.0;
  String? _selectedPlaceId; // Store Google Places place_id
  bool _isGettingLocation = false;

  // Data managers
  AddShopDataManager? addShopDataManager;
  LoginDataManager? loginDataManager;
  SharedPreferences? sharedPreferences;

  // Selected values with smart defaults
  String _selectedBusinessType = "";
  String _selectedBusinessTypeId = "";
  String _selectedServiceDuration = "30-60 minutes";
  String _selectedCapacity = "5-8 cars per hour";
  String _selectedOperatingHours = "9 AM - 6 PM";
  List<String> _selectedDays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday"
  ];
  bool _useSmartDefaults = true; // Default to using smart defaults

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
      _shopNameController.text = "$firstName's ${_selectedBusinessType.isNotEmpty ? _selectedBusinessType : 'Business'}";
    }
    
    // Auto-get current location
    _getCurrentLocation();
  }

  void _updateShopNameWithCategory() {
    // Update shop name if it was auto-populated with category
    final firstName = sharedPreferences?.getString(Constant.firstName) ?? "";
    if (firstName.isNotEmpty && _shopNameController.text.contains("'s")) {
      // Only update if it looks like our auto-generated format
      _shopNameController.text = "$firstName's ${_selectedBusinessType.isNotEmpty ? _selectedBusinessType : 'Business'}";
    }
  }

  Future<void> _fetchCategories() async {
    print("🔍 Starting to fetch categories...");
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      if (addShopDataManager == null) {
        print("❌ addShopDataManager is null!");
        return;
      }

      var response = await addShopDataManager!.getcategory(context);
      print("🔍 Category API response status: ${response.statusCode}");
      print("🔍 Category API response body: ${response.body}");

      if (response.statusCode != 200) {
        print("❌ API returned error status: ${response.statusCode}");
        throw Exception("API returned status ${response.statusCode}");
      }

      var data = CategoryModelData.fromJson(jsonDecode(response.body));

      if (data.status == "success" && data.data != null) {
        setState(() {
          _categories = data.data!;
          print("🔍 Loaded ${_categories.length} categories from database");
          for (var cat in _categories) {
            print("🔍 Category: ${cat.categoryTitle} (ID: ${cat.sId})");
          }
          if (_categories.isNotEmpty) {
            _selectedBusinessType = _categories.first.categoryTitle ?? "";
            _selectedBusinessTypeId = _categories.first.sId ?? "";
            print(
                "🔍 Auto-selected: $_selectedBusinessType (ID: $_selectedBusinessTypeId)");
            // Update shop name if it was auto-populated
            _updateShopNameWithCategory();
          }
        });
      } else {
        print("❌ API returned error: ${data.message}");
        throw Exception("API returned error: ${data.message}");
      }
    } catch (e) {
      print("❌ Error fetching categories: $e");
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
          _selectedBusinessType = _categories.first.categoryTitle ?? "";
          _selectedBusinessTypeId = _categories.first.sId ?? "";
          _updateShopNameWithCategory();
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
      print("🔍 Building SimpleAddShopActivity - Step: $_currentStep");
      print("🔍 Categories loaded: ${_categories.length}");
      print("🔍 Selected business type: $_selectedBusinessType");

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
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: _previousStep,
                  )
                : null,
            title: Text(
              "Add Your Shop",
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
              // Progress indicator
              _buildProgressIndicator(),
              // Page content
              Expanded(
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
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      );
    } catch (e) {
      print("❌ Error in build method: $e");
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => CommonWidget.safePop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
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
    return Padding(
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
                    "Don't worry! You can add more services and change this later from your dashboard.",
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
            "Tap to select the type that best describes your business",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoadingCategories)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Loading business types..."),
                  ],
                ),
              ),
            )
          else if (_categories.isEmpty)
            const Expanded(
              child: Center(
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
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return _buildCategoryCard(category);
                },
              ),
            ),
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
            _buildInputField(
              controller: _shopNameController,
              label: "Business Name",
              icon: Icons.store,
              hint: "e.g., Mike's Car Wash",
              isRequired: true,
            ),
            const SizedBox(height: 20),
            _buildAddressField(),
            const SizedBox(height: 24),
            
            // Smart Defaults Option
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
                      Icon(Icons.auto_awesome, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Smart Defaults (Recommended)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
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
                          });
                        },
                        activeColor: Colors.blue[700],
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
                          _buildDefaultPreviewRow("Hours", "9 AM - 6 PM (Monday-Saturday)"),
                          const SizedBox(height: 8),
                          _buildDefaultPreviewRow("Service Duration", "30-60 minutes"),
                          const SizedBox(height: 8),
                          _buildDefaultPreviewRow("Capacity", "5-8 cars per hour"),
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
                  _buildDropdownField(
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
                  _buildDropdownField(
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
                  _buildOperatingHoursField(),
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
  
  Widget _buildDefaultPreviewRow(String label, String value) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green[600], size: 16),
        const SizedBox(width: 8),
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
            _buildDropdownField(
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
            _buildDropdownField(
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
            // Operating Hours
            _buildOperatingHoursField(),
            const SizedBox(height: 20),
            // Working Days
            _buildWorkingDaysField(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryData category) {
    final isSelected = _selectedBusinessType == category.categoryTitle;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
                _selectedBusinessType = category.categoryTitle ?? "";
            _selectedBusinessTypeId = category.sId ?? "";
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
                        child: Image.network(
                          category.logoImage!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Icon(
                              Icons.category,
                              color: ColorClass.base_color,
                              size: 24,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Icon(
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
    bool isAutoPopulated = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (isRequired)
              const Text(
                " *",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            if (isAutoPopulated) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Text(
                  "Auto-filled",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: ColorClass.base_color),
            hintText: hint ?? "Enter $label",
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
        ),
      ],
    );
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
            Container(
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
          if (place.administrativeArea?.isNotEmpty == true)
            parts.add(place.administrativeArea!);
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
            if (place.administrativeArea?.isNotEmpty == true)
              parts.add(place.administrativeArea!);
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

  Future<void> _getCurrentLocation({bool showLoading = false}) async {
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
      print("Location fetch error (non-critical): $e");
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
              value: value,
              isExpanded: true,
              icon:
                  Icon(Icons.keyboard_arrow_down, color: ColorClass.base_color),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      Icon(icon, color: ColorClass.base_color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
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
          "Which days do you work?",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _workingDays.map((day) {
            final isSelected = _selectedDays.contains(day);
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDays.remove(day);
                  } else {
                    _selectedDays.add(day);
                  }
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? ColorClass.base_color : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected ? ColorClass.base_color : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  day,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        if (_selectedBusinessType.isEmpty || _selectedBusinessTypeId.isEmpty) {
          CommonWidget.errorShowSnackBarFor(
              context, "Please select a business category to continue");
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
      // Get user details from SharedPreferences
      final userEmail = sharedPreferences?.getString(Constant.email) ?? "";
      final userMobile = sharedPreferences?.getString(Constant.mobile) ?? "";

      // Parse operating hours - use smart defaults if enabled
      String openTime, closeTime;
      List<String> workingDays;
      
      if (_useSmartDefaults) {
        // Use smart defaults
        openTime = "9:00 AM";
        closeTime = "6:00 PM";
        workingDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
      } else {
        // Use user-selected values
        if (_selectedOperatingHours == "Custom hours" ||
            _selectedOperatingHours.contains(":")) {
          openTime = _customOpenTime;
          closeTime = _customCloseTime;
        } else {
          final parts = _selectedOperatingHours.split(" - ");
          openTime = parts[0];
          closeTime = parts[1];
        }
        workingDays = _selectedDays.isEmpty 
            ? ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"] // Fallback
            : _selectedDays;
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
      print("🔍 Selected Category Name: $_selectedBusinessType");
      print("🔍 Selected Category ID: $_selectedBusinessTypeId");

      // Call the API to save shop details
      var response = await addShopDataManager!.captureVendor(
        _shopNameController.text,
        userEmail,
        userMobile,
        "",
        // profile image URL
        openTime,
        // open time
        closeTime,
        // close time
        _shopNameController.text,
        // title
        "Business description",
        // about
        _useSmartDefaults ? "5-8 cars per hour" : _selectedCapacity,
        // time slot (capacity)
        "0",
        // price
        _useSmartDefaults ? "30-60 minutes" : _selectedServiceDuration,
        // duration
        _selectedBusinessType,
        // category name
        _selectedBusinessTypeId,
        // category ID
        [],
        // detail images
        "",
        // cover image
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
      print("🔍 API Response Status: ${response.statusCode}");
      print("🔍 API Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        CommonWidget.successShowSnackBarFor(
            context, "Shop details saved successfully!");

        // Parse response to get vendorId and save it
        try {
          final responseData = jsonDecode(response.body);
          print("🔍 Full API Response: $responseData");

          if (responseData['status'] == 'success' &&
              responseData['data'] != null) {
            final vendorData = responseData['data'];
            print("🔍 Vendor Data: $vendorData");

            if (vendorData['newBusinessData'] != null) {
              final businessData = vendorData['newBusinessData'];
              print("🔍 Business Data: $businessData");

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
                print("🔍 Saving vendorId to SharedPreferences: $vendorId");
                await sharedPreferences?.setString(Constant.vendorId, vendorId);
                print("✅ VendorId saved successfully");

                // Debug: Print all SharedPreferences values
                print("🔍 All SharedPreferences after saving:");
                final keys = sharedPreferences?.getKeys() ?? {};
                for (String key in keys) {
                  final value = sharedPreferences?.getString(key);
                  print("🔍 $key: $value");
                }
              } else {
                print("❌ No vendorId found in response");
              }
            } else {
              print("❌ No newBusinessData in response");
            }
          } else {
            print("❌ API response not successful: ${responseData['status']}");
          }
        } catch (e) {
          print("❌ Error parsing vendor response: $e");
        }

        // Navigate to dashboard instead of popping
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardActivity()),
          (route) => false, // Remove all previous routes
        );
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
                      const ModernLoginActivity(isSignUp: false),
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
        print(
            "❌ API Error - Status: ${response.statusCode}, Body: ${response.body}");
        try {
          final responseData = jsonDecode(response.body);
          final errorMessage =
              responseData['message'] ?? 'Failed to save shop details';
          print("❌ API Error Message: $errorMessage");
          CommonWidget.errorShowSnackBarFor(context, errorMessage);
        } catch (e) {
          print("❌ Error parsing API response: $e");
          CommonWidget.errorShowSnackBarFor(
              context, "Failed to save shop details. Please try again.");
        }
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context); // Close loading dialog
      }
      print("❌ Error in _saveShopDetails: $e");
      CommonWidget.errorShowSnackBarFor(context, "Error: ${e.toString()}");
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
