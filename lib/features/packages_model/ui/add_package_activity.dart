import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/Common/UXHelperWidget.dart';
import 'package:car_app/Common/ModernDesignSystem.dart';
import 'package:car_app/design_system/components/app_header.dart';
import 'package:car_app/design_system/components/bouncy_tap.dart';
import 'package:car_app/features/packages_model/data_manager/package_data_manager.dart';
import 'package:car_app/features/packages_model/model/package_model_data.dart';
import 'package:car_app/features/home_module/model/services_model_data.dart';
import 'package:car_app/features/log_in/data_manager/LoginDataManager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddPackageActivity extends StatefulWidget {
  const AddPackageActivity({super.key});

  @override
  State<AddPackageActivity> createState() => _AddPackageActivityState();
}

class _AddPackageActivityState extends State<AddPackageActivity> {
  int currentStep = 0;
  final PageController _pageController = PageController();
  bool _isInitialized = false; // Track if initial data load is done

  // Package Details
  TextEditingController packageNameController = TextEditingController();
  TextEditingController packageDescriptionController = TextEditingController();
  TextEditingController packagePriceController = TextEditingController();
  TextEditingController smallVehiclePriceController = TextEditingController();
  TextEditingController largeVehiclePriceController = TextEditingController();

  // Package Tier
  String selectedTier = "BASIC";
  bool isBestSeller = false;

  // Services
  List<ServicesData> availableServices = [];
  List<String> selectedServices = [];
  List<String> customServices = []; // For custom service names
  TextEditingController customServiceController = TextEditingController();
  bool isLoadingServices = true;

  // Image
  XFile? selectedImage;

  // Car Wash Package Templates
  final List<PackageTemplate> packageTemplates = [
    PackageTemplate(
      name: "OUTSIDE",
      description: "Basic exterior wash service",
      smallPrice: "25",
      largePrice: "30",
      duration: "1",
      tier: "OUTSIDE",
      services: ["Hand Wash", "Tire Wipe", "Air Dry"],
      color: Colors.green,
    ),
    PackageTemplate(
      name: "BASIC",
      description: "Standard wash with interior cleaning",
      smallPrice: "35",
      largePrice: "40",
      duration: "1.5",
      tier: "BASIC",
      services: ["Hand Wash", "Wheel Clean", "Vacuum", "Interior Wipe", "Hand Dry"],
      color: Colors.blue,
    ),
    PackageTemplate(
      name: "ULTRA",
      description: "Premium wash with ceramic protection",
      smallPrice: "45",
      largePrice: "55",
      duration: "2.5",
      tier: "ULTRA",
      isBestSeller: true,
      services: [
        "Premium Hand Wash", "Wheel/Rim Cleaning", "Tire Conditioning",
        "Hand Dry", "Air Freshener", "Interior Wipe", "Interior Dressing",
        "Ceramic Spray Wax", "All Mats Cleaned", "Rain Guard", "Under Carriage"
      ],
      color: Colors.purple,
    ),
    PackageTemplate(
      name: "THE BEST",
      description: "Ultimate detailing package with UV protection",
      smallPrice: "70",
      largePrice: "80",
      duration: "3.5",
      tier: "THE BEST",
      services: [
        "Premium Hand Wash", "Wheel/Rim Cleaning", "Tire Conditioning",
        "Hand Dry", "Air Freshener", "Interior Wipe", "Interior Dressing",
        "Ceramic Spray Wax", "All Mats Cleaned", "Rain Guard",
        "Door Detailing", "Dashboard Detailing", "Ultraviolet Protector"
      ],
      color: Colors.red,
    ),
  ];

  PackageDataManager? dataManager;
  LoginDataManager? loginDataManager;
  SharedPreferences? sharedPreferences;

  @override
  void initState() {
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    dataManager = PackageDataManager(sharedPreferences!);
    loginDataManager = LoginDataManager(sharedPreferences!);
    await getAvailableServices();
  }

