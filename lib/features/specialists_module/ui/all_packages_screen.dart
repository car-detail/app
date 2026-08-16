import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/design_system/components/car_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data_manager/specialists_data_manager.dart';
import '../utils/package_mapper.dart';
import '../../booking_model/ui/booking_activity.dart';
import '../../home_module/model/services_model_data.dart';

class AllPackagesScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final List<Map<String, dynamic>> initialPackages;

  const AllPackagesScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
    this.initialPackages = const [],
  });

  @override
  _AllPackagesScreenState createState() => _AllPackagesScreenState();
}

class _AllPackagesScreenState extends State<AllPackagesScreen> {
  List<Map<String, dynamic>> packages = [];
  bool isLoading = true;
  String? errorMessage;
  SpecialistsDataManager? _dataManager;
  SharedPreferences? _sharedPreferences;

  @override
  void initState() {
    super.initState();
    packages = List<Map<String, dynamic>>.from(widget.initialPackages);
    if (packages.isNotEmpty) {
      isLoading = false;
    }
    _initialize();
  }

  Future<void> _initialize() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    _dataManager = SpecialistsDataManager(_sharedPreferences!);
    await _loadPackages(showLoader: packages.isEmpty);
  }

  Future<void> _loadPackages({bool showLoader = true}) async {
    if (_dataManager == null) {
      return;
    }

    if (widget.vendorId.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = "Vendor information is missing.";
      });
      return;
    }

    try {
      if (showLoader) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }

      final response = await _dataManager!.getVendorPackages(context, widget.vendorId);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == "success") {
          final mappedPackages = mapPackagesForDisplay(jsonData['data']);
          setState(() {
            packages = mappedPackages;
            isLoading = false;
            errorMessage = null;
          });
        } else {
          setState(() {
            packages = [];
            isLoading = false;
            errorMessage = jsonData['message']?.toString() ?? "Failed to load packages";
          });
        }
      } else {
        setState(() {
          packages = [];
          isLoading = false;
          errorMessage = "Server responded with ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        packages = [];
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: ColorClass.base_color,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: ColorClass.base_color,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
          child: CommonWidget.buildBackButton(
            context,
            backgroundColor: Colors.white.withOpacity(0.9),
            iconColor: Colors.black87,
          ),
        ),
        title: Text(
          "Packages - ${widget.vendorName}",
          style: const TextStyle(
            color: Colors.white,
            fontFamily: "Pop600",
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingState()
          : packages.isEmpty
              ? (errorMessage != null ? _buildErrorState() : _buildEmptyState())
              : _buildPackagesList(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: CarLoader(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            "No Packages Available",
            style: TextStyle(
              fontSize: 24,
              fontFamily: "Pop600",
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Packages will appear here when available",
            style: TextStyle(
              fontSize: 16,
              fontFamily: "Pop400",
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? "Failed to load packages",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Pop500",
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadPackages(),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorClass.base_color,
                foregroundColor: Colors.white,
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackagesList() {
    return RefreshIndicator(
      onRefresh: () => _loadPackages(showLoader: false),
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

  Widget _buildPackageCard(Map<String, dynamic> package) {
    final imageUrl = package['image'] ?? package['coverImage'];
    final title = package['title'] ?? package['packageName'] ?? package['name'] ?? 'Service Package';
    final description = package['description'] ?? '';
    final duration = package['duration'] ?? package['packageDuration'] ?? 'Duration TBD';
    final price = package['price'];
    final features = (package['features'] as List<dynamic>?)
            ?.map((feature) => feature.toString())
            .toList() ??
        (package['services'] as List<dynamic>?)
            ?.map((service) => service.toString())
            .toList() ??
        [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[200],
              child: (imageUrl != null && imageUrl.toString().isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.inventory_2,
                          size: 64,
                          color: ColorClass.base_color,
                        );
                      },
                    )
                  : Icon(
                      Icons.inventory_2,
                      size: 64,
                      color: ColorClass.base_color,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: "Pop600",
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: "Pop400",
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: "Pop400",
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      price != null ? "\$$price" : "Price TBD",
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: "Pop600",
                        color: ColorClass.base_color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: features.map((service) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorClass.base_light_color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: "Pop400",
                          color: ColorClass.base_color,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _bookPackage(package);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorClass.base_color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Book Package",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "Pop500",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _bookPackage(Map<String, dynamic> package) {
    // Navigate directly to booking page with vendor ID
    // Create a ServicesData object with the vendor ID
    if (widget.vendorId.isNotEmpty) {
      // For vendor app, we need to pass a ServicesData object
      // Since we only have vendorId, we'll create a minimal ServicesData
      ServicesData serviceData = ServicesData(
        sId: widget.vendorId,
        serviceTitle: package['title']?.toString() ?? 'Package Booking',
        price: package['price'] != null ? int.tryParse(package['price'].toString()) : null,
        serviceDuration: package['duration']?.toString(),
      );
      CommonWidget.navigateToScreen(
        context,
        BookingActivity(serviceData),
      );
    } else {
      CommonWidget.errorShowSnackBarFor(context, "Vendor information is missing. Cannot proceed with booking.");
    }
  }
}
