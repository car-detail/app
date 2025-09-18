import 'dart:convert';
import 'dart:io';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/packages_model/data_manager/package_data_manager.dart';
import 'package:car_app/features/packages_model/model/package_model_data.dart';
import 'package:car_app/features/home_module/model/services_model_data.dart';
import 'package:flutter/material.dart';
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
  TextEditingController packageDurationController = TextEditingController();
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
    // Populate form fields with existing package data
    packageNameController.text = widget.packageData.packageName ?? "";
    packageDescriptionController.text = widget.packageData.packageDescription ?? "";
    packagePriceController.text = widget.packageData.packagePrice ?? "";
    packageDurationController.text = widget.packageData.packageDuration ?? "";
    smallVehiclePriceController.text = widget.packageData.smallVehiclePrice ?? "";
    largeVehiclePriceController.text = widget.packageData.largeVehiclePrice ?? "";
    selectedTier = widget.packageData.packageTier ?? "BASIC";
    isBestSeller = widget.packageData.isBestSeller ?? false;
    
    // Populate selected services
    selectedServices = List<String>.from(widget.packageData.servicesIncluded ?? []);
    
    // Extract custom services from description if any
    _extractCustomServicesFromDescription();
    
    print("🔍 Populated form data:");
    print("🔍 Package Name: ${packageNameController.text}");
    print("🔍 Description: ${packageDescriptionController.text}");
    print("🔍 Price: ${packagePriceController.text}");
    print("🔍 Selected Services: $selectedServices");
    print("🔍 Custom Services: $customServices");
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
      print("✅ Added custom service: ${serviceName.trim()}");
      print("🔍 Custom services now: $customServices");
    }
  }

  Future<void> getAvailableServices() async {
    print("🔄 Loading available services...");
    var response = await dataManager!.getAllServices(context);
    print("📡 Services API Response Status: ${response.statusCode}");
    print("📡 Services API Response Body: ${response.body}");
    
    try {
    var data = ServicesModelData.fromJson(jsonDecode(response.body));
      print("📦 Services Data Status: ${data.status}");
      print("📦 Services Count: ${data.data?.length ?? 0}");
      
    if (data.status == "success") {
      setState(() {
        availableServices.clear();
        availableServices.addAll(data.data!);
      });
        print("✅ Services loaded successfully: ${availableServices.length} services");
        
        // Debug: Print details of each service
        for (int i = 0; i < availableServices.length; i++) {
          final service = availableServices[i];
          print("🔍 Service $i: ID=${service.sId}, Title=${service.serviceTitle}, About=${service.about}, Description=${service.description}, Price=${service.price}");
        }
        
        // Debug: Print selected services
        print("🔍 Selected Services: $selectedServices");
      } else {
        print("❌ Services API returned error: ${data.message}");
      }
    } catch (e, stackTrace) {
      print("❌ Error parsing services response: $e");
      print("❌ Stack Trace: $stackTrace");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Package"),
        backgroundColor: ColorClass.base_color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
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
            "Update your package information",
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
          
          // Vehicle Size Pricing
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
            value: selectedTier,
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
          
          // Duration
                      const Text(
                        "Duration (hours) *",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: packageDurationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "2",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.schedule),
                        ),
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
                  activeColor: ColorClass.base_color,
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
                const Text(
                  "Add Custom Services",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Add your own services to this package",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customServiceController,
                        decoration: const InputDecoration(
                          hintText: "e.g., Dry clean seats, Interior cleaning, Blow dry",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      child: const Text("Add"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (customServices.isNotEmpty) ...[
                  const Text(
                    "Custom Services:",
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
          
            const SizedBox(height: 20),
          
          // Existing Services Section
          const Text(
            "Select from Existing Services",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
            
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
          else if (availableServices.length == 0)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No services available", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text("Please add some services first", style: TextStyle(color: Colors.grey)),
                ],
              ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: availableServices.length,
                itemBuilder: (context, index) {
                  final service = availableServices[index];
                  final isSelected = selectedServices.contains(service.sId);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
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
                            print("✅ Added service: ${service.serviceTitle} (ID: ${service.sId})");
                            print("🔍 Selected services now: $selectedServices");
                          } else {
                            selectedServices.remove(service.sId!);
                            print("❌ Removed service: ${service.serviceTitle} (ID: ${service.sId})");
                            print("🔍 Selected services now: $selectedServices");
                          }
                        });
                      },
                    ),
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
                      _buildInfoChip("Price", "\$${packagePriceController.text}"),
                      const SizedBox(width: 10),
                      _buildInfoChip("Duration", "${packageDurationController.text} hours"),
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
                      }).toList(),
                      
                      // Selected Services (from existing services)
                      ...selectedServices.map((serviceId) {
                        print("🔍 Looking for service with ID: $serviceId");
                        
                        final service = availableServices.firstWhere(
                          (s) => s.sId == serviceId,
                          orElse: () => ServicesData(),
                        );
                        
                        if (service.sId != null) {
                          print("🔍 Found service: ${service.serviceTitle} (ID: ${service.sId})");
                          return Chip(
                            label: Text(service.serviceTitle ?? "Unknown Service"),
                            backgroundColor: ColorClass.base_color.withOpacity(0.1),
                            labelStyle: TextStyle(color: ColorClass.base_color),
                          );
                        } else {
                          print("❌ Service not found for ID: $serviceId");
                          return const SizedBox.shrink(); // Don't show anything for unknown services
                        }
                      }).toList(),
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
      packageDurationController.text = template.duration;
      selectedTier = template.tier;
      isBestSeller = template.isBestSeller;
      
      // Add template services as custom services instead of selected services
      customServices.clear();
      customServices.addAll(template.services);
      selectedServices.clear(); // Clear any existing selected services
    });
    
    CommonWidget.successShowSnackBarFor(context, "Package template selected!");
  }

  void _nextStep() {
    if (currentStep == 0) {
      if (packageNameController.text.isEmpty || 
          packageDescriptionController.text.isEmpty ||
          smallVehiclePriceController.text.isEmpty ||
          largeVehiclePriceController.text.isEmpty ||
          packageDurationController.text.isEmpty) {
        CommonWidget.errorShowSnackBarFor(context, "Please fill all required fields");
        return;
      }
      
      if (customServices.isEmpty && selectedServices.isEmpty) {
        CommonWidget.errorShowSnackBarFor(context, "Please add at least one service to the package");
        return;
      }
    } else if (currentStep == 1) {
      if (selectedServices.isEmpty && customServices.isEmpty) {
        CommonWidget.errorShowSnackBarFor(context, "Please select at least one service");
        return;
      }
    }
    
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _updatePackage() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Only send actual service IDs (not custom service names)
      // Custom services will be handled in the package description or as a separate field
      print("🔍 Updating package with services:");
      print("🔍 Selected services (IDs): $selectedServices");
      print("🔍 Custom services (names): $customServices");
      
      // Create a combined description that includes custom services
      String combinedDescription = packageDescriptionController.text;
      if (customServices.isNotEmpty) {
        combinedDescription += "\n\nServices included:\n• ${customServices.join('\n• ')}";
      }
      
      var response = await dataManager!.updatePackage(
        context,
        widget.packageData.sId!,
        packageNameController.text,
        combinedDescription, // Include custom services in description
        packagePriceController.text,
        packageDurationController.text,
        selectedServices, // Only send actual service IDs
        widget.packageData.isActive ?? true,
      );
      
      Navigator.pop(context); // Close loader
      
      print("📦 Package Update Response Status: ${response.statusCode}");
      print("📦 Package Update Response Body: ${response.body}");
      
      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        return;
      }
      
      try {
        var data = PackageModelData.fromJson(jsonDecode(response.body));
        print("📦 Package Data Status: ${data.status}");
        print("📦 Package Data Message: ${data.message}");
        
        if (data.status == "success") {
          CommonWidget.successShowSnackBarFor(context, "Package updated successfully!");
          Navigator.pop(context);
        } else {
          CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to update package");
        }
      } catch (e, stackTrace) {
        print("❌ Error parsing package update response: $e");
        print("❌ Stack Trace: $stackTrace");
        print("❌ Response body: ${response.body}");
        CommonWidget.errorShowSnackBarFor(context, "Error parsing response: $e");
      }
    } catch (e, stackTrace) {
      Navigator.pop(context); // Close loader
      print("❌ Package Update Error: $e");
      print("❌ Stack Trace: $stackTrace");
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