  void _addCustomService(String serviceName) {
    if (serviceName.trim().isNotEmpty && !customServices.contains(serviceName.trim())) {
      setState(() {
        customServices.add(serviceName.trim());
        customServiceController.clear();
      });
    }
  }

  // Get list of common services that haven't been selected yet
  List<String> get _availableCommonServices {
    const List<String> allCommonServices = [
      "Interior wash", "Exterior wash", "Compounding", "Engine cleansing",
      "Waxing", "Polishing", "Tire cleaning", "Dashboard cleaning",
      "Seat cleaning", "Carpet cleaning", "Window cleaning", "Headlight restoration"
    ];

    // Filter out services that are already in customServices
    return allCommonServices.where((service) => !customServices.contains(service)).toList();
  }

  Future<void> getAvailableServices() async {
    if (_isInitialized) {
      // Don't call setState for loading if already initialized - it causes keyboard dismiss
      isLoadingServices = true;
    } else {
      setState(() {
        isLoadingServices = true;
      });
    }

    try {
      String? vId = sharedPreferences?.getString(Constant.vendorId);
      debugPrint('=== Current vendorId: $vId ===');

      // Self-healing: If vendorId is missing, try to recover it from my-business API
      if (vId == null || vId.isEmpty) {
        debugPrint('=== vendorId missing, attempting recovery ===');
        final vendorResponse = await loginDataManager!.getVendorDetails(context);
        if (!mounted) return;
        debugPrint('Vendor details API Status: ${vendorResponse.statusCode}');
        debugPrint('Vendor details API Response: ${vendorResponse.body}');

        if (vendorResponse.statusCode == 200) {
          final vendorData = jsonDecode(vendorResponse.body);
          if (vendorData['status'] == 'success' &&
              vendorData['data'] is List &&
              (vendorData['data'] as List).isNotEmpty) {
            vId = vendorData['data'][0]['_id'] ?? '';
            if (vId != null && vId!.isNotEmpty) {
              await sharedPreferences!.setString(Constant.vendorId, vId!);
              debugPrint('=== vendorId recovered and stored: $vId ===');
            }
          } else {
            debugPrint('=== Vendor data structure issue: ${vendorData}');
          }
        } else {
          debugPrint('=== Failed to get vendor details: ${vendorResponse.statusCode}');
        }
      }

      if (vId == null || vId.isEmpty) {
        debugPrint('=== Cannot fetch services - no valid vendorId ===');
        setState(() {
          isLoadingServices = false;
        });
        return;
      }

      debugPrint('=== Fetching Services for Vendor: $vId ===');
      var response = await dataManager!.getAllServices(context);
      if (!mounted) return;
      debugPrint('Services API Status Code: ${response.statusCode}');
      debugPrint('Services API Response Body: ${response.body.substring(0, min(response.body.length, 500))}...');

      // Check for HTML error responses
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        debugPrint('=== Received HTML error response instead of JSON ===');
        setState(() {
          isLoadingServices = false;
        });
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Backend connection issue. Please check your internet connection.");
        }
        return;
      }

      var data = ServicesModelData.fromJson(jsonDecode(response.body));

