import 'dart:convert';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/services_model/data_manager/services_data_manager.dart';
import 'package:car_app/features/services_model/model/add_services_bean.dart';
import 'package:car_app/features/home_module/model/category_model_data.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleAddServicesActivity extends StatefulWidget {
  const SimpleAddServicesActivity({super.key});

  @override
  State<SimpleAddServicesActivity> createState() => _SimpleAddServicesActivityState();
}

class _SimpleAddServicesActivityState extends State<SimpleAddServicesActivity> {
  int currentStep = 0;
  final PageController _pageController = PageController();
  
  // Service Details
  TextEditingController serviceNameController = TextEditingController();
  TextEditingController serviceDescriptionController = TextEditingController();
  TextEditingController servicePriceController = TextEditingController();
  TextEditingController serviceDurationController = TextEditingController();
  
  // Category
  String selectedCategoryId = "";
  String selectedCategoryName = "";
  List<CategoryData> categories = [];
  
  ServicesDataManager? dataManager;
  SharedPreferences? sharedPreferences;

  // Pre-defined service templates for easy selection
  final List<ServiceTemplate> serviceTemplates = [
    ServiceTemplate(
      name: "Basic Car Wash",
      description: "Exterior wash, tire cleaning, and basic interior vacuum",
      price: "25",
      duration: "1",
      category: "Car Wash",
    ),
    ServiceTemplate(
      name: "Premium Car Wash",
      description: "Complete exterior wash, wax, tire shine, and interior cleaning",
      price: "50",
      duration: "2",
      category: "Car Wash",
    ),
    ServiceTemplate(
      name: "Oil Change",
      description: "Engine oil change with filter replacement",
      price: "40",
      duration: "1",
      category: "Maintenance",
    ),
    ServiceTemplate(
      name: "Tire Rotation",
      description: "Rotate tires for even wear and extend tire life",
      price: "20",
      duration: "1",
      category: "Maintenance",
    ),
    ServiceTemplate(
      name: "Brake Inspection",
      description: "Complete brake system inspection and safety check",
      price: "30",
      duration: "1",
      category: "Repair",
    ),
    ServiceTemplate(
      name: "AC Service",
      description: "AC system cleaning, filter replacement, and gas refill",
      price: "60",
      duration: "2",
      category: "Repair",
    ),
  ];

  @override
  void initState() {
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = ServicesDataManager(sharedPreferences!);
    await getCategories();
  }

