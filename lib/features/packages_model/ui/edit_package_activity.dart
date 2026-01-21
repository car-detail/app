import 'dart:convert';
import 'dart:io';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/Common/UXHelperWidget.dart';
import 'package:car_app/features/packages_model/data_manager/package_data_manager.dart';
import 'package:car_app/features/packages_model/model/package_model_data.dart';
import 'package:car_app/features/home_module/model/services_model_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EditPackageActivity extends StatefulWidget {
  final PackageData packageData;
  
  const EditPackageActivity({super.key, required this.packageData});

  @override
  State<EditPackageActivity> createState() => _EditPackageActivityState();
}

class _EditPackageActivityState extends State<EditPackageActivity> {
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
  SharedPreferences? sharedPreferences;

  @override
  void initState() {
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = PackageDataManager(sharedPreferences!);
    await getAvailableServices();
    _populateFormData();
  }

  void _populateFormData() {
    // Debug: Print the package data received
    
    // Populate form fields with existing package data
    packageNameController.text = widget.packageData.packageName ?? "";
    packageDescriptionController.text = widget.packageData.packageDescription ?? "";
    packagePriceController.text = widget.packageData.packagePrice ?? "";
    
    // Handle pricing - prefer smallVehiclePrice/largeVehiclePrice, fallback to packagePrice
    if (widget.packageData.smallVehiclePrice != null && widget.packageData.smallVehiclePrice!.isNotEmpty) {
      smallVehiclePriceController.text = widget.packageData.smallVehiclePrice!;
    } else if (widget.packageData.packagePrice != null && widget.packageData.packagePrice!.isNotEmpty) {
      // If smallVehiclePrice is not set, use packagePrice as fallback
      smallVehiclePriceController.text = widget.packageData.packagePrice!;
    } else {
      smallVehiclePriceController.text = "";
    }
    
    if (widget.packageData.largeVehiclePrice != null && widget.packageData.largeVehiclePrice!.isNotEmpty) {
      largeVehiclePriceController.text = widget.packageData.largeVehiclePrice!;
    } else if (widget.packageData.packagePrice != null && widget.packageData.packagePrice!.isNotEmpty) {
      // If largeVehiclePrice is not set, use packagePrice as fallback
      largeVehiclePriceController.text = widget.packageData.packagePrice!;
    } else {
      largeVehiclePriceController.text = "";
    }
    
    selectedTier = widget.packageData.packageTier ?? "BASIC";
    // Set isBestSeller from API data - ensure it's properly set
    isBestSeller = widget.packageData.isBestSeller == true;
    
    // Populate selected services - handle both service IDs and service objects
    if (widget.packageData.servicesIncluded != null) {
      selectedServices = widget.packageData.servicesIncluded!.map((e) => e.toString()).toList();
    } else {
      selectedServices = [];
    }
    
    // Load custom services from package data (if available) or extract from description as fallback
    if (widget.packageData.customServices != null && widget.packageData.customServices!.isNotEmpty) {
      customServices = List<String>.from(widget.packageData.customServices!);
    } else {
      // Fallback: Extract custom services from description if any
      _extractCustomServicesFromDescription();
    }
    
    // Trigger setState to update UI with populated data
    setState(() {});
    
  }

  void _extractCustomServicesFromDescription() {
    // Try to extract custom services from the description
    // Look for patterns like "Services included:" or bullet points
    String description = packageDescriptionController.text;
    
    if (description.contains("Services included:")) {
      List<String> lines = description.split('\n');
      bool foundServices = false;
      
      for (String line in lines) {
        if (line.contains("Services included:")) {
          foundServices = true;
          continue;
        }
        
        if (foundServices && line.trim().startsWith('•')) {
          String service = line.trim().substring(1).trim();
          if (service.isNotEmpty && !customServices.contains(service)) {
            customServices.add(service);
          }
        } else if (foundServices && line.trim().isNotEmpty) {
          // If we hit a non-bullet line after services, stop
          break;
        }
      }
    }
  }

