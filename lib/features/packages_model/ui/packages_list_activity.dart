import 'dart:convert';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/packages_model/data_manager/package_data_manager.dart';
import 'package:car_app/features/packages_model/model/package_model_data.dart';
import 'package:car_app/features/packages_model/ui/add_package_activity.dart';
import 'package:car_app/features/packages_model/ui/edit_package_activity.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PackagesListActivity extends StatefulWidget {
  const PackagesListActivity({super.key});

  @override
  State<PackagesListActivity> createState() => _PackagesListActivityState();
}

class _PackagesListActivityState extends State<PackagesListActivity> {
  List<PackageData> packages = [];
  bool isLoading = true;
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
    await getPackages();
  }

  Future<void> getPackages() async {
    setState(() {
      isLoading = true;
    });

    print("🔄 Loading packages...");
    var response = await dataManager!.getAllPackages(context);
    print("📡 Packages API Response Status: ${response.statusCode}");
    print("📡 Packages API Response Body: ${response.body}");
    
    try {
      var data = PackageModelData.fromJson(jsonDecode(response.body));
      print("📦 Packages Data Status: ${data.status}");
      print("📦 Packages Count: ${data.data?.length ?? 0}");
      
      if (data.status == "success") {
        setState(() {
          packages.clear();
          packages.addAll(data.data!);
        });
        print("✅ Packages loaded successfully: ${packages.length} packages");
      } else {
        print("❌ Packages API returned error: ${data.message}");
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to load packages");
      }
    } catch (e, stackTrace) {
      print("❌ Error parsing packages response: $e");
      print("❌ Stack Trace: $stackTrace");
      CommonWidget.errorShowSnackBarFor(context, "Error loading packages: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deletePackage(PackageData package) async {
    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Package"),
          content: Text("Are you sure you want to delete '${package.packageName}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        var response = await dataManager!.deletePackage(context, package.sId!);

        print("📦 Delete Package Response Status: ${response.statusCode}");
        print("📦 Delete Package Response Body: ${response.body}");

        // Check if response is HTML (error page) instead of JSON
        if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
          return;
        }

        try {
          var data = PackageModelData.fromJson(jsonDecode(response.body));
          print("📦 Delete Data Status: ${data.status}");
          print("📦 Delete Data Message: ${data.message}");

          if (data.status == "success") {
            CommonWidget.successShowSnackBarFor(context, "Package deleted successfully!");
            await getPackages(); // Refresh the list
          } else {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to delete package");
          }
        } catch (e, stackTrace) {
          print("❌ Error parsing delete response: $e");
          print("❌ Stack Trace: $stackTrace");
          print("❌ Response body: ${response.body}");
          CommonWidget.errorShowSnackBarFor(context, "Error parsing response: $e");
        }
      } catch (e, stackTrace) {
        print("❌ Delete Package Error: $e");
        print("❌ Stack Trace: $stackTrace");
        CommonWidget.errorShowSnackBarFor(context, "Error deleting package: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // Enhanced Header with Back Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorClass.base_color,
                    ColorClass.base_color.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "My Packages",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${packages.length} packages available",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPackageActivity(),
                        ),
                      );
                      if (result == true) {
                        await getPackages(); // Refresh the list
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (packages.isNotEmpty)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    getPackages();
                  },
                  child: ListView.builder(
                      itemCount: packages.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final package = packages[index];
                        return _buildPackageCard(package);
                      }),
                ),
              ),
            if (packages.isEmpty && !isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        "No packages found",
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Create your first package to get started",
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            if (isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: ColorClass.base_color),
                      const SizedBox(height: 16),
                      Text(
                        "Loading packages...",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(PackageData package) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPackageActivity(packageData: package),
            ),
          );
          if (result == true) {
            await getPackages(); // Refresh the list
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      package.packageName ?? "Unnamed Package",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (package.isActive ?? true) 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (package.isActive ?? true) ? "Active" : "Inactive",
                      style: TextStyle(
                        color: (package.isActive ?? true) ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                package.packageDescription ?? "No description",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Price and Duration
              Row(
                children: [
                  _buildInfoChip(Icons.attach_money, "\$${package.packagePrice ?? "0"}"),
                  const SizedBox(width: 10),
                  _buildInfoChip(Icons.schedule, "${package.packageDuration ?? "0"} hrs"),
                  const SizedBox(width: 10),
                  if (package.servicesIncluded != null)
                    _buildInfoChip(Icons.build, "${package.servicesIncluded!.length} services"),
                ],
              ),
              const SizedBox(height: 12),
              
              // Services Preview
              if (package.servicesIncluded != null && package.servicesIncluded!.isNotEmpty) ...[
                const Text(
                  "Services:",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: package.servicesIncluded!.take(3).map((serviceId) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ColorClass.base_color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Service $serviceId",
                        style: TextStyle(
                          color: ColorClass.base_color,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList()
                    ..addAll(
                      package.servicesIncluded!.length > 3
                          ? [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "+${package.servicesIncluded!.length - 3} more",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ]
                          : [],
                    ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPackageActivity(packageData: package),
                          ),
                        );
                        if (result == true) {
                          await getPackages(); // Refresh the list
                        }
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text("Edit"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorClass.base_color,
                        side: BorderSide(color: ColorClass.base_color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deletePackage(package),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text("Delete"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