      if (data.status == "success") {
        availableServices.clear();
        if (data.data != null) {
          availableServices.addAll(data.data!);
        }
        isLoadingServices = false;
        _isInitialized = true;
        if (mounted) setState(() {});

        debugPrint('=== Services loaded successfully: ${availableServices.length} services ===');
        // Debug: Print service details
        for (int i = 0; i < availableServices.length; i++) {
          final service = availableServices[i];
          debugPrint('Service $i: ${service.serviceTitle} (ID: ${service.sId})');
        }
      } else {
        debugPrint('=== Failed to load services: ${data.message} ===');
        setState(() {
          isLoadingServices = false;
        });
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Failed to load services: ${data.message}");
        }
      }
    } catch (e) {
      debugPrint('=== Error loading services: $e ===');
      setState(() {
        isLoadingServices = false;
      });
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error loading services: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppHeader(
        title: "Create Package",
        subtitle: "Bundle your services into a package",
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                _buildStepIndicator(0, "Basic Info"),
                Expanded(child: _buildStepLine(0)),
                _buildStepIndicator(1, "Services"),
                Expanded(child: _buildStepLine(1)),
                _buildStepIndicator(2, "Review"),
              ],
            ),
          ),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  currentStep = index;
                });
              },
              children: [
                _buildBasicInfoStep(),
                _buildServicesStep(),
                _buildReviewStep(),
              ],
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: const Color(0xFF1B2A4A).withOpacity(0.2), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B2A4A).withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (currentStep > 0)
                  Expanded(
                    child: BouncyTap(
                      onTap: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: ModernDesignSystem.accentFor(4), width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Previous",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ModernDesignSystem.accentFor(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: BouncyTap(
                    onTap: currentStep < 2 ? _nextStep : _createPackage,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ModernDesignSystem.accentFor(4),
                            ModernDesignSystem.accentFor(4).withOpacity(0.7),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: ModernDesignSystem.getColoredShadow(
                            ModernDesignSystem.accentFor(4), opacity: 0.35),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentStep < 2 ? "Next" : "Create Package",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              currentStep < 2 ? Icons.arrow_forward_rounded : Icons.check_circle_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String title) {
    final bool isCompleted = currentStep > step;
    final bool isActive = currentStep == step;
    final accent = ModernDesignSystem.accentFor(4); // amber, packages identity

    return Column(
      children: [
        AnimatedScale(
          scale: isActive ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: (isActive || isCompleted)
                  ? LinearGradient(
                      colors: [accent, accent.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: (isActive || isCompleted) ? null : Colors.white,
              border: !isActive && !isCompleted
                  ? Border.all(color: accent, width: 1)
                  : null,
              boxShadow: isActive
                  ? ModernDesignSystem.getColoredShadow(accent, opacity: 0.4)
                  : null,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16, key: ValueKey(true))
                    : Text(
                        "${step + 1}",
                        key: const ValueKey(false),
                        style: TextStyle(
                          color: isActive ? Colors.white : accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: isActive || isCompleted ? accent : Colors.grey[400],
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: currentStep > step
            ? ModernDesignSystem.accentFor(4)
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          UXHelperWidget.buildInfoBanner(
            iconColor: ModernDesignSystem.accentFor(4),
            message: "Create a package by combining multiple services. Customers love packages because they save money!",
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 30),

          const Text(
            "Package Details",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1526),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Tell us about your package",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),

          // Package Templates
          const Text(
            "Choose a Package Template",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1526),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: packageTemplates.length,
              itemBuilder: (context, index) {
                final template = packageTemplates[index];
                final bool isSelectedTemplate =
                    packageNameController.text == template.name && selectedTier == template.tier;
                return Container(
                  width: 240,
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _selectPackageTemplate(template),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelectedTemplate
                              ? const Color(0xFF1B2A4A)
                              : Colors.grey[300]!,
                          width: isSelectedTemplate ? 2 : 1,
                        ),
                        boxShadow: isSelectedTemplate
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF1B2A4A).withOpacity(0.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: template.color.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.local_car_wash,
                                  color: template.color,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  template.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: template.color,
                                    fontSize: 14,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              if (template.isBestSeller)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1B2A4A), Color(0xFF00C853)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "BEST",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            template.description,
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _buildPriceChip("Small", "\$${template.smallPrice}", template.color),
                              _buildPriceChip("Large", "\$${template.largePrice}", template.color),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${template.services.length} services",
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Package Name
          const Text(
            "Package Name *",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B2A4A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: packageNameController,
            decoration: InputDecoration(
              hintText: "e.g., Premium Car Wash Package",
              filled: true,
              fillColor: const Color(0xFFF0FDF4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: const Color(0xFF1B2A4A).withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: const Color(0xFF1B2A4A).withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF1B2A4A), width: 2),
              ),
              labelStyle: const TextStyle(
                  color: Color(0xFF1B2A4A), fontWeight: FontWeight.w600),
              prefixIcon:
                  const Icon(Icons.inventory_2, color: Color(0xFF1B2A4A)),
            ),
          ),
          const SizedBox(height: 16),

          // Package Description
          const Text(
            "Description *",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B2A4A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: packageDescriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Describe what's included in this package...",
              filled: true,
              fillColor: const Color(0xFFF0FDF4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: const Color(0xFF1B2A4A).withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: const Color(0xFF1B2A4A).withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF1B2A4A), width: 2),
              ),
              labelStyle: const TextStyle(
                  color: Color(0xFF1B2A4A), fontWeight: FontWeight.w600),
              prefixIcon:
                  const Icon(Icons.description, color: Color(0xFF1B2A4A)),
            ),
          ),
          const SizedBox(height: 16),

          // Vehicle Size Pricing with help
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Pricing by Vehicle Size",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1526),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  UXHelperWidget.showHelpDialog(
                    context,
                    title: "Vehicle Size Pricing",
                    message:
                        "You can charge different prices for small cars (sedans, hatchbacks) and large vehicles (SUVs, trucks). This helps you price fairly based on the work required.",
                    example: "Small car: \$35, Large vehicle: \$45",
                  );
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2A4A).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    size: 14,
                    color: Color(0xFF1B2A4A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Vehicle Size Pricing *",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B2A4A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: smallVehiclePriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Small Vehicle Price",
                    labelText: "Small Vehicle (\$)",
                    filled: true,
                    fillColor: const Color(0xFFF0FDF4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: const Color(0xFF1B2A4A).withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: const Color(0xFF1B2A4A).withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFF1B2A4A), width: 2),
                    ),
                    labelStyle: const TextStyle(
                        color: Color(0xFF1B2A4A), fontWeight: FontWeight.w600),
                    prefixIcon: const Icon(Icons.directions_car,
                        color: Color(0xFF1B2A4A)),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextField(
                  controller: largeVehiclePriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Large Vehicle Price",
                    labelText: "Large Vehicle (\$)",
                    filled: true,
                    fillColor: const Color(0xFFF0FDF4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: const Color(0xFF1B2A4A).withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: const Color(0xFF1B2A4A).withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFF1B2A4A), width: 2),
                    ),
                    labelStyle: const TextStyle(
                        color: Color(0xFF1B2A4A), fontWeight: FontWeight.w600),
                    prefixIcon: const Icon(Icons.local_shipping,
                        color: Color(0xFF1B2A4A)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Package Tier
          const Text(
            "Package Tier *",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1526),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ["OUTSIDE", "BASIC", "ULTRA", "THE BEST"].map((tier) {
              final bool isActiveTier = selectedTier == tier;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTier = tier;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isActiveTier
                          ? const LinearGradient(
                              colors: [Color(0xFF0D1526), Color(0xFF1B2A4A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isActiveTier ? null : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActiveTier
                            ? const Color(0xFF1B2A4A)
                            : Colors.grey[300]!,
                        width: isActiveTier ? 0 : 1,
                      ),
                      boxShadow: isActiveTier
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1B2A4A).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        tier,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isActiveTier ? Colors.white : Colors.grey[500],
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Services Included Section
          const Text(
            "What's Included in This Package?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1526),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Define what services customers will get (e.g., Interior wash, Compounding, Engine cleansing)",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 15),

          // Service Definition Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF1B2A4A).withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B2A4A).withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customServiceController,
                        decoration: InputDecoration(
                          hintText:
                              "e.g., Interior wash, Compounding, Engine cleansing, Waxing",
                          filled: true,
                          fillColor: const Color(0xFFF0FDF4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: const Color(0xFF1B2A4A).withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: const Color(0xFF1B2A4A).withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Color(0xFF1B2A4A), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          prefixIcon: const Icon(Icons.add_circle_outline,
                              color: Color(0xFF1B2A4A)),
                        ),
                        onSubmitted: (value) {
                          _addCustomService(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _addCustomService(customServiceController.text);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D1526), Color(0xFF1B2A4A)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "Add",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Add Buttons
                Text(
                  "Quick Add Common Services:",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                _availableCommonServices.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "All common services have been added",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableCommonServices.map((service) {
                          return GestureDetector(
                            onTap: () {
                              _addCustomService(service);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                service,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                const SizedBox(height: 16),

                // Display Added Services
                if (customServices.isNotEmpty) ...[
                  Text(
                    "Services Added:",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: customServices.map((service) {
                      return Container(
                        padding: const EdgeInsets.only(
                            left: 12, top: 6, bottom: 6, right: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B2A4A), Color(0xFF00C853)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              service,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  customServices.remove(service);
                                });
                              },
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Best Seller Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF1B2A4A).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text(
                  "Mark as Best Seller",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1526),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: isBestSeller,
                  onChanged: (value) {
                    setState(() {
                      isBestSeller = value;
                    });
                  },
                  activeColor: const Color(0xFF1B2A4A),
                  activeTrackColor: const Color(0xFF1B2A4A).withOpacity(0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Services",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1526),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Choose which services are included in this package",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),

          // Existing Services Section
          const Text(
            "Select services to link (optional)",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1526),
              letterSpacing: -0.5,
            ),
          ),

          if (isLoadingServices)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                        color: Color(0xFF1B2A4A)),
                    const SizedBox(height: 16),
                    Text(
                      "Loading services...",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            Builder(
              builder: (context) {
                // Show all services, don't filter by price
                final servicesToShow = availableServices.where((service) {
                  // Only filter out services without an ID
                  return service.sId != null && service.sId!.isNotEmpty;
                }).toList();

                if (servicesToShow.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            size: 64,
                            color: const Color(0xFF1B2A4A).withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text(
                          "No services available",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Please add some services first",
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: servicesToShow.length,
                  itemBuilder: (context, index) {
                    final service = servicesToShow[index];
                    final isSelected =
                        selectedServices.contains(service.sId);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedServices.remove(service.sId!);
                          } else {
                            selectedServices.add(service.sId!);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF0FDF4)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1B2A4A)
                                : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? const Color(0xFF1B2A4A).withOpacity(0.12)
                                  : Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Checkbox
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF1B2A4A),
                                            Color(0xFF00C853)
                                          ],
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 15,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              // Service Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: service.coverImage != null &&
                                        service.coverImage!.isNotEmpty
                                    ? Image.network(
                                        service.coverImage!,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 70,
                                            height: 70,
                                            color: const Color(0xFFF0FDF4),
                                            child: Icon(
                                              Icons.build_circle_rounded,
                                              color: const Color(0xFF1B2A4A)
                                                  .withOpacity(0.4),
                                              size: 30,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.build_circle_rounded,
                                          color: const Color(0xFF1B2A4A)
                                              .withOpacity(0.4),
                                          size: 30,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              // Service Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.categoryName ??
                                          service.serviceTitle ??
                                          "Unknown Service",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontFamily: "Pop600",
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (service.serviceTitle != null &&
                                        service.serviceTitle !=
                                            service.categoryName)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 2),
                                        child: Text(
                                          service.serviceTitle!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontFamily: "Pop500",
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    if (service.about != null &&
                                        service.about!.isNotEmpty)
                                      Text(
                                        service.about!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    else if (service.description != null &&
                                        service.description!.isNotEmpty)
                                      Text(
                                        service.description!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    else
                                      Text(
                                        "No description",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[400],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    // Info badges
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0FDF4),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFF1B2A4A)
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.attach_money,
                                                  size: 12,
                                                  color: Color(0xFF1B2A4A)),
                                              const SizedBox(width: 2),
                                              Text(
                                                "${service.price ?? 0}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1B2A4A),
                                                  fontFamily: "Pop600",
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (service.serviceDuration != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue
                                                  .withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.access_time,
                                                    size: 12,
                                                    color: Colors.blue[700]),
                                                const SizedBox(width: 2),
                                                Text(
                                                  service.serviceDuration!,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.blue[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
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
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Review Package",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1526),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Review your package details before creating",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF1B2A4A).withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B2A4A).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Package name header with gradient accent
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D1526), Color(0xFF1B2A4A)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          packageNameController.text,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D1526),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    packageDescriptionController.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Show price range if both small and large vehicle prices are set
                      if (smallVehiclePriceController.text.isNotEmpty &&
                          largeVehiclePriceController.text.isNotEmpty)
                        _buildInfoChip("Price",
                            "\$${smallVehiclePriceController.text} - \$${largeVehiclePriceController.text}")
                      else if (packagePriceController.text.isNotEmpty)
                        _buildInfoChip(
                            "Price", "\$${packagePriceController.text}")
                      else
                        _buildInfoChip("Price", "N/A"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Services Included:",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D1526),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Selected Services (from existing services)
                      ...selectedServices.map((serviceId) {
                        final service = availableServices.firstWhere(
                          (s) => s.sId == serviceId,
                          orElse: () => ServicesData(),
                        );

                        if (service.sId != null) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1B2A4A), Color(0xFF00C853)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              service.categoryName ??
                                  service.serviceTitle ??
                                  "Unknown Service",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      }),
                      // Custom Services (including template services)
                      ...customServices.map((serviceName) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B2A4A), Color(0xFF00C853)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            serviceName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }),
                      if (selectedServices.isEmpty && customServices.isEmpty)
                        Text(
                          "No services selected",
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1526), Color(0xFF1B2A4A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPriceChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  void _selectPackageTemplate(PackageTemplate template) {
    FocusScope.of(context).unfocus();
    setState(() {
      packageNameController.text = template.name;
      packageDescriptionController.text = template.description;
      smallVehiclePriceController.text = template.smallPrice;
      largeVehiclePriceController.text = template.largePrice;
      selectedTier = template.tier;
      isBestSeller = template.isBestSeller;

      // Add template services as custom services instead of selected services
      customServices.clear();
      customServices.addAll(template.services);
      selectedServices.clear(); // Clear any existing selected services
    });

    CommonWidget.successShowSnackBarFor(context, "Package template selected!");
  }

  // Validation methods
  String? _validatePackageName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Package name is required";
    }
    if (value.trim().length < 3) {
      return "Package name must be at least 3 characters";
    }
    if (value.trim().length > 100) {
      return "Package name must be less than 100 characters";
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Description is required";
    }
    if (value.trim().length < 10) {
      return "Description must be at least 10 characters";
    }
    if (value.trim().length > 500) {
      return "Description must be less than 500 characters";
    }
    return null;
  }

  String? _validatePrice(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    final price = double.tryParse(value.trim());
    if (price == null) {
      return "$fieldName must be a valid number";
    }
    if (price < 0) {
      return "$fieldName cannot be negative";
    }
    if (price > 10000) {
      return "$fieldName cannot exceed \$10,000";
    }
    return null;
  }

  bool _validateBasicInfo() {
    // Validate package name
    final nameError = _validatePackageName(packageNameController.text);
    if (nameError != null) {
      CommonWidget.errorShowSnackBarFor(context, nameError);
      return false;
    }

    // Validate description
    final descError = _validateDescription(packageDescriptionController.text);
    if (descError != null) {
      CommonWidget.errorShowSnackBarFor(context, descError);
      return false;
    }

    // Validate small vehicle price
    final smallPriceError =
        _validatePrice(smallVehiclePriceController.text, "Small vehicle price");
    if (smallPriceError != null) {
      CommonWidget.errorShowSnackBarFor(context, smallPriceError);
      return false;
    }

    // Validate large vehicle price
    final largePriceError =
        _validatePrice(largeVehiclePriceController.text, "Large vehicle price");
    if (largePriceError != null) {
      CommonWidget.errorShowSnackBarFor(context, largePriceError);
      return false;
    }

    // Validate that large vehicle price is >= small vehicle price
    final smallPrice =
        double.tryParse(smallVehiclePriceController.text.trim());
    final largePrice =
        double.tryParse(largeVehiclePriceController.text.trim());
    if (smallPrice != null &&
        largePrice != null &&
        largePrice < smallPrice) {
      CommonWidget.errorShowSnackBarFor(context,
          "Large vehicle price should be greater than or equal to small vehicle price");
      return false;
    }

    // Note: Services validation is done in step 1 (Services step), not in Basic Info step
    // Services will be validated when moving from step 1 to step 2, or in the final review step

    return true;
  }

  bool _validateServices() {
    if (selectedServices.isEmpty && customServices.isEmpty) {
      CommonWidget.errorShowSnackBarFor(
          context, "Please select at least one service");
      return false;
    }
    return true;
  }

  void _nextStep() {
    // Hide keyboard when moving to next step
    FocusScope.of(context).unfocus();
    
    bool isValid = false;

    // Validate based on current step
    if (currentStep == 0) {
      // Step 0: Basic Info validation
      isValid = _validateBasicInfo();
    } else if (currentStep == 1) {
      // Step 1: Services validation
      isValid = _validateServices();
    } else if (currentStep == 2) {
      // Step 2: Review - validate everything before creating
      isValid = _validateAllSteps();
    }

    // Only proceed to next step if validation passes
    if (isValid) {
      if (currentStep < 2) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // If on last step and valid, create the package
        _createPackage();
      }
    }
  }

  // Comprehensive validation for all steps
  bool _validateAllSteps() {
    // Validate Basic Info
    if (!_validateBasicInfo()) {
      return false;
    }

    // Validate Services
    if (!_validateServices()) {
      return false;
    }

    return true;
  }

  Future<void> _createPackage() async {
    if (!mounted || !context.mounted) return;

    // Final comprehensive validation before creating package
    if (!_validateAllSteps()) {
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1B2A4A)),
        ),
      );

      // Send actual service IDs

      var response = await dataManager!.createPackage(
        context,
        packageNameController.text,
        packageDescriptionController.text,
        smallVehiclePriceController.text, // Use small vehicle price as base price
        "", // Duration removed - pass empty string
        selectedServices, // Only send actual service IDs
        smallVehiclePrice: smallVehiclePriceController.text,
        largeVehiclePrice: largeVehiclePriceController.text,
        packageTier: selectedTier,
        isBestSeller: isBestSeller,
        customServices: customServices, // Send custom services
      );

      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loader
      }

      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') ||
          response.body.startsWith('<html')) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context,
              "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        return;
      }

      // Check response status code
      if (response.statusCode != 200 && response.statusCode != 201) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context,
              "Unable to create package. Please check your connection and try again.");
        }
        return;
      }

      try {
        var data = PackageModelData.fromJson(jsonDecode(response.body));

        if (data.status == "success") {
          if (mounted && context.mounted) {
            CommonWidget.successShowSnackBarFor(
                context, "Package created successfully!");
            Navigator.pop(context, true);
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context,
                data.message ?? "Failed to create package. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(
              context, "Error parsing response. Please try again.");
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Close loader
      }
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context,
            "Error creating package. Please check your connection and try again.");
      }
    }
  }
}

class PackageTemplate {
  final String name;
  final String description;
  final String smallPrice;
  final String largePrice;
  final String duration;
  final String tier;
  final List<String> services;
  final Color color;
  final bool isBestSeller;

  PackageTemplate({
    required this.name,
    required this.description,
    required this.smallPrice,
    required this.largePrice,
    required this.duration,
    required this.tier,
    required this.services,
    required this.color,
    this.isBestSeller = false,
  });
}
