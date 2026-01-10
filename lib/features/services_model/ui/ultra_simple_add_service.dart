import 'dart:convert';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/Common/UXHelperWidget.dart';
import 'package:car_app/features/services_model/data_manager/services_data_manager.dart';
import 'package:car_app/features/services_model/model/add_services_bean.dart';
import 'package:car_app/features/home_module/model/category_model_data.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ultra-simple service addition - just name and price
class UltraSimpleAddService extends StatefulWidget {
  const UltraSimpleAddService({super.key});

  @override
  State<UltraSimpleAddService> createState() => _UltraSimpleAddServiceState();
}

class _UltraSimpleAddServiceState extends State<UltraSimpleAddService> {
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  String _selectedCategoryId = "";
  String _selectedCategoryName = "";
  List<CategoryData> _categories = [];
  ServicesDataManager? dataManager;
  SharedPreferences? sharedPreferences;

  // Quick templates
  final List<Map<String, String>> _quickTemplates = [
    {"name": "Basic Wash", "price": "25"},
    {"name": "Premium Wash", "price": "50"},
    {"name": "Full Detailing", "price": "100"},
    // {"name": "Oil Change", "price": "40"},
    // {"name": "Tire Service", "price": "30"},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = ServicesDataManager(sharedPreferences!);
    await _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      var response = await dataManager!.getcategory(context);
      var data = CategoryModelData.fromJson(jsonDecode(response.body));
      if (data.status == "success" && data.data != null && data.data!.isNotEmpty) {
        setState(() {
          _categories = data.data!;
          _selectedCategoryName = _categories.first.categoryTitle ?? "";
          _selectedCategoryId = _categories.first.sId ?? "";
        });
      }
    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => CommonWidget.safePop(context),
        ),
        title: const Text(
          "Add Service",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            UXHelperWidget.buildInfoBanner(
              message: "Just enter the service name and price. We'll set everything else up for you!",
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 30),
            
            // Quick templates
            const Text(
              "Or choose a quick template:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _quickTemplates.map((template) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _serviceNameController.text = template["name"]!;
                      _priceController.text = template["price"]!;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          template["name"]!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "\$${template["price"]}",
                          style: TextStyle(
                            color: ColorClass.base_color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            
            // Service name
            UXHelperWidget.buildHelpfulInputField(
              controller: _serviceNameController,
              label: "Service Name",
              icon: Icons.design_services,
              helpText: "What do you call this service?",
              example: "Basic Car Wash",
              isRequired: true,
              context: context,
            ),
            const SizedBox(height: 20),
            
            // Price
            UXHelperWidget.buildHelpfulInputField(
              controller: _priceController,
              label: "Price",
              icon: Icons.attach_money,
              helpText: "How much do you charge for this service?",
              example: "25",
              keyboardType: TextInputType.number,
              isRequired: true,
              context: context,
            ),
            const SizedBox(height: 20),
            
            // Category (auto-selected, but can change)
            if (_categories.isNotEmpty) ...[
              Text(
                "Service Type",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButton<String>(
                  value: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
                  isExpanded: true,
                  hint: const Text("Select category"),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category.sId,
                      child: Text(category.categoryTitle ?? ""),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value ?? "";
                      _selectedCategoryName = _categories
                          .firstWhere((c) => c.sId == value)
                          .categoryTitle ?? "";
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Smart defaults info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "We'll automatically set: Duration (30-60 min), Time slots, and Capacity. You can change these later!",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorClass.base_color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Add Service",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

  void _saveService() async {
    if (_serviceNameController.text.trim().isEmpty) {
      UXHelperWidget.showFriendlyError(
        context,
        "Please enter a service name!",
      );
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      UXHelperWidget.showFriendlyError(
        context,
        "Please enter a price!",
      );
      return;
    }

    if (_selectedCategoryId.isEmpty && _categories.isNotEmpty) {
      UXHelperWidget.showFriendlyError(
        context,
        "Please select a service type!",
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final vendorId = sharedPreferences?.getString(Constant.vendorId) ?? "";
      
      if (vendorId.isEmpty) {
        if (context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        if (context.mounted) {
          UXHelperWidget.showFriendlyError(
            context,
            "Please complete your business registration first!",
          );
        }
        return;
      }

      // Use smart defaults
      final mobile = sharedPreferences?.getString(Constant.mobile) ?? "";
      
      var response = await dataManager!.postServies(
        context,
        _serviceNameController.text.trim(), // title
        "Professional ${_serviceNameController.text.trim()} service", // about
        "5", // timeSlot
        _priceController.text.trim(), // price
        "30-60 minutes", // duration
        _selectedCategoryName, // catName
        _selectedCategoryId, // categoryId
        "", // serviceImage
        mobile, // mobile
      );

      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context); // Close loading
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (context.mounted) {
          UXHelperWidget.showSuccessMessage(
            context,
            "Service added successfully! You can add more services anytime.",
          );
        }
        CommonWidget.safePop(context); // Go back
      } else {
        if (context.mounted) {
          UXHelperWidget.showFriendlyError(
            context,
            "Couldn't add service. Please try again.",
          );
        }
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
      UXHelperWidget.showFriendlyError(
        context,
        "Error: ${e.toString()}. Please try again.",
      );
    }
  }
}

