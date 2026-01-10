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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title, Category, Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Image (Compact)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: data.coverImage != null && data.coverImage!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            data.coverImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.local_car_wash,
                                color: ColorClass.base_color,
                                size: 30,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.local_car_wash,
                          color: ColorClass.base_color,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 12),
                // Title and Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data.serviceTitle ?? "Untitled Service",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  "Active",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Category
                      if (data.categoryName != null && data.categoryName!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ColorClass.base_color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            data.categoryName!,
                            style: TextStyle(
                              color: ColorClass.base_color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Description (if available)
            if (data.about != null && data.about!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  data.about!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            
            // Key Info Row: Price, Duration, Capacity
            Row(
              children: [
                // Price
                Expanded(
                  child: _buildInfoItem(
                    Icons.attach_money,
                    data.price != null && data.price! > 0 
                        ? "\$${data.price}" 
                        : "Free",
                    Colors.green,
                  ),
                ),
                // Duration
                Expanded(
                  child: _buildInfoItem(
                    Icons.schedule,
                    data.serviceDuration ?? "N/A",
                    Colors.blue,
                  ),
                ),
                // Capacity
                Expanded(
                  child: _buildInfoItem(
                    Icons.people,
                    "${data.timeSlotCapacity ?? "0"}/hr",
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Location (Compact)
            if (data.location?.name != null && (data.location!.name?.isNotEmpty ?? false))
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data.location!.name ?? "",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildMinimalActionButton(
                    Icons.edit_outlined,
                    "Edit",
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
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMinimalActionButton(
                    Icons.visibility_outlined,
                    "View",
                    Colors.blue[600]!,
                    () {
                      CommonWidget.navigateToScreen(
                        context,
                        SpecialistsActivity(data.sId.toString()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMinimalActionButton(IconData icon, String text, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: Icon(
        Icons.local_car_wash,
        color: ColorClass.base_color,
        size: 30,
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