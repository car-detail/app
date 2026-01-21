import 'dart:convert';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/features/packages_model/data_manager/package_data_manager.dart';
import 'package:car_app/features/packages_model/model/package_model_data.dart';
import 'package:car_app/features/packages_model/ui/add_package_activity.dart';
import 'package:car_app/features/packages_model/ui/edit_package_activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PackageListActivity extends StatefulWidget {
  const PackageListActivity({super.key});

  @override
  State<PackageListActivity> createState() => _PackageListActivityState();
}

class _PackageListActivityState extends State<PackageListActivity> {
  List<PackageData> packages = [];
  PackageDataManager? dataManager;
  SharedPreferences? sharedPreferences;
  bool isLoading = true;

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
    
    try {
      var response = await dataManager!.getAllPackages(context);
      var data = PackageModelData.fromJson(jsonDecode(response.body));
      
      if (data.status == "success") {
        setState(() {
          packages.clear();
          packages.addAll(data.data!);
        });
      } else {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to load packages");
      }
    } catch (e) {
      CommonWidget.errorShowSnackBarFor(context, "Error loading packages: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deletePackage(String packageId) async {
    try {
      var response = await dataManager!.deletePackage(context, packageId);
      var data = PackageModelData.fromJson(jsonDecode(response.body));
      
      if (data.status == "success") {
        CommonWidget.successShowSnackBarFor(context, "Package deleted successfully");
        getPackages(); // Refresh the list
      } else {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to delete package");
      }
    } catch (e) {
      CommonWidget.errorShowSnackBarFor(context, "Error deleting package: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: ColorClass.base_color,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Stack(
          children: [
            // Green status bar background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).padding.top,
                color: ColorClass.base_color,
                width: double.infinity,
              ),
            ),
            // Main content
            Column(
          children: [
            // Enhanced Header with Back Button
            Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
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
                  CommonWidget.buildBackButton(
                    context,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    iconColor: Colors.white,
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
                ],
              ),
            ),
            if (packages.isNotEmpty)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    getPackages();
                  },
                  child: _buildPackagesList(),
                ),
              ),
            if (packages.isEmpty && !isLoading)
              Expanded(
                child: _buildEmptyState(),
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
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddPackageActivity(),
              ),
            ).then((_) => getPackages());
          },
          backgroundColor: ColorClass.base_color,
          tooltip: "Add Package",
          child: const Icon(Icons.add, color: Colors.white),
        ),
        ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              "No Packages Yet",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Create your first package to start offering bundled services to customers",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPackageActivity(),
                  ),
                ).then((_) => getPackages());
              },
              icon: const Icon(Icons.add),
              label: const Text("Create Package"),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorClass.base_color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackagesList() {
    return RefreshIndicator(
      onRefresh: getPackages,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final package = packages[index];
          return _buildPackageCard(package);
        },
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
    
    // Get service names from serviceDetails, customServices, or fallback to IDs
    List<String> serviceNames = [];
    
    // First, add custom services (these are always service names)
    if (package.customServices != null && package.customServices!.isNotEmpty) {
      serviceNames.addAll(package.customServices!);
    }
    
    // Then, add service names from populated service objects
    if (package.serviceDetails != null && package.serviceDetails!.isNotEmpty) {
      final serviceDetailNames = package.serviceDetails!
          .map((s) => s['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty && !name.startsWith('Service '))
          .toList();
      serviceNames.addAll(serviceDetailNames);
    } else if (package.servicesIncluded != null && package.customServices == null) {
      // If no custom services and no service details, show IDs as fallback
      debugPrint('Package: ${package.packageName} - No serviceDetails or customServices, servicesIncluded: ${package.servicesIncluded}');
      serviceNames.addAll(package.servicesIncluded!.map((id) => 'Service $id').toList());
    }
    
    // Remove duplicates while preserving order
    serviceNames = serviceNames.toSet().toList();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPackageActivity(packageData: package),
              ),
            ).then((_) => getPackages());
          },
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Title, Status, Best Seller
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      package.packageName ?? "Unknown Package",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  if (isBestSeller) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star, size: 12, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                            "BEST",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                package.packageDescription ?? "No description",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Status Badge - Minimal
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isActive 
                                ? const Color(0xFF10B981).withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive 
                                      ? const Color(0xFF10B981)
                                      : Colors.grey[600],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isActive ? "Active" : "Inactive",
                                style: TextStyle(
                                  color: isActive 
                                      ? const Color(0xFF10B981)
                                      : Colors.grey[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Pricing Row - Compact
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactPrice(
                            icon: Icons.directions_car_rounded,
                            price: smallPrice,
                            color: primaryColor,
                          ),
                        ),
                        Container(width: 1, height: 30, color: Colors.grey[200]),
                        Expanded(
                          child: _buildCompactPrice(
                            icon: Icons.directions_car_filled,
                            price: largePrice,
                            color: primaryColor,
                            iconSize: 20, // Slightly larger for SUV
                          ),
                        ),
                        Container(width: 1, height: 30, color: Colors.grey[200]),
                        Expanded(
                          child: _buildCompactInfo(
                            icon: Icons.access_time_rounded,
                            text: "${duration.toStringAsFixed(0)}h",
                          ),
                        ),
                        Container(width: 1, height: 30, color: Colors.grey[200]),
                        Expanded(
                          child: _buildCompactInfo(
                            icon: Icons.build_rounded,
                            text: "$servicesCount",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Service Tags - Chip Style (like Quick Add Common Services)
                    if (serviceNames.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: serviceNames.map((serviceName) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              serviceName.length > 25 ? '${serviceName.substring(0, 25)}...' : serviceName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Package Tier
                    if (package.packageTier != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.category, size: 14, color: Colors.grey[700]),
                            const SizedBox(width: 6),
                            Text(
                              package.packageTier!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Action Buttons - Compact
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditPackageActivity(packageData: package),
                                ),
                              ).then((_) => getPackages());
                            },
                            label: "Edit",
                            icon: Icons.edit_rounded,
                            color: primaryColor,
                            isPrimary: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCompactButton(
                            onPressed: () => _showDeleteDialog(package),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPrice({
    required IconData icon,
    required double price,
    required Color color,
    double iconSize = 18,
  }) {
    return Column(
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(height: 4),
        Text(
          "\$${price.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInfo({
    required IconData icon,
    required String text,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color color,
    required bool isPrimary,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isPrimary ? color : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: isPrimary ? null : Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isPrimary ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _showDeleteDialog(PackageData package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Package"),
        content: Text("Are you sure you want to delete '${package.packageName}'?"),
        actions: [
          TextButton(
            onPressed: () => CommonWidget.safePop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              CommonWidget.safePop(context);
              deletePackage(package.sId!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
