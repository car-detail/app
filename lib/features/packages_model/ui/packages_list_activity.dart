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
    if (!mounted || !context.mounted) return;
    
    setState(() {
      isLoading = true;
    });

    
    try {
      var response = await dataManager!.getAllPackages(context);
      
      if (!mounted || !context.mounted) return;
      
      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }
      
      // Check response status code
      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to load packages. Please check your connection and try again.");
        }
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }
      
      try {
        var data = PackageModelData.fromJson(jsonDecode(response.body));
        
        if (data.status == "success") {
          if (mounted) {
            setState(() {
              packages.clear();
              packages.addAll(data.data!);
            });
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to load packages");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error parsing packages data. Please try again.");
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error loading packages. Please check your connection and try again.");
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
              onPressed: () {
                if (mounted && context.mounted) {
                  Navigator.of(context).pop(false);
                }
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (mounted && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
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


        if (!mounted || !context.mounted) return;
        
        // Check if response is HTML (error page) instead of JSON
        if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
          }
          return;
        }

        try {
          var data = PackageModelData.fromJson(jsonDecode(response.body));

          if (data.status == "success") {
            if (mounted && context.mounted) {
              CommonWidget.successShowSnackBarFor(context, "Package deleted successfully!");
            }
            if (mounted && context.mounted) {
              await getPackages(); // Refresh the list
            }
          } else {
            if (mounted && context.mounted) {
              CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to delete package");
            }
          }
        } catch (e) {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, "Error parsing response: $e");
          }
        }
      } catch (e) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error deleting package: $e");
        }
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
                      if (mounted && context.mounted) {
                        Navigator.pop(context);
                      }
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
                      if (mounted && context.mounted) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddPackageActivity(),
                          ),
                        );
                        if (mounted && context.mounted && result == true) {
                          await getPackages(); // Refresh the list
                        }
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
    final isBestSeller = package.isBestSeller ?? false;
    final smallPrice = double.tryParse(package.smallVehiclePrice ?? package.packagePrice ?? "0") ?? 0;
    final largePrice = double.tryParse(package.largeVehiclePrice ?? package.packagePrice ?? "0") ?? 0;
    final duration = double.tryParse(package.packageDuration ?? "0") ?? 0;
    final servicesCount = package.servicesIncluded?.length ?? 0;
    final isActive = package.isActive ?? true;
    final primaryColor = ColorClass.base_color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          // Main Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                  spreadRadius: -8,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPackageActivity(packageData: package),
                      ),
                    );
                    if (result == true) {
                      await getPackages();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Package Name
                                  Text(
                                    package.packageName ?? "Unnamed Package",
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -1,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Description
                                  Text(
                                    package.packageDescription ?? "No description",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                      height: 1.4,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive 
                                    ? const Color(0xFF10B981).withOpacity(0.12)
                                    : Colors.grey.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: isActive 
                                          ? const Color(0xFF10B981)
                                          : Colors.grey[600],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isActive ? "Active" : "Inactive",
                                    style: TextStyle(
                                      color: isActive 
                                          ? const Color(0xFF10B981)
                                          : Colors.grey[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Pricing Cards - Modern Design
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernPriceCard(
                                icon: Icons.directions_car_rounded,
                                label: "Car",
                                price: smallPrice,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernPriceCard(
                                icon: Icons.local_shipping_rounded,
                                label: "Truck",
                                price: largePrice,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Bottom Info Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              _buildInfoBadge(
                                icon: Icons.access_time_rounded,
                                text: "${duration.toStringAsFixed(0)}h",
                              ),
                              const SizedBox(width: 16),
                              _buildInfoBadge(
                                icon: Icons.build_rounded,
                                text: "$servicesCount services",
                              ),
                              const Spacer(),
                              if (package.packageTier != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    package.packageTier!,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernActionButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditPackageActivity(packageData: package),
                                    ),
                                  );
                                  if (result == true) {
                                    await getPackages();
                                  }
                                },
                                label: "Edit",
                                icon: Icons.edit_rounded,
                                color: primaryColor,
                                isPrimary: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernActionButton(
                                onPressed: () => _deletePackage(package),
                                label: "Delete",
                                icon: Icons.delete_outline_rounded,
                                color: const Color(0xFFEF4444),
                                isPrimary: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Best Seller Badge - Floating
          if (isBestSeller)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "BEST SELLER",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernPriceCard({
    required IconData icon,
    required String label,
    required double price,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "\$${price.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }




  Widget _buildModernActionButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color color,
    required bool isPrimary,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isPrimary ? color : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isPrimary ? null : Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary ? Colors.white : color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? Colors.white : color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
