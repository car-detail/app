import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/Common/UXHelperWidget.dart';
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
    setState(() {
      isLoadingServices = true;
    });

    try {
      String? vId = sharedPreferences?.getString(Constant.vendorId);
      debugPrint('=== Current vendorId: $vId ===');
      
      // Self-healing: If vendorId is missing, try to recover it from my-business API
      if (vId == null || vId.isEmpty) {
        debugPrint('=== vendorId missing, attempting recovery ===');
        final vendorResponse = await loginDataManager!.getVendorDetails(context);
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
        setState(() {
          availableServices.clear();
          if (data.data != null) {
            availableServices.addAll(data.data!);
          }
          isLoadingServices = false;
        });
        
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: CommonWidget.buildAppBarBackButton(
          context,
          iconColor: Colors.black87,
        ),
        title: const Text(
          "Create Package",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Progress Indicator - Simple design
          Container(
            padding: const EdgeInsets.all(16),
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
              physics: const NeverScrollableScrollPhysics(), // Disable swipe to prevent bypassing validation
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
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
            ),
            child: Row(
              children: [
                if (currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF1CB273), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Previous",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1CB273),
                        ),
                      ),
                    ),
                  ),
                if (currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: currentStep < 2 ? _nextStep : _createPackage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1CB273),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      currentStep < 2 ? "Next" : "Create Package",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: currentStep >= step ? const Color(0xFF1CB273) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "${step + 1}",
              style: TextStyle(
                color: currentStep >= step ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: currentStep >= step ? const Color(0xFF1CB273) : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    return Container(
      height: 2,
      color: currentStep > step ? const Color(0xFF1CB273) : Colors.grey[300],
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
            message: "Create a package by combining multiple services. Customers love packages because they save money!",
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 30),
          
          const Text(
            "Package Details",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Tell us about your package",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          
          // Package Templates
          const Text(
            "Choose a Package Template",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: packageTemplates.length,
              itemBuilder: (context, index) {
                final template = packageTemplates[index];
                return Container(
                  width: 240,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    child: InkWell(
                      onTap: () => _selectPackageTemplate(template),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: template.isBestSeller 
                              ? Border.all(color: Colors.red, width: 2)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: template.color.withOpacity(0.1),
                                  child: Icon(
                                    Icons.local_car_wash,
                                    color: template.color,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    template.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: template.color,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (template.isBestSeller)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "BEST",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              template.description,
                              style: const TextStyle(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                _buildPriceChip("Small", "\$${template.smallPrice}", template.color),
                                _buildPriceChip("Large", "\$${template.largePrice}", template.color),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${template.services.length} services",
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          
          // Package Name
          const Text(
            "Package Name *",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: packageNameController,
            decoration: InputDecoration(
              hintText: "e.g., Premium Car Wash Package",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.inventory_2),
            ),
          ),
          const SizedBox(height: 15),
          
          // Package Description
          const Text(
            "Description *",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: packageDescriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Describe what's included in this package...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 15),
          
          // Vehicle Size Pricing with help
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Pricing by Vehicle Size",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  UXHelperWidget.showHelpDialog(
                    context,
                    title: "Vehicle Size Pricing",
                    message: "You can charge different prices for small cars (sedans, hatchbacks) and large vehicles (SUVs, trucks). This helps you price fairly based on the work required.",
                    example: "Small car: \$35, Large vehicle: \$45",
                  );
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: ColorClass.base_color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.help_outline,
                    size: 14,
                    color: ColorClass.base_color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Vehicle Size Pricing *",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.directions_car),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.local_shipping),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Package Tier
          const Text(
            "Package Tier *",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedTier,
            decoration: InputDecoration(
              hintText: "Select package tier",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.category),
            ),
            items: ["OUTSIDE", "BASIC", "ULTRA", "THE BEST"].map((tier) {
              return DropdownMenuItem(
                value: tier,
                child: Text(tier),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedTier = value ?? "BASIC";
              });
            },
          ),
          const SizedBox(height: 15),
          
          // Services Included Section
          const Text(
            "What's Included in This Package?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Define what services customers will get (e.g., Interior wash, Compounding, Engine cleansing)",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 15),
          
          // Service Definition Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customServiceController,
                        decoration: const InputDecoration(
                          hintText: "e.g., Interior wash, Compounding, Engine cleansing, Waxing",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          prefixIcon: Icon(Icons.add_circle_outline),
                        ),
                        onSubmitted: (value) {
                          _addCustomService(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        _addCustomService(customServiceController.text);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Add"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorClass.base_color,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Quick Add Buttons
                const Text(
                  "Quick Add Common Services:",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableCommonServices.map((service) {
                          return ActionChip(
                            label: Text(service),
                            onPressed: () {
                              _addCustomService(service);
                            },
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            labelStyle: const TextStyle(color: Colors.blue, fontSize: 12),
                          );
                        }).toList(),
                      ),
                
                const SizedBox(height: 16),
                
                // Display Added Services
                if (customServices.isNotEmpty) ...[
                  const Text(
                    "Services Added:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: customServices.map((service) {
                      return Chip(
                        label: Text(service),
                        backgroundColor: ColorClass.base_color.withOpacity(0.1),
                        labelStyle: TextStyle(color: ColorClass.base_color),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            customServices.remove(service);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 15),
          
          // Best Seller Toggle
          Row(
            children: [
              const Text(
                "Mark as Best Seller",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
                activeThumbColor: ColorClass.base_color,
              ),
            ],
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
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Choose which services are included in this package",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          
          // Existing Services Section
          const Text(
            "Select services to link (optional)",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          
          if (isLoadingServices)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Loading services..."),
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
                        Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "No services available",
                          style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Please add some services first",
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
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
                    final isSelected = selectedServices.contains(service.sId);
                  
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? ColorClass.base_color.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? ColorClass.base_color : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected 
                                ? ColorClass.base_color.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Checkbox
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? ColorClass.base_color : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? ColorClass.base_color : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            // Service Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: service.coverImage != null && service.coverImage!.isNotEmpty
                                  ? Image.network(
                                      service.coverImage!,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey[200],
                                          child: Icon(
                                            Icons.build_circle_rounded,
                                            color: Colors.grey[400],
                                            size: 30,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.build_circle_rounded,
                                        color: Colors.grey[400],
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
                                    service.categoryName ?? service.serviceTitle ?? "Unknown Service",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontFamily: "Pop600",
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (service.serviceTitle != null && service.serviceTitle != service.categoryName)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
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
                                  if (service.about != null && service.about!.isNotEmpty)
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
                                  else if (service.description != null && service.description!.isNotEmpty)
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: ColorClass.base_color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.attach_money, size: 12, color: ColorClass.base_color),
                                            const SizedBox(width: 2),
                                            Text(
                                              "${service.price ?? 0}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: ColorClass.base_color,
                                                fontFamily: "Pop600",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (service.serviceDuration != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.access_time, size: 12, color: Colors.blue[700]),
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
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Review your package details before creating",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    packageNameController.text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    packageDescriptionController.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      // Show price range if both small and large vehicle prices are set
                      if (smallVehiclePriceController.text.isNotEmpty && largeVehiclePriceController.text.isNotEmpty)
                        _buildInfoChip("Price", "\$${smallVehiclePriceController.text} - \$${largeVehiclePriceController.text}")
                      else if (packagePriceController.text.isNotEmpty)
                        _buildInfoChip("Price", "\$${packagePriceController.text}")
                      else
                        _buildInfoChip("Price", "N/A"),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Services Included:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                          return Chip(
                            label: Text(service.categoryName ?? service.serviceTitle ?? "Unknown Service"),
                            backgroundColor: ColorClass.base_color.withOpacity(0.1),
                            labelStyle: TextStyle(color: ColorClass.base_color),
                          );
                        } else {
                          return const SizedBox.shrink(); // Don't show anything for unknown services
                        }
                      }),
                      if (selectedServices.isEmpty)
                        Text(
                          "No services selected",
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ColorClass.base_color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(
          color: ColorClass.base_color,
          fontWeight: FontWeight.w600,
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
    final smallPriceError = _validatePrice(smallVehiclePriceController.text, "Small vehicle price");
    if (smallPriceError != null) {
      CommonWidget.errorShowSnackBarFor(context, smallPriceError);
      return false;
    }

    // Validate large vehicle price
    final largePriceError = _validatePrice(largeVehiclePriceController.text, "Large vehicle price");
    if (largePriceError != null) {
      CommonWidget.errorShowSnackBarFor(context, largePriceError);
      return false;
    }

    // Validate that large vehicle price is >= small vehicle price
    final smallPrice = double.tryParse(smallVehiclePriceController.text.trim());
    final largePrice = double.tryParse(largeVehiclePriceController.text.trim());
    if (smallPrice != null && largePrice != null && largePrice < smallPrice) {
      CommonWidget.errorShowSnackBarFor(context, "Large vehicle price should be greater than or equal to small vehicle price");
      return false;
    }

    // Note: Services validation is done in step 1 (Services step), not in Basic Info step
    // Services will be validated when moving from step 1 to step 2, or in the final review step

    return true;
  }

  bool _validateServices() {
    if (selectedServices.isEmpty) {
      CommonWidget.errorShowSnackBarFor(context, "Please select at least one service");
      return false;
    }
    return true;
  }

  void _nextStep() {
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
    if (isValid && currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
          child: CircularProgressIndicator(),
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
      
      if (!mounted || !context.mounted) return;
      
      if (Navigator.canPop(context)) {
      Navigator.pop(context); // Close loader
      }
      
      
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
          CommonWidget.errorShowSnackBarFor(context, "Unable to create package. Please check your connection and try again.");
        }
        return;
      }
      
      try {
        var data = PackageModelData.fromJson(jsonDecode(response.body));
        
        if (data.status == "success") {
          if (mounted && context.mounted) {
          CommonWidget.successShowSnackBarFor(context, "Package created successfully!");
            Navigator.pop(context, true);
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to create package. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error parsing response. Please try again.");
      }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context); // Close loader
      }
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error creating package. Please check your connection and try again.");
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
