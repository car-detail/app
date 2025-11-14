import 'dart:convert';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/features/packages_model/data_manager/package_data_manager.dart';
import 'package:car_app/features/packages_model/model/package_model_data.dart';
import 'package:car_app/features/services_model/model/services_model_data.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditPackageActivity extends StatefulWidget {
  final PackageData package;
  
  const EditPackageActivity({super.key, required this.package});

  @override
  State<EditPackageActivity> createState() => _EditPackageActivityState();
}

class _EditPackageActivityState extends State<EditPackageActivity> {
  late TextEditingController packageNameController;
  late TextEditingController packageDescriptionController;
  late TextEditingController packagePriceController;
  late TextEditingController packageDurationController;
  
  List<ServicesData> availableServices = [];
  List<String> selectedServices = [];
  bool isActive = true;
  
  PackageDataManager? dataManager;
  SharedPreferences? sharedPreferences;

  @override
  void initState() {
    super.initState();
    packageNameController = TextEditingController(text: widget.package.packageName);
    packageDescriptionController = TextEditingController(text: widget.package.packageDescription);
    packagePriceController = TextEditingController(text: widget.package.packagePrice);
    packageDurationController = TextEditingController(text: widget.package.packageDuration);
    selectedServices = List<String>.from(widget.package.servicesIncluded ?? []);
    isActive = widget.package.isActive ?? true;
    
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = PackageDataManager(sharedPreferences!);
    await getAvailableServices();
  }

  Future<void> getAvailableServices() async {
    var response = await dataManager!.getAllServices(context);
    var data = ServicesModelData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        availableServices.clear();
        availableServices.addAll(data.data!);
      });
    }
  }

  Future<void> updatePackage() async {
    if (packageNameController.text.isEmpty || 
        packageDescriptionController.text.isEmpty ||
        packagePriceController.text.isEmpty ||
        packageDurationController.text.isEmpty) {
      CommonWidget.errorShowSnackBarFor(context, "Please fill all required fields");
      return;
    }
    
    if (selectedServices.isEmpty) {
      CommonWidget.errorShowSnackBarFor(context, "Please select at least one service");
      return;
    }

    try {
      CommonWidget.showLoaderDialog(context, "Updating package...");
      
      var response = await dataManager!.updatePackage(
        context,
        widget.package.sId!,
        packageNameController.text,
        packageDescriptionController.text,
        packagePriceController.text,
        packageDurationController.text,
        selectedServices,
        isActive,
      );
      
      Navigator.pop(context); // Close loader
      
      var data = PackageModelData.fromJson(jsonDecode(response.body));
      if (data.status == "success") {
        CommonWidget.successShowSnackBarFor(context, "Package updated successfully!");
        Navigator.pop(context);
      } else {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to update package");
      }
    } catch (e) {
      Navigator.pop(context); // Close loader
      CommonWidget.errorShowSnackBarFor(context, "Error updating package: $e");
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
        actions: [
          TextButton(
            onPressed: updatePackage,
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package Details
            const Text(
              "Package Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
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
            const SizedBox(height: 20),
            
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
            const SizedBox(height: 20),
            
            // Price and Duration Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Price (\$) *",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: packagePriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "99.99",
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Active Status
            Row(
              children: [
                const Text(
                  "Package Status",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: isActive,
                  onChanged: (value) {
                    setState(() {
                      isActive = value;
                    });
                  },
                  activeColor: ColorClass.base_color,
                ),
                Text(
                  isActive ? "Active" : "Inactive",
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // Services Selection
            const Text(
              "Services Included",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Select which services are included in this package",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            
            if (availableServices.isEmpty)
              const Center(
                child: CircularProgressIndicator(),
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
                        service.serviceName ?? "Unknown Service",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        service.serviceDescription ?? "No description",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      secondary: Text(
                        "\$${service.servicePrice ?? "0"}",
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
              ),
          ],
        ),
      ),
    );
  }
}