  void _addCustomService(String serviceName) {
    if (serviceName.trim().isNotEmpty) {
      setState(() {
        customServices.add(serviceName.trim());
        customServiceController.clear();
      });
    }
  }

  Future<void> getAvailableServices() async {
    var response = await dataManager!.getAllServices(context);
    
    try {
    var data = ServicesModelData.fromJson(jsonDecode(response.body));
      
    if (data.status == "success") {
      setState(() {
        availableServices.clear();
        availableServices.addAll(data.data!);
      });
        
        // Debug: Print details of each service
        debugPrint('=== Available Services Debug ===');
        debugPrint('Total services loaded: ${availableServices.length}');
        for (int i = 0; i < availableServices.length; i++) {
          final service = availableServices[i];
          debugPrint('Service $i: ${service.serviceTitle}, Price: ${service.price}, ID: ${service.sId}');
        }
        debugPrint('=== End Services Debug ===');
        
        // Debug: Print selected services
      } else {
        debugPrint('Failed to load services: ${data.message}');
      }
    } catch (e) {
      debugPrint('Error loading services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar style when this screen builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: ColorClass.base_color,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    });
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: ColorClass.base_color,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Column(
          children: [
            // Green status bar background
            Container(
              height: MediaQuery.of(context).padding.top,
              color: ColorClass.base_color,
              width: double.infinity,
            ),
            // AppBar-like header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: ColorClass.base_color,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back button on the left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CommonWidget.buildAppBarBackButton(
          context,
          backgroundColor: Colors.white.withOpacity(0.2),
          iconColor: Colors.white,
        ),
                  ),
                  // Centered title
                  const Text(
                    "Edit Package",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Pop600",
      ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(20),
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (currentStep > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("Previous"),
                    ),
                  ),
                if (currentStep > 0) const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: currentStep < 2 ? _nextStep : _updatePackage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorClass.base_color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(currentStep < 2 ? "Next" : "Update Package"),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String title) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: currentStep >= step ? ColorClass.base_color : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "${step + 1}",
              style: TextStyle(
                color: currentStep >= step ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: currentStep >= step ? ColorClass.base_color : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    return Container(
      height: 2,
      color: currentStep > step ? ColorClass.base_color : Colors.grey[300],
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
              message: "Update your package details below. You can change anything anytime!",
              icon: Icons.edit_outlined,
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
            UXHelperWidget.buildHelpfulInputField(
              context: context,
              controller: packageNameController,
              label: "Package Name",
              icon: Icons.inventory_2,
              helpText: "Give your package a clear and attractive name, like 'Complete Car Care Package' or 'Express Wash & Wax'.",
              example: "Premium Car Wash Package",
              isRequired: true,
            ),
          const SizedBox(height: 15),
            
            // Package Description
            UXHelperWidget.buildHelpfulInputField(
              context: context,
              controller: packageDescriptionController,
              label: "Description",
              icon: Icons.description,
              helpText: "Describe what's included in this package. Be clear about what customers will get.",
              example: "Complete car care package including wash, detailing, and polishing",
              maxLines: 3,
              isRequired: true,
            ),
          const SizedBox(height: 15),
          
          // Vehicle Size Pricing
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Vehicle Size Pricing *",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  UXHelperWidget.showHelpDialog(
                    context,
                    title: "Vehicle Size Pricing",
                    message: "Offer different prices for small vehicles (sedans, hatchbacks) and large vehicles (SUVs, trucks, vans). This helps you price fairly based on the effort required.",
                    example: "Small Vehicle: \$25, Large Vehicle: \$35",
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
          Row(
            children: [
              Expanded(
                child: UXHelperWidget.buildHelpfulInputField(
                  context: context,
                  controller: smallVehiclePriceController,
                  label: "Small Vehicle",
                  icon: Icons.directions_car,
                  helpText: "Enter the price for smaller vehicles like sedans and hatchbacks.",
                  hintText: "e.g., 25",
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: UXHelperWidget.buildHelpfulInputField(
                  context: context,
                  controller: largeVehiclePriceController,
                  label: "Large Vehicle",
                  icon: Icons.local_shipping,
                  helpText: "Enter the price for larger vehicles like SUVs, trucks, and vans.",
                  hintText: "e.g., 35",
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Package Tier
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Package Tier *",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  UXHelperWidget.showHelpDialog(
                    context,
                    title: "Package Tier",
                    message: "Choose the tier that best describes your package. OUTSIDE is basic exterior, BASIC includes interior, ULTRA is premium, and THE BEST is the ultimate package.",
                    example: "BASIC - Standard wash with interior cleaning",
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: selectedTier,
              decoration: InputDecoration(
                hintText: "Select package tier",
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: Icon(Icons.category, color: ColorClass.base_color),
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
          ),
          const SizedBox(height: 15),
          
          // Services Included Section
          Row(
            children: [
              const Expanded(
                child: Text(
                  "What's Included in This Package?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  UXHelperWidget.showHelpDialog(
                    context,
                    title: "Package Services",
                    message: "List all the services that are included in this package. You can add custom services or select from your existing services.",
                    example: "Interior wash, Compounding, Engine cleansing, Waxing",
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
          UXHelperWidget.buildInfoBanner(
            message: "Define what services customers will get. You can add custom services or select from your existing services below.",
            icon: Icons.info_outline,
            backgroundColor: Colors.blue[50],
            iconColor: Colors.blue[700],
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
                const SizedBox(height: 12),
                
                // Quick Add Buttons
                const Text(
                  "Quick Add Common Services:",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    "Interior wash", "Exterior wash", "Compounding", "Engine cleansing",
                    "Waxing", "Polishing", "Tire cleaning", "Dashboard cleaning",
                    "Seat cleaning", "Carpet cleaning", "Window cleaning", "Headlight restoration"
                  ].map((service) {
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
          UXHelperWidget.buildInfoBanner(
            message: "Select which services are included in this package. You can choose from your existing services or add custom ones.",
            icon: Icons.checklist,
          ),
          // const SizedBox(height: 15),
          
          // Custom Services Section
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
                    const Expanded(
                      child: Text(
                        "Add Custom Services",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        UXHelperWidget.showHelpDialog(
                          context,
                          title: "Custom Services",
                          message: "Add services that aren't in your service list. These are just descriptions of what's included in the package.",
                          example: "Dry clean seats, Interior cleaning, Blow dry",
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
                const SizedBox(height: 6),
                const Text(
                  "Add your own services to this package",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customServiceController,
                        decoration: InputDecoration(
                          hintText: "e.g., Dry clean seats, Interior cleaning, Blow dry",
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          prefixIcon: Icon(Icons.add_circle_outline, color: ColorClass.base_color),
                        ),
                        onSubmitted: (value) {
                          _addCustomService(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _addCustomService(customServiceController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorClass.base_color,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Add"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (customServices.isNotEmpty) ...[
                  const Text(
                    "Custom Services:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: customServices.map((service) {
                      return Chip(
                        label: Text(service),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        labelStyle: const TextStyle(color: Colors.blue),
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
          
          const SizedBox(height: 10),
          
          // Existing Services Section
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Select Services to Link (optional)",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  UXHelperWidget.showHelpDialog(
                    context,
                    title: "Existing Services",
                    message: "Select services from your service list. These are services you've already created. You can select multiple services.",
                    example: "Check the boxes next to services you want to include",
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
          const SizedBox(height: 12),
            if (availableServices.isEmpty)
              const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading services..."),
                ],
              ),
            )
          else
            Builder(
              builder: (context) {
                // Show all services (remove price filter - services can have price 0 or null)
                // The price filter was too restrictive and hiding valid services
                final filteredServices = availableServices.toList();
                
                // Debug: Print filtered services
                debugPrint('=== Filtered Services Debug ===');
                debugPrint('Total services after filter: ${filteredServices.length}');
                for (int i = 0; i < filteredServices.length; i++) {
                  final service = filteredServices[i];
                  debugPrint('Filtered Service $i: ${service.serviceTitle}, Price: ${service.price}, ID: ${service.sId}');
                }
                debugPrint('=== End Filtered Services Debug ===');
                
                if (filteredServices.isEmpty) {
                  return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                        Text("No services available", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                        Text("Please create services first", style: TextStyle(color: Colors.grey)),
                ],
              ),
                  );
                }
                
                return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: filteredServices.length,
                itemBuilder: (context, index) {
                    final service = filteredServices[index];
                  final isSelected = selectedServices.contains(service.sId);
                  
                  return Card(
                      margin: EdgeInsets.only(bottom: index == filteredServices.length - 1 ? 0 : 10),
                    child: CheckboxListTile(
                      title: Text(
                        service.serviceTitle ?? "Unknown Service",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        service.description ?? service.about ?? "No description",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      secondary: Text(
                        "\$${service.price ?? 0}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorClass.base_color,
                        ),
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedServices.add(service.sId!);
                          } else {
                            selectedServices.remove(service.sId!);
                          }
                        });
                      },
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
            "Review your package details before updating",
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
                        _buildInfoChip("Price", "\$${smallVehiclePriceController.text}-\$${largeVehiclePriceController.text}")
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
                      // Custom Services
                      ...customServices.map((service) {
                        return Chip(
                          label: Text(service),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          labelStyle: const TextStyle(color: Colors.blue),
                        );
                      }),
                      
                      // Selected Services (from existing services)
                      ...selectedServices.map((serviceId) {
                        
                        final service = availableServices.firstWhere(
                          (s) => s.sId == serviceId,
                          orElse: () => ServicesData(),
                        );
                        
                        if (service.sId != null) {
                          return Chip(
                            label: Text(service.serviceTitle ?? "Unknown Service"),
                            backgroundColor: ColorClass.base_color.withOpacity(0.1),
                            labelStyle: TextStyle(color: ColorClass.base_color),
                          );
                        } else {
                          return const SizedBox.shrink(); // Don't show anything for unknown services
                        }
                      }),
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

  String? _validateDuration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Duration is required";
    }
    final duration = double.tryParse(value.trim());
    if (duration == null) {
      return "Duration must be a valid number";
    }
    if (duration <= 0) {
      return "Duration must be greater than 0";
    }
    if (duration > 24) {
      return "Duration cannot exceed 24 hours";
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
      if (selectedServices.isEmpty && customServices.isEmpty) {
      CommonWidget.errorShowSnackBarFor(context, "Please select or add at least one service");
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
      // Step 2: Review - validate everything before updating
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

  Future<void> _updatePackage() async {
    // Final comprehensive validation before updating package
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
      
      // Send custom services as a separate field (not in description)
      var response = await dataManager!.updatePackage(
        context,
        widget.packageData.sId!,
        packageNameController.text,
        packageDescriptionController.text, // Keep description clean, custom services sent separately
        packagePriceController.text,
        "", // Duration removed - pass empty string
        selectedServices, // Only send actual service IDs
        widget.packageData.isActive ?? true,
        smallVehiclePrice: smallVehiclePriceController.text,
        largeVehiclePrice: largeVehiclePriceController.text,
        packageTier: selectedTier,
        isBestSeller: isBestSeller,
        customServices: customServices, // Send custom services as separate field
      );
      
      Navigator.pop(context); // Close loader
      
      
      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        return;
      }
      
      try {
        var data = PackageModelData.fromJson(jsonDecode(response.body));
        
        if (data.status == "success") {
          CommonWidget.successShowSnackBarFor(context, "Package updated successfully!");
          Navigator.pop(context);
        } else {
          CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to update package");
        }
      } catch (e) {
        CommonWidget.errorShowSnackBarFor(context, "Error parsing response: $e");
      }
    } catch (e) {
      Navigator.pop(context); // Close loader
      CommonWidget.errorShowSnackBarFor(context, "Error updating package: $e");
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