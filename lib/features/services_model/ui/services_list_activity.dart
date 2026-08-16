import 'dart:convert';

import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/ShimmerLoader.dart';
import 'package:car_app/Common/ContainerDecoration.dart';
import 'package:car_app/features/services_model/ui/modern_add_service_activity.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Color.dart';
import '../../../Common/Constant.dart';
import '../../../Common/ModernDesignSystem.dart';
import '../../resister_vendor_model/ui/registor_vendor_activity_simple.dart';
import '../../specialists_module/ui/specialists_activity.dart';
import '../data_manager/services_data_manager.dart';
import '../model/services_list_bean.dart';
import '../../home_module/model/category_model_data.dart';

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
  List<CategoryData> allCategories = [];
  bool allCategoriesHaveServices = false;
  bool isLoading = true;
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
    if (venderId != "") {
      await getCategory(context);
      await _fetchAllCategories();
      _checkIfAllCategoriesHaveServices();
    }
    if (mounted) setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF0FDF4),
        bottomNavigationBar: null,
        body: Column(
          children: [
            // Enhanced Fancy Header with Back Button
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: ModernDesignSystem.brandGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorClass.base_color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Back Button with uniform design
                      CommonWidget.buildBackButton(
                        context,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        iconColor: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "My Services",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${servicesData.length} services available",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Settings/Design icon
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.design_services_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Refresh button with animation
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                if (mounted && context.mounted) {
                                  await getCategory(context);
                                  await _fetchAllCategories();
                                  _checkIfAllCategoriesHaveServices();
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (venderId != "")
              Expanded(
                child: isLoading
                    ? ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: 6,
                        itemBuilder: (_, __) => ShimmerLoader.buildServiceCardShimmer(),
                      )
                    : servicesData.isNotEmpty
                    ? RefreshIndicator(
                        onRefresh: () async {
                          if (mounted && context.mounted) {
                            await getCategory(context);
                            await _fetchAllCategories();
                            _checkIfAllCategoriesHaveServices();
                          }
                        },
                        child: ListView.builder(
                            itemCount: servicesData.length,
                            padding: const EdgeInsets.all(12),
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
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: ColorClass.base_color.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              if (mounted && context.mounted) {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (context) => const ModernAddServiceActivity(),
                  ),
                )
                    .then((onValue) async {
                  if (mounted && context.mounted && onValue == true && venderId != "") {
                    await getCategory(context);
                    await _fetchAllCategories();
                    _checkIfAllCategoriesHaveServices();
                  }
                });
              }
            },
            backgroundColor: ColorClass.base_color,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            label: const Text(
              "Add Service",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildServiceCard(ServicesListData data, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: ModernDesignSystem.shadowLarge,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          color: Colors.white,
          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Big banner image, not a small icon -- this is the
                    // vendor's actual service photo, it needs to read clearly.
                    SizedBox(
                      width: double.infinity,
                      height: 170,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  ModernDesignSystem.accentFor(1),
                                  ModernDesignSystem.accentFor(1).withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: _buildServiceIconWithFallback(data),
                          ),
                          // dark gradient so the status badge stays readable
                          // over any photo
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.45),
                                ],
                              ),
                            ),
                          ),
                          // Status Badge
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: data.isPaused == true
                                      ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                                      : [ModernDesignSystem.accentFor(1), ModernDesignSystem.accentFor(1).withOpacity(0.7)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    data.isPaused == true ? "Paused" : "Active",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: "Pop600",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Title + category badge, over the image like the
                          // rest of the app's photo cards
                          Positioned(
                            left: 14,
                            right: 14,
                            bottom: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.categoryName ?? data.serviceTitle ?? "Untitled Service",
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    fontFamily: "Pop600",
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (data.categoryName != null && data.categoryName!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.white.withOpacity(0.35)),
                                    ),
                                    child: Text(
                                      data.categoryName!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: "Pop600",
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                    // Key Info Cards: Price, Duration, Capacity
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Price Card
                          if (data.price != null && data.price! > 0) ...[
                            Expanded(
                              child: _buildFancyInfoCard(
                                Icons.attach_money_rounded,
                                "\$${data.price}",
                                "Price",
                                const Color(0xFF192028),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey[200],
                            ),
                          ],
                          // Duration Card
                          Expanded(
                            child: _buildFancyInfoCard(
                              Icons.schedule_rounded,
                              data.serviceDuration ?? "N/A",
                              "Duration",
                              Colors.blue,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey[200],
                          ),
                          // Capacity Card
                          Expanded(
                            child: _buildFancyInfoCard(
                              Icons.people_rounded,
                              data.timeSlotCapacity ?? "N/A",
                              "Capacity",
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Location (if available)
                    if (data.location?.name != null && (data.location!.name?.isNotEmpty ?? false))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                data.location!.name ?? "",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.w600,
                                  fontFamily: "Pop600",
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (data.location?.name != null && (data.location!.name?.isNotEmpty ?? false))
                      const SizedBox(height: 8),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildFancyActionButton(
                            Icons.edit_rounded,
                            "Edit",
                            ColorClass.base_color,
                            () {
                              if (mounted && context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ModernAddServiceActivity(serviceToEdit: data),
                                  ),
                                ).then((onValue) async {
                                  if (mounted && context.mounted && onValue == true && venderId != "") {
                                    await getCategory(context);
                                    await _fetchAllCategories();
                                    _checkIfAllCategoriesHaveServices();
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildFancyActionButton(
                            data.isPaused == true ? Icons.play_arrow_rounded : Icons.pause_rounded,
                            data.isPaused == true ? "Resume" : "Pause",
                            data.isPaused == true ? const Color(0xFF192028) : Colors.orange[700]!,
                            () async {
                              final newStatus = data.isPaused != true;
                              final response = await servicesDataManager!.pauseService(
                                context,
                                data.sId.toString(),
                                newStatus,
                              );
                              if (response.statusCode == 200) {
                                if (mounted) {
                                  setState(() {
                                    data.isPaused = newStatus;
                                  });
                                  CommonWidget.successShowSnackBarFor(
                                    context,
                                    newStatus ? "Service paused successfully!" : "Service resumed successfully!"
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildFancyActionButton(
                            Icons.visibility_rounded,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceIconWithFallback(ServicesListData data) {
    // Priority 1: Try service cover image
    String? coverImage = data.coverImage;
    if (coverImage != null && coverImage.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          coverImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Priority 2: Fallback to vendor image if service image fails
            return _buildVendorImageFallback(data);
          },
        ),
      );
    }
    // Priority 2: Try vendor image if no service image
    return _buildVendorImageFallback(data);
  }

  Widget _buildVendorImageFallback(ServicesListData data) {
    // Try vendor display picture
    String? vendorImage = data.vendorId?.displayPicture;
    if (vendorImage != null && vendorImage.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          vendorImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Priority 3: Fallback to generic car icon
            return _buildGenericCarIcon();
          },
        ),
      );
    }
    // Priority 3: Generic car icon if no images available
    return _buildGenericCarIcon();
  }

  Widget _buildGenericCarIcon() {
    return const Icon(
      Icons.local_car_wash,
      color: Colors.white,
      size: 40,
    );
  }

  Widget _buildFancyInfoCard(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: "Pop600",
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontFamily: "Pop400",
          ),
        ),
      ],
    );
  }
  
  Widget _buildFancyActionButton(IconData icon, String text, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: "Pop600",
                ),
              ),
            ],
          ),
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
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B2A4A), Color(0xFF3F5A85)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.design_services,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Services Yet",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Start by adding your first service to attract customers and grow your business.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
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
                      context, const RegistorVendorActivitySimple());
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
    if (!mounted || !context.mounted) return;
    
    String vendorId = sharedPreferences!.getString(Constant.vendorId) ?? "";
    
    if (vendorId.isEmpty) {
      if (mounted && context.mounted) {
        _showVendorRegistrationDialog();
      }
      return;
    }
    
    try {
      var response = await servicesDataManager!.getServicesList(context);
      
      if (!mounted || !context.mounted) return;
      
      // Check if response is HTML (ngrok error page)
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        return;
      }
      
      // Check response status code
      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to load services. Please check your connection and try again.");
        }
        return;
      }
      
      try {
        var data = ServicesListBean.fromJson(jsonDecode(response.body));
        if (data.status == "success") {
          if (mounted) {
            setState(() {
              servicesData.clear();
              servicesData.addAll(data.data ?? []);
            });
          }
          // Check if all categories have services after loading
          _checkIfAllCategoriesHaveServices();
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to load services. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error parsing services list. Please try again.");
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error loading services. Please check your connection and try again.");
      }
    }
  }

  Future<void> _fetchAllCategories() async {
    if (servicesDataManager == null) return;
    
    try {
      var response = await servicesDataManager!.getcategory(context);
      var data = CategoryModelData.fromJson(jsonDecode(response.body));
      if (data.status == "success" && data.data != null) {
        if (mounted) {
          setState(() {
            allCategories = data.data!;
          });
        }
      }
    } catch (e) {
      // Don't show error, just continue
    }
  }

  void _checkIfAllCategoriesHaveServices() {
    if (allCategories.isEmpty || servicesData.isEmpty) {
      setState(() {
        allCategoriesHaveServices = false;
      });
      return;
    }

    // Get set of category IDs that have services
    Set<String> categoriesWithServices = {};
    for (var service in servicesData) {
      if (service.categoryId != null && service.categoryId!.isNotEmpty) {
        categoriesWithServices.add(service.categoryId!);
      }
      // Also check by category name as fallback
      if (service.categoryName != null && service.categoryName!.isNotEmpty) {
        var matchingCategory = allCategories.firstWhere(
          (cat) => cat.categoryTitle == service.categoryName,
          orElse: () => CategoryData(sId: "", categoryTitle: ""),
        );
        if (matchingCategory.sId != null && matchingCategory.sId!.isNotEmpty) {
          categoriesWithServices.add(matchingCategory.sId!);
        }
      }
    }

    // Check if all categories have services
    bool allHaveServices = allCategories.every((category) {
      if (category.sId == null || category.sId!.isEmpty) return false;
      return categoriesWithServices.contains(category.sId);
    });

    if (mounted) {
      setState(() {
        allCategoriesHaveServices = allHaveServices;
      });
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
                if (mounted && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (mounted && context.mounted) {
                  Navigator.of(context).pop();
                  CommonWidget.navigateToScreen(
                    context,
                    const RegistorVendorActivitySimple(),
                  );
                }
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

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1526),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                onTap: () {
                  Navigator.of(context).popUntil((route) {
                    return route.isFirst || route.settings.name == '/dashboard';
                  });
                },
                isSelected: false,
              ),
              // Centre pill gradient add button
              if (venderId != "" && !allCategoriesHaveServices)
                GestureDetector(
                  onTap: () {
                    if (mounted && context.mounted) {
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          builder: (context) => const ModernAddServiceActivity(),
                        ),
                      )
                          .then((onValue) async {
                        if (mounted && context.mounted && onValue == true && venderId != "") {
                          await getCategory(context);
                          await _fetchAllCategories();
                          _checkIfAllCategoriesHaveServices();
                        }
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B2A4A), Color(0xFF3F5A85)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B2A4A).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text(
                          "Add Service",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: "Pop600",
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(width: 8),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                onTap: () {
                  Navigator.of(context).popUntil((route) {
                    return route.isFirst || route.settings.name == '/dashboard';
                  });
                },
                isSelected: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3F5A85) : Colors.white60,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF3F5A85) : Colors.white60,
                fontFamily: isSelected ? "Pop600" : "Pop400",
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}