import 'dart:convert';

import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/ShimmerLoader.dart';
import 'package:car_app/Common/ContainerDecoration.dart';
import 'package:car_app/features/services_model/ui/add_services_activity.dart';
import 'package:car_app/features/services_model/ui/modern_add_service_activity.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Color.dart';
import '../../../Common/Constant.dart';
import '../../resister_vendor_model/ui/registor_vendor_activity.dart';
import '../../specialists_module/ui/specialists_activity.dart';
import '../data_manager/services_data_manager.dart';
import '../model/services_list_bean.dart';

class ServicesListActivity extends StatefulWidget {
  const ServicesListActivity({super.key});

  @override
  State<ServicesListActivity> createState() => _ServicesListActivityState();
}

class _ServicesListActivityState extends State<ServicesListActivity> {
  ApiFuntions apiFuntions = ApiFuntions();
  ServicesDataManager? servicesDataManager;
  SharedPreferences? sharedPreferences;
  List<ServicesListData> servicesData = [];
  var venderId = "";

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    servicesDataManager = ServicesDataManager(sharedPreferences!);
    setState(() {
      venderId = sharedPreferences!.getString(Constant.vendorId) ?? "";
    });
    if (venderId != "") getCategory(context);
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
                          "My Services",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${servicesData.length} services available",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.design_services,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          print("🔄 Manual refresh triggered");
                          getCategory(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (venderId != "")
              Expanded(
                child: servicesData.isNotEmpty
                    ? RefreshIndicator(
                        onRefresh: () async {
                          getCategory(context);
                        },
                        child: ListView.builder(
                            itemCount: servicesData.length,
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              var data = servicesData[index];
                              return _buildServiceCard(data, index);
                            }),
                      )
                    : _buildEmptyState(),
              )
            else
              _buildNoVendorState()
          ],
        ),
        floatingActionButton: venderId != ""
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(
                      builder: (context) => const ModernAddServiceActivity(),
                    ),
                  )
                      .then((onValue) {
                    if (onValue == true && venderId != "") getCategory(context);
                  });
                },
                backgroundColor: ColorClass.base_color,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Add Service",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              )
            : null);
  }

  Widget _buildServiceCard(ServicesListData data, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 25,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced Service Image with Gradient Overlay
          Container(
            height: 220,
            child: Stack(
              children: [
                // Main Image
                Container(
                  height: 220,
                  width: double.infinity,
                  child: data.coverImage != null && data.coverImage!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          child: Image.network(
                            data.coverImage!,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                          ),
                        )
                      : _buildImagePlaceholder(),
                ),
                // Gradient Overlay
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Active",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Price Badge
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: data.price != null && data.price! > 0 
                          ? ColorClass.base_color 
                          : Colors.grey[600],
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: (data.price != null && data.price! > 0 
                              ? ColorClass.base_color 
                              : Colors.grey[600]!).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      data.price != null && data.price! > 0 
                          ? "₹${data.price}" 
                          : "N/A",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Category Badge
                if (data.categoryName != null && data.categoryName!.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data.categoryName!,
                        style: TextStyle(
                          color: ColorClass.base_color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Enhanced Service Details
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Title
                Text(
                  data.serviceTitle ?? "",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Service Description
                if (data.about != null && data.about!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      data.about!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 20),
                
                // Enhanced Service Stats
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildEnhancedStatChip(
                      Icons.schedule_outlined,
                      data.serviceDuration ?? "0 hours",
                      "Duration",
                      Colors.blue,
                    ),
                    _buildEnhancedStatChip(
                      Icons.people_outline,
                      "${data.timeSlotCapacity ?? "0"}",
                      "Capacity",
                      Colors.green,
                    ),
                    if (data.averageRating != null && data.averageRating! > 0)
                      _buildEnhancedStatChip(
                        Icons.star_outline,
                        "${data.averageRating!.toStringAsFixed(1)}",
                        "Rating (${data.totalReviews ?? 0})",
                        Colors.orange,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Location Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue[100]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Service Location",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.location?.name ?? "Location not available",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Enhanced Action Buttons
               Container(
  margin: const EdgeInsets.only(top: 16), // top margin for Row
  child:  Row(
                  children: [
                    Expanded(
                      child: _buildEnhancedActionButton(
                        Icons.edit_outlined,
                        "Edit Service",
                        ColorClass.base_color,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ModernAddServiceActivity(serviceToEdit: data),
                            ),
                          ).then((onValue) {
                            if (onValue == true && venderId != "") getCategory(context);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: _buildEnhancedActionButton(
                        Icons.visibility_outlined,
                        "View Details",
                        Colors.blue[600]!,
                        () {
                          CommonWidget.navigateToScreen(context,
                              SpecialistsActivity(data.sId.toString()));
                        },
                      ),
                    ),
                  ],
                ),),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
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
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ColorClass.base_color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ColorClass.base_color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: ColorClass.base_color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorClass.base_color.withOpacity(0.15),
            ColorClass.base_color.withOpacity(0.08),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorClass.base_color.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.local_car_wash,
              size: 48,
              color: ColorClass.base_color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Service Image",
            style: TextStyle(
              color: ColorClass.base_color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Add an image to showcase your service",
            style: TextStyle(
              color: ColorClass.base_color.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorClass.base_color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.design_services,
                size: 64,
                color: ColorClass.base_color,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Services Yet",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Start by adding your first service to attract customers and grow your business.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (venderId.isEmpty) ...[
              ElevatedButton.icon(
                onPressed: () {
                  _showVendorRegistrationDialog();
                },
                icon: const Icon(Icons.business),
                label: const Text("Complete Vendor Registration"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorClass.base_color,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "You need to complete vendor registration first",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(
                      builder: (context) => const ModernAddServiceActivity(),
                    ),
                  )
                      .then((onValue) {
                    if (onValue == true && venderId != "") getCategory(context);
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("Add Your First Service"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorClass.base_color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoVendorState() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.store,
                  size: 64,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Setup Required",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You need to add your shop details first before managing services.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  CommonWidget.navigateToScreen(
                      context, const RegistorVendorActivity());
                },
                icon: const Icon(Icons.add_business),
                label: const Text("Add Shop"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorClass.base_color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  getCategory(BuildContext context) async {
    print("🔄 Refreshing services list...");
    String vendorId = sharedPreferences!.getString(Constant.vendorId) ?? "";
    print("🔍 Vendor ID: $vendorId");
    print("🔍 API URL: ${Constant.baseurl}${Constant.getServicesList}$vendorId");
    
    if (vendorId.isEmpty) {
      print("❌ No vendor ID found - user needs to complete vendor registration");
      _showVendorRegistrationDialog();
      return;
    }
    
    var response = await servicesDataManager!.getServicesList(context);
    print("📋 Services list response status: ${response.statusCode}");
    print("📋 Response body: ${response.body}");
    
    // Check if response is HTML (ngrok error page)
    if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
      print("❌ Received HTML instead of JSON - ngrok error page");
      CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
      return;
    }
    
    try {
      var data = ServicesListBean.fromJson(jsonDecode(response.body));
      if (data.status == "success") {
        setState(() {
          servicesData.clear();
          servicesData.addAll(data.data!);
        });
        print("✅ Services list refreshed successfully. Count: ${servicesData.length}");
        //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      } else {
        print("❌ Failed to refresh services list: ${data.message}");
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      }
    } catch (e) {
      print("❌ Error parsing services list JSON: $e");
      CommonWidget.errorShowSnackBarFor(context, "Error parsing services list. Please try again.");
    }
  }

  void _showVendorRegistrationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.business, color: ColorClass.base_color),
              const SizedBox(width: 8),
              const Text("Vendor Registration Required"),
            ],
          ),
          content: const Text(
            "To manage services, you need to complete your vendor registration first. This will set up your business profile and allow you to add services.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                CommonWidget.navigateToScreen(
                  context,
                  const RegistorVendorActivity(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorClass.base_color,
              ),
              child: const Text(
                "Complete Registration",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  getRowDetails(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CommonWidget.getTextWidget500(title, size: 14),
          CommonWidget.getTextWidget400(value, 14)
        ],
      ),
    );
  }

  // Enhanced Stat Chip with better styling
  Widget _buildEnhancedStatChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced Action Button with better styling
  Widget _buildEnhancedActionButton(IconData icon, String text, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}