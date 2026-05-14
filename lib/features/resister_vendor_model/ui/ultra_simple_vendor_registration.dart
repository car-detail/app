import 'dart:convert';
import 'dart:io';
import 'package:car_app/Common/BaseActivity.dart';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/Common/UXHelperWidget.dart';
import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:car_app/features/home_module/model/category_model_data.dart';
import 'package:car_app/features/resister_vendor_model/ui/edit_vendor_activity.dart';
import 'package:car_app/features/log_in/ui/profile_activity.dart';
import 'package:car_app/features/resister_vendor_model/datamanager/add_shop_data_manager.dart';
import 'package:car_app/features/services_model/data_manager/services_data_manager.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_places_autocomplete_widgets/widgets/address_autocomplete_textfield.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final TextEditingController _serviceAboutController = TextEditingController();

  // Selected values - now supports multiple selections
  final List<String> _selectedCategories = [];
  final List<String> _selectedCategoryIds = [];
  double _currentLat = 0.0;
  double _currentLng = 0.0;

  // Data managers
  AddShopDataManager? addShopDataManager;
  ServicesDataManager? servicesDataManager;
  SharedPreferences? sharedPreferences;
  List<CategoryData> _categories = [];
  
  // Service images
  List<String> _detailImages = [];
  List<File> _selectedDetailFiles = [];
  bool _isUploadingImages = false;

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
    servicesDataManager = ServicesDataManager(sharedPreferences!);
    
    // Auto-fill shop name from user's name if available
    final firstName = sharedPreferences?.getString(Constant.firstName) ?? "";
    if (firstName.isNotEmpty) {
      _shopNameController.text = "$firstName's Car Service";
    }

    // Fetch categories and auto-select first one
    await _fetchCategories();
    
    // Auto-get current location
    await _getCurrentLocation();
  }

  bool _isLoadingCategories = false;
  String? _categoryError;

  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });
    
    try {
      if (addShopDataManager == null) {
        throw Exception("Unable to load business types. Please try again.");
      }
      
      var response = await addShopDataManager!.getcategory(context);
      
      if (response.statusCode == 200) {
        try {
          var data = CategoryModelData.fromJson(jsonDecode(response.body));
          if (data.status == "success" && data.data != null && data.data!.isNotEmpty) {
            if (mounted) {
              setState(() {
                _categories = data.data!;
                // Auto-select first category by default
                _selectedCategories.clear();
                _selectedCategoryIds.clear();
                _selectedCategories.add(_categories.first.categoryTitle ?? "Car Wash");
                _selectedCategoryIds.add(_categories.first.sId ?? "");
                _isLoadingCategories = false;
              });
            }
          } else {
            throw Exception("No business types available");
          }
        } catch (jsonError) {
          if (mounted) {
            setState(() {
              _categoryError = "Unable to load business types. Please check your connection.";
              _isLoadingCategories = false;
            });
          }
        }
      } else {
        throw Exception("Unable to load business types. Please try again.");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoryError = "Unable to load business types. Please check your connection and try again.";
          _isLoadingCategories = false;
          // Set fallback categories
          _categories = [
            CategoryData(sId: "fallback1", categoryTitle: "Car Wash"),
            CategoryData(sId: "fallback2", categoryTitle: "Car Detailing"),
            CategoryData(sId: "fallback3", categoryTitle: "Auto Repair"),
          ];
          if (_categories.isNotEmpty) {
            _selectedCategories.clear();
            _selectedCategoryIds.clear();
            _selectedCategories.add(_categories.first.categoryTitle ?? "Car Wash");
            _selectedCategoryIds.add(_categories.first.sId ?? "");
          }
        });
      }
    }
  }

  bool _isGettingLocation = false;

  Future<void> _getCurrentLocation({bool showError = true}) async {
    if (!mounted || _isGettingLocation) return;
    
    setState(() {
      _isGettingLocation = true;
    });
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted && showError && context.mounted) {
          UXHelperWidget.showFriendlyError(
            context,
            "Location services are disabled. Please enable them in your device settings to use this feature.",
          );
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted && showError && context.mounted) {
            UXHelperWidget.showFriendlyError(
              context,
              "Location permission is required to automatically fill your address. You can still type it manually.",
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted && showError && context.mounted) {
          UXHelperWidget.showFriendlyError(
            context,
            "Location permission is permanently denied. Please enable it in settings, or type your address manually.",
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Changed to medium for faster response
        timeLimit: const Duration(seconds: 10),
      );
      
      if (mounted) {
        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
        });
      }
      
      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks[0];
          final street = place.street ?? "";
          final locality = place.locality ?? "";
          final area = place.administrativeArea ?? "";
          final address = [street, locality, area].where((s) => s.isNotEmpty).join(", ");
          if (address.isNotEmpty) {
            setState(() {
              _addressController.text = address;
            });
          }
        }
      } catch (e) {
        // Location coordinates are set, user can type address manually
      }
    } catch (e) {
      if (mounted && showError && context.mounted) {
        UXHelperWidget.showFriendlyError(
          context,
          "Unable to get your location. Please type your address manually or try again.",
        );
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
          leading: CommonWidget.buildAppBarBackButton(
            context,
            iconColor: Colors.black,
            onPressed: () {
              if (_currentStep > 0) {
                _goToStep(_currentStep - 1);
              } else {
                CommonWidget.safePop(context);
              }
            },
          ),
          title: const Text(
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
          const Text(
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
          const Text(
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
          _isLoadingCategories
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          "Loading business types...",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : _categoryError != null
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _categoryError!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _fetchCategories,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text("Try Again"),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    )
                  : _categories.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "No business types available. Please contact support.",
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _categories.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final categoryTitle = category.categoryTitle ?? "";
                            final categoryId = category.sId ?? "";
                            final isSelected = _selectedCategories.contains(categoryTitle);

                            return InkWell(
                              onTap: () {
                                if (mounted) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedCategories.remove(categoryTitle);
                                      _selectedCategoryIds.remove(categoryId);
                                    } else {
                                      _selectedCategories.add(categoryTitle);
                                      _selectedCategoryIds.add(categoryId);
                                    }
                                  });
                                }
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
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: ColorClass.base_color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: category.logoImage != null && category.logoImage!.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: Image.network(
                                                category.logoImage!,
                                                width: 24,
                                                height: 24,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Icon(Icons.category, color: ColorClass.base_color, size: 24),
                                              ),
                                            )
                                          : Icon(Icons.category, color: ColorClass.base_color, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            categoryTitle,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected ? ColorClass.base_color : Colors.black87,
                                            ),
                                          ),
                                          if (category.categoryDescription != null && category.categoryDescription!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                category.categoryDescription!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
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
                            );
                          },
                        ),
          const SizedBox(height: 20),
          UXHelperWidget.buildInfoBanner(
            message: "💡 Don't worry! You can add more services and change settings later from your dashboard.",
            icon: Icons.lightbulb_outline,
            backgroundColor: Colors.amber[50],
            iconColor: Colors.amber[700],
          ),
          const SizedBox(height: 30),
          
          // Optional Service Images
          const Text(
            "Add Service Photos (Optional)",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Show customers your work! You can add up to 5 photos.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          UXHelperWidget.buildHelpfulInputField(
            context: context,
            controller: _serviceAboutController,
            label: "Service Description",
            icon: Icons.description_outlined,
            helpText: "Briefly tell customers what's included in this service.",
            example: "Quick exterior wash and tire polish.",
            maxLines: 2,
            isRequired: false,
          ),
          const SizedBox(height: 20),
          
          _buildImageUploadArea(),
          
          if (_detailImages.isNotEmpty || _selectedDetailFiles.isNotEmpty)
            Container(
              height: 100,
              margin: const EdgeInsets.only(top: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _detailImages.length + _selectedDetailFiles.length,
                itemBuilder: (context, index) {
                  bool isUploaded = index < _detailImages.length;
                  return _buildImagePreview(index, isUploaded);
                },
              ),
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
          const Text(
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
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: _isGettingLocation ? null : () => _getCurrentLocation(showError: true),
              icon: _isGettingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_isGettingLocation ? "Getting Location..." : "Use My Current Location"),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorClass.base_color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
            ),
          ),
          
          // Address field with Google Places
          const Text(
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

  Widget _buildImageUploadArea() {
    return InkWell(
      onTap: _isUploadingImages ? null : _pickServiceImages,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorClass.base_color.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              if (_isUploadingImages)
                const CircularProgressIndicator()
              else ...[
                Icon(Icons.add_a_photo_outlined, color: ColorClass.base_color, size: 40),
                const SizedBox(height: 12),
                Text(
                  "Tap to add photos",
                  style: TextStyle(
                    color: ColorClass.base_color,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _pickServiceImages() async {
    // Re-using common file picker
    BaseActivity.showFilePicker(
      context,
      (List<File>? files) async {
        if (files != null && files.isNotEmpty) {
          setState(() {
            _selectedDetailFiles = files.take(5).toList();
            _isUploadingImages = true;
          });
          
          // Upload each image
          List<String> uploadedUrls = [];
          for (var file in _selectedDetailFiles) {
            try {
              var response = await addShopDataManager!.postImage([file], context, skipAutoNavigation: true);
              if (response.statusCode == 200 || response.statusCode == 201) {
                var data = jsonDecode(response.body);
                if (data['status'] == "success" && data['data'] != null) {
                  uploadedUrls.add(data['data']);
                }
              }
            } catch (e) {
            }
          }
          
          if (mounted) {
            setState(() {
              _detailImages.addAll(uploadedUrls);
              _selectedDetailFiles.clear();
              _isUploadingImages = false;
            });
            
            if (uploadedUrls.isNotEmpty) {
              CommonWidget.successShowSnackBarFor(context, "Added ${uploadedUrls.length} photos!");
            }
          }
        }
      },
      isFile: false,
      isPhoto: true,
      isOnlyPhoto: true,
      allowMultipleImage: true,
    );
  }

  Widget _buildImagePreview(int index, bool isUploaded) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isUploaded
                ? Image.network(_detailImages[index], fit: BoxFit.cover)
                : Image.file(_selectedDetailFiles[index - _detailImages.length], fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 0,
          right: 12,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isUploaded) {
                  _detailImages.removeAt(index);
                } else {
                  _selectedDetailFiles.removeAt(index - _detailImages.length);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
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
      if (_selectedCategories.isEmpty) {
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
    if (!mounted || !context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
              ),
              const SizedBox(height: 16),
              Text(
                "Setting up your business...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This will only take a moment",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      if (!mounted || !context.mounted) return;
      
      final userEmail = sharedPreferences?.getString(Constant.email) ?? "";
      final userMobile = sharedPreferences?.getString(Constant.mobile) ?? "";

      if (addShopDataManager == null) {
        throw Exception("Unable to register. Please try again.");
      }

      final userProfileImage = sharedPreferences?.getString(Constant.image) ?? "";

      // Call API to create vendor with service
      var response = await addShopDataManager!.captureVendor(
        _shopNameController.text.trim(),
        userEmail,
        userMobile,
        userProfileImage, // Use existing profile image if available
        _defaultOpenTime,
        _defaultCloseTime,
        _shopNameController.text.trim(), // service title
        _serviceAboutController.text.isEmpty ? "Professional car service" : _serviceAboutController.text.trim(), // about
        _defaultCapacity,
        "0", // price - can be set later
        _defaultDuration,
        _selectedCategories[0],
        _selectedCategoryIds[0],
        _detailImages, // detail images
        _detailImages.isNotEmpty ? _detailImages[0] : userProfileImage, // Use first service image as cover or fallback to profile
        _defaultDays,
        _currentLng,
        _currentLat,
        _addressController.text.trim(),
        context,
      );

      if (!mounted || !context.mounted) return;
      
      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context); // Close loading
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
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

              // Create additional services for remaining categories
              if (_selectedCategories.length > 1) {
                await _createAdditionalServices(
                  vendorId,
                  userMobile,
                  _defaultCapacity,
                  _defaultDuration,
                  _detailImages.isNotEmpty ? _detailImages[0] : userProfileImage,
                );
              }
            } else {
            }
          }

          if (mounted && context.mounted) {
            UXHelperWidget.showSuccessMessage(
              context,
              "🎉 Success! Your business is now registered! You can start adding services and packages from your dashboard.",
            );

            // Small delay to show success message
            await Future.delayed(const Duration(seconds: 1));

            if (mounted && context.mounted) {
              // Navigate to dashboard
              CommonWidget.navigateToKillAllScreen(context, const DashboardActivity());
            }
          }
        } catch (jsonError) {
          if (mounted && context.mounted) {
            UXHelperWidget.showFriendlyError(
              context,
              "Registration completed but we couldn't verify it. Please check your dashboard.",
            );
            await Future.delayed(const Duration(seconds: 1));
            if (mounted && context.mounted) {
              CommonWidget.navigateToKillAllScreen(context, const DashboardActivity());
            }
          }
        }
      } else {
        // Try to parse error message
        String errorMessage = "Something went wrong. Please check your internet connection and try again.";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } catch (e) {
          // Use default error message
        }
        
        if (mounted && context.mounted) {
          UXHelperWidget.showFriendlyError(
            context,
            errorMessage,
          );
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        if (Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        UXHelperWidget.showFriendlyError(
          context,
          "Unable to complete registration. Please check your internet connection and try again. If the problem continues, contact support.",
        );
      }
    }
  }

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
    for (int i = 1; i < _selectedCategories.length; i++) {
      final categoryName = _selectedCategories[i];
      final categoryId = _selectedCategoryIds[i];

      try {
        await servicesDataManager!.postServies(
          context,
          _shopNameController.text, // serviceTitle
          _serviceAboutController.text.isEmpty ? "Professional car service" : _serviceAboutController.text.trim(), // about
          capacity, // timeSlotCapacity
          "0", // price
          duration, // serviceDuration
          categoryName, // categoryName
          categoryId, // categoryId
          coverImage, // coverImage
          _detailImages, // detailImages
          mobile, // mobile
        );
      } catch (e) {
        // Continue with next category even if one fails
        debugPrint("Error creating additional service: $e");
      }
    }
  }
}

