import 'dart:convert';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/features/packages_model/data_manager/package_data_manager.dart';
import 'package:car_app/features/packages_model/model/package_model_data.dart';
import 'package:car_app/features/packages_model/ui/add_package_activity.dart';
import 'package:car_app/features/packages_model/ui/edit_package_activity.dart';
import 'package:flutter/material.dart';
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPackageActivity(),
                        ),
                      ).then((_) => getPackages());
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
        padding: const EdgeInsets.all(16),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final package = packages[index];
          return _buildPackageCard(package);
        },
      ),
    );
  }

  Widget _buildPackageCard(PackageData package) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.packageName ?? "Unknown Package",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package.packageDescription ?? "No description",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: package.isActive == true ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    package.isActive == true ? "Active" : "Inactive",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (package.smallVehiclePrice != null && package.largeVehiclePrice != null) ...[
                  _buildInfoChip(
                    Icons.directions_car,
                    "Small: \$${package.smallVehiclePrice}",
                    Colors.green,
                  ),
                  _buildInfoChip(
                    Icons.local_shipping,
                    "Large: \$${package.largeVehiclePrice}",
                    Colors.blue,
                  ),
                ] else
                  _buildInfoChip(
                    Icons.attach_money,
                    "\$${package.packagePrice ?? "0"}",
                    Colors.green,
                  ),
                _buildInfoChip(
                  Icons.schedule,
                  "${package.packageDuration ?? "0"} hours",
                  Colors.blue,
                ),
                _buildInfoChip(
                  Icons.design_services,
                  "${package.servicesIncluded?.length ?? 0} services",
                  Colors.orange,
                ),
                if (package.packageTier != null)
                  _buildInfoChip(
                    Icons.category,
                    package.packageTier!,
                    Colors.purple,
                  ),
                if (package.isBestSeller == true)
                  _buildInfoChip(
                    Icons.star,
                    "BEST SELLER",
                    Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPackageActivity(packageData: package),
                        ),
                      ).then((_) => getPackages());
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("Edit"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorClass.base_color,
                      side: BorderSide(color: ColorClass.base_color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showDeleteDialog(package);
                    },
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
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
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