  Future<void> getCategories() async {
    try {
      var response = await dataManager!.getcategory(context);
      var data = CategoryModelData.fromJson(jsonDecode(response.body));
      
      if (data.status == "success" && data.data != null) {
        setState(() {
          categories.clear();
          categories.addAll(data.data!);
        });
      }
    } catch (e) {
      print("Error fetching categories: $e");
      // Fallback to hardcoded categories if API fails
      setState(() {
        categories.clear();
        categories.addAll([
          CategoryData(sId: "1", categoryTitle: "Car Wash"),
          CategoryData(sId: "2", categoryTitle: "Maintenance"),
          CategoryData(sId: "3", categoryTitle: "Repair"),
          CategoryData(sId: "4", categoryTitle: "Detailing"),
        ]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Service"),
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
                _buildStepIndicator(0, "Template"),
                Expanded(child: _buildStepLine(0)),
                _buildStepIndicator(1, "Details"),
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
                _buildTemplateStep(),
                _buildDetailsStep(),
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
                    onPressed: currentStep < 2 ? _nextStep : _createService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorClass.base_color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(currentStep < 2 ? "Next" : "Create Service"),
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

  Widget _buildTemplateStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Choose a Service Template",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Select a template to get started quickly, or create your own",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          
          Expanded(
            child: ListView.builder(
              itemCount: serviceTemplates.length,
              itemBuilder: (context, index) {
                final template = serviceTemplates[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: ColorClass.base_color.withOpacity(0.1),
                      child: Icon(
                        _getCategoryIcon(template.category),
                        color: ColorClass.base_color,
                      ),
                    ),
                    title: Text(
                      template.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template.description),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _buildInfoChip("\$${template.price}", "green"),
                            _buildInfoChip("${template.duration}h", "blue"),
                            _buildInfoChip(template.category, "orange"),
                          ],
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        _selectTemplate(template);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorClass.base_color,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 36),
                      ),
                      child: const Text("Use"),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text("Create Custom Service Instead"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Service Details",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Fill in the details for your service",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          
          // Service Name
          const Text(
            "Service Name *",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: serviceNameController,
            decoration: InputDecoration(
              hintText: "e.g., Premium Car Wash",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.design_services),
            ),
          ),
          const SizedBox(height: 20),
          
          // Service Description
          const Text(
            "Description *",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: serviceDescriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Describe what this service includes...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 20),
          
          // Category Selection
          const Text(
            "Category *",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedCategoryId.isEmpty ? null : selectedCategoryId,
            decoration: InputDecoration(
              hintText: "Select a category",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.category),
            ),
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category.sId,
                child: Text(category.categoryTitle ?? ""),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategoryId = value ?? "";
                selectedCategoryName = categories
                    .firstWhere((c) => c.sId == value)
                    .categoryTitle ?? "";
              });
            },
          ),
          const SizedBox(height: 20),
          
          // Price and Duration Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Price (\$) (Optional)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: servicePriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "25.00",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Duration (hours) *",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: serviceDurationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "1",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.schedule),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Review Service",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Review your service details before creating",
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
                    serviceNameController.text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    serviceDescriptionController.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildInfoChip("Category", selectedCategoryName),
                      const SizedBox(width: 10),
                      _buildInfoChip("Price", "\$${servicePriceController.text}"),
                      const SizedBox(width: 10),
                      _buildInfoChip("Duration", "${serviceDurationController.text} hours"),
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
    Color chipColor = ColorClass.base_color;
    if (value == "green") chipColor = Colors.green;
    if (value == "blue") chipColor = Colors.blue;
    if (value == "orange") chipColor = Colors.orange;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'car wash':
        return Icons.local_car_wash;
      case 'maintenance':
        return Icons.build;
      case 'repair':
        return Icons.handyman;
      default:
        return Icons.design_services;
    }
  }

  void _selectTemplate(ServiceTemplate template) {
    setState(() {
      serviceNameController.text = template.name;
      serviceDescriptionController.text = template.description;
      servicePriceController.text = template.price;
      serviceDurationController.text = template.duration;
      
      // Find matching category
      final category = categories.firstWhere(
        (c) => c.categoryTitle?.toLowerCase().contains(template.category.toLowerCase()) ?? false,
        orElse: () => categories.isNotEmpty ? categories.first : CategoryData(),
      );
      selectedCategoryId = category.sId ?? "";
      selectedCategoryName = category.categoryTitle ?? "";
    });
    
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (currentStep == 0) {
      // Template step - can proceed without selection
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (currentStep == 1) {
      if (serviceNameController.text.isEmpty || 
          serviceDescriptionController.text.isEmpty ||
          serviceDurationController.text.isEmpty ||
          selectedCategoryId.isEmpty) {
        CommonWidget.errorShowSnackBarFor(context, "Please fill all required fields");
        return;
      }
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createService() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      var response = await dataManager!.postServies(
        context,
        serviceNameController.text,
        serviceDescriptionController.text,
        "1", // timeSlot
        servicePriceController.text.isEmpty ? "0" : servicePriceController.text,
        serviceDurationController.text,
        selectedCategoryName, // catName
        selectedCategoryId,
        "", // serviceImage
        "", // mobile
      );
      
      Navigator.pop(context); // Close loader
      
      var data = AddServicesBean.fromJson(jsonDecode(response.body));
      if (data.status == "success") {
        CommonWidget.successShowSnackBarFor(context, "Service created successfully!");
        Navigator.pop(context);
      } else {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to create service");
      }
    } catch (e) {
      Navigator.pop(context); // Close loader
      CommonWidget.errorShowSnackBarFor(context, "Error creating service: $e");
    }
  }
}

class ServiceTemplate {
  final String name;
  final String description;
  final String price;
  final String duration;
  final String category;

  ServiceTemplate({
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.category,
  });
}
