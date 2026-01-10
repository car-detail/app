import 'dart:convert';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/Common/UXHelperWidget.dart';
import 'package:car_app/features/packages_model/data_manager/package_data_manager.dart';
import 'package:car_app/features/home_module/model/services_model_data.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ultra-simple package addition - just name, price, and select services
class UltraSimpleAddPackage extends StatefulWidget {
  const UltraSimpleAddPackage({super.key});

  @override
  State<UltraSimpleAddPackage> createState() => _UltraSimpleAddPackageState();
}

class _UltraSimpleAddPackageState extends State<UltraSimpleAddPackage> {
  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  List<ServicesData> _availableServices = [];
  List<String> _selectedServiceIds = [];
  PackageDataManager? dataManager;
  SharedPreferences? sharedPreferences;

  // Quick package templates
  final List<Map<String, dynamic>> _quickTemplates = [
    {
      "name": "Basic Package",
      "price": "50",
      "description": "Includes 2-3 basic services",
    },
    {
      "name": "Premium Package",
      "price": "100",
      "description": "Includes 3-5 premium services",
    },
    {
      "name": "Complete Package",
      "price": "150",
      "description": "Includes 5+ services",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = PackageDataManager(sharedPreferences!);
    await _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final vendorId = sharedPreferences?.getString(Constant.vendorId) ?? "";
      if (vendorId.isEmpty) return;

      var response = await dataManager!.getAllServices(context);
      if (response.statusCode == 200) {
        var data = ServicesModelData.fromJson(jsonDecode(response.body));
        if (data.status == "success" && data.data != null) {
          setState(() {
            _availableServices = data.data!;
          });
        }
      }
    } catch (e) {
      print("Error loading services: $e");
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
          "Add Package",
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
              message: "A package is a combination of services sold together at a special price. Just give it a name and price!",
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
                      _packageNameController.text = template["name"] as String;
                      _priceController.text = template["price"] as String;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template["name"] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "\$${template["price"]}",
                          style: TextStyle(
                            color: ColorClass.base_color,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template["description"] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            
            // Package name
            UXHelperWidget.buildHelpfulInputField(
              controller: _packageNameController,
              label: "Package Name",
              icon: Icons.inventory_2,
              helpText: "What do you want to call this package?",
              example: "Complete Car Care Package",
              isRequired: true,
              context: context,
            ),
            const SizedBox(height: 20),
            
            // Price
            UXHelperWidget.buildHelpfulInputField(
              controller: _priceController,
              label: "Package Price",
              icon: Icons.attach_money,
              helpText: "Total price for this package",
              example: "100",
              keyboardType: TextInputType.number,
              isRequired: true,
              context: context,
            ),
            const SizedBox(height: 20),
            
            // Select services (optional but helpful)
            if (_availableServices.isNotEmpty) ...[
              Text(
                "Which services are included? (Optional)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Tap to select services. You can add more later!",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableServices.length,
                  itemBuilder: (context, index) {
                    final service = _availableServices[index];
                    final isSelected = _selectedServiceIds.contains(service.sId);
                    return CheckboxListTile(
                      title: Text(service.serviceTitle ?? ""),
                      subtitle: Text("\$${service.price ?? "0"}"),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedServiceIds.add(service.sId ?? "");
                          } else {
                            _selectedServiceIds.remove(service.sId ?? "");
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Add some services first, then you can create packages!",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePackage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorClass.base_color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Create Package",
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

  void _savePackage() async {
    if (_packageNameController.text.trim().isEmpty) {
      UXHelperWidget.showFriendlyError(
        context,
        "Please enter a package name!",
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

      var response = await dataManager!.createPackage(
        context,
        _packageNameController.text.trim(), // packageName
        "Package includes selected services", // packageDescription
        _priceController.text.trim(), // packagePrice
        "1", // packageDuration (default 1 hour)
        _selectedServiceIds, // servicesIncluded
      );

      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context); // Close loading
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (context.mounted) {
          UXHelperWidget.showSuccessMessage(
            context,
            "Package created successfully! You can add more packages anytime.",
          );
        }
        CommonWidget.safePop(context); // Go back
      } else {
        if (context.mounted) {
          UXHelperWidget.showFriendlyError(
            context,
            "Couldn't create package. Please try again.",
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

