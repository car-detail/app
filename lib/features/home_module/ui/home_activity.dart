import 'dart:convert';
// import 'dart:ffi'; // Not available on web platform

import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonBean.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/Common/ModernDesignSystem.dart';
import 'package:car_app/features/categories_module/ui/categories_list_activity.dart';
import 'package:car_app/features/home_module/data_manager/home_data_manager.dart';
import 'package:car_app/features/offer_model/ui/enhanced_offer_list_screen.dart';
import 'package:car_app/features/specialists_module/ui/specialists_activity.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../Common/CommonPopUp.dart';
import '../../../Common/ContainerDecoration.dart';
import '../../../Common/PromoCarousel.dart';
import '../../booking_model/data_model/booking_list_bean.dart';
import '../../booking_model/model/complete_model_bean.dart';
import '../../dashboard_module/model/vendor_details_main_bean.dart';
import '../../offer_model/model/offer_list_model_bean.dart';
import '../model/category_model_data.dart';
import '../model/notification_data_bean.dart';
import '../model/services_model_data.dart';
import '../../services_model/ui/simple_add_services_activity.dart';
import '../../services_model/ui/services_list_activity.dart';
import '../../booking_model/ui/booking_list_activity.dart';
import '../../offer_model/ui/enhanced_offer_screen.dart';
import '../../packages_model/ui/add_package_activity.dart';
import '../../packages_model/ui/package_list_activity.dart';
import '../../packages_model/ui/ultra_simple_add_package.dart';
import '../../resister_vendor_model/ui/simple_registor_vendor_activity.dart';
import '../../notification_model/ui/notification_activity.dart';
import '../../services_model/ui/ultra_simple_add_service.dart';
import 'location_picker_screen.dart';

class HomeActivity extends StatefulWidget {
  Function(bool value) offline;
  HomeActivity(this.offline, {super.key});

  @override
  State<HomeActivity> createState() => _HomeActivityState();
}

class _HomeActivityState extends State<HomeActivity> {
  List<CategoryData> categoryData = [];
  List<ServicesData> servicesData = [];
  HomeDataManager? dataManager;
  SharedPreferences? sharedPreferences;
  List<String> offerList = ["car_image.png", "car_image.png"];
  List<Records> records = [];
  TextEditingController reasone = TextEditingController();
  List<OfferListModelData> offerListData = [];
  List<Notifications> notificationsList = [];
  var vendorId = "";
  bool isShopOpen = true; // Store status toggle state

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = HomeDataManager(sharedPreferences!);
    
    final vendorIdValue = sharedPreferences!.getString(Constant.vendorId) ?? "";
    setState(() {
      vendorId = vendorIdValue;
    });
    
    print("🔍 Home - Checking vendorId: '$vendorIdValue'");
    print("🔍 Home - User ID: ${sharedPreferences!.getString(Constant.id) ?? ""}");

    if (vendorIdValue.isNotEmpty) {
      print("✅ VendorId found, loading vendor data");
      getdetails(context);
      getServices(context); // Load services data for Business Overview
    } else {
      print("❌ No vendorId found - vendor needs to complete registration");
      // Don't make API calls if there's no vendorId
    }
  }

  getdetails(BuildContext context) async {
    try {
      var response = await dataManager!.getdetails(context);
      print("🔍 Home getdetails response: ${response.statusCode} - ${response.body}");
      
      if (response.statusCode == 404) {
        print("❌ Vendor not found - vendorId might be missing");
        // Don't show error snackbar here as it might be expected for new vendors
        return;
      }
      
      var data = VendorDetailsMainBean.fromJson(jsonDecode(response.body));
      if (data.status == "success") {
        setState(() {
          isShopOpen = data.data!.isShopOpen!;
        });
        if(data.data!.isShopOpen! == true) {
          getBookingListFilter(context);
          getoffer(context);
          getNotifications(context);
        }
        print("✅ Home vendor details loaded successfully");
      } else {
        print("❌ Home API returned error: ${data.message}");
        // Don't show error snackbar here as it might be expected for new vendors
      }
    } catch (e) {
      print("❌ Error in Home getdetails: $e");
      // Don't show error snackbar here as it might be expected for new vendors
    }
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        CommonWidget.safePop(context);
        CommonWidget.errorShowSnackBarFor(
            context, 'Location services are disabled. Please enable them.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          CommonWidget.safePop(context);
          CommonWidget.errorShowSnackBarFor(
              context, 'Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        CommonWidget.safePop(context);
        CommonWidget.errorShowSnackBarFor(
            context, 'Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      
      String address = placemarks[0].locality ?? 
                      placemarks[0].subAdministrativeArea ?? 
                      placemarks[0].administrativeArea ?? 
                      "Current Location";
      
      sharedPreferences!.setString(Constant.location, address);
      sharedPreferences!.setString(Constant.lat, position.latitude.toString());
      sharedPreferences!.setString(Constant.long, position.longitude.toString());

      if (context.mounted) {
        CommonWidget.safePop(context);
        CommonWidget.successShowSnackBarFor(
            context, 'Location updated successfully!');
      }
      
      // Refresh the page to show updated location
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (context.mounted) {
        CommonWidget.safePop(context);
      }
      CommonWidget.errorShowSnackBarFor(
          context, 'Error getting location: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with store status and notifications
          Container(
            padding: const EdgeInsets.only(top: 45, bottom: 15),
            decoration: BoxDecoration(
            color: ColorClass.base_color,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPickerScreen(
                          currentLocation: sharedPreferences?.getString(Constant.location),
                        ),
                      ),
                    );
                    
                    if (result != null && mounted) {
                      setState(() {
                        // Location updated, refresh the screen
                      });
                    }
                  },
                  child: Container(
                      margin: const EdgeInsets.only(left: 15),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                ),
                ),
                Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationPickerScreen(
                                currentLocation: sharedPreferences?.getString(Constant.location),
                              ),
                            ),
                          );
                          
                          if (result != null && mounted) {
                            setState(() {
                              // Location updated, refresh the screen
                            });
                          }
                        },
                        child: CommonWidget.getTextWidget500(
                          sharedPreferences?.getString(Constant.location) ?? "Location not set",
                            color: Colors.white,
                        ),
                      ),
                    ),
                GestureDetector(
                  onTap: () {
                    CommonWidget.navigateToScreen(
                        context, NotificationActivity(notificationsList));
                  },
                  child: Container(
                        margin: const EdgeInsets.only(right: 15),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                        color: Colors.white,
                              size: 24,
                            ),
                            if (notificationsList.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${notificationsList.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
              ],
            ),
          ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Store status card
                  if (vendorId != "")
                    Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                          offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.store,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              const Text(
                                "Shop Status",
                                  style: TextStyle(
                                    fontFamily: "PopSemi",
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              const SizedBox(height: 4),
                                Text(
                                isShopOpen 
                                  ? "Your shop is currently online and accepting bookings"
                                  : "Your shop is currently offline and not accepting bookings",
                                  style: TextStyle(
                                  fontFamily: "PopReg",
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            activeColor: ColorClass.base_color,
                            inactiveThumbColor: Colors.red,
                            inactiveTrackColor: Colors.red[100],
                            value: isShopOpen,
                            onChanged: (val) {
                              CommonPopUp.showalertDialog(
                                context,
                                "",
                                isShopOpen 
                                  ? "Are you sure you want to make the store offline?"
                                  : "Are you sure you want to make the store online?",
                                "No",
                                "Yes",
                                "", // No image to avoid asset loading error
                                    () => CommonWidget.safePop(context),
                                    () async {
                                  CommonWidget.safePop(context);
                                  makeOffLine(context);
                                },
                                190,
                                positivetitlecolorButton: ColorClass.red,
                                navtextColorButton: ColorClass.green,
                                isboldtitle: false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Pending Bookings Section (only show if there are pending bookings)
                  if (records.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Recent Bookings",
                                style: TextStyle(
                                  fontFamily: "PopSemi",
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  CommonWidget.navigateToScreen(
                                    context,
                                    const BookingListActivity(),
                                  );
                                },
                                child: Text(
                                  "View All",
                                  style: TextStyle(
                                    fontFamily: "PopSemi",
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: ColorClass.base_color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Show only the first 3 pending bookings
                          ...records.take(3).map((booking) => _buildPendingBookingCard(booking)).toList(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                  
                  // Business Metrics Cards
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Business Overview",
                          style: TextStyle(
                            fontFamily: "PopSemi",
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                "Bookings",
                                "${records.length}",
                                Icons.calendar_today_outlined,
                                const Color(0xFF3B82F6), // Blue
                                0,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCard(
                                "Services",
                                "${servicesData.length}",
                                Icons.build_outlined,
                                const Color(0xFFF59E0B), // Orange
                                1,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCard(
                                "Rating",
                                "4.8",
                                Icons.star_outline,
                                const Color(0xFFFBBF24), // Amber
                                2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Quick Actions
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        const Text(
                          "Quick Actions",
                          style: TextStyle(
                            fontFamily: "PopSemi",
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                              Row(
                                children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                "Services",
                                Icons.design_services_outlined,
                                const Color(0xFF10B981), // Green
                                () {
                                  CommonWidget.navigateToScreen(
                                    context, 
                                    const ServicesListActivity()
                                  );
                                },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                              child: _buildQuickActionCard(
                                "Packages",
                                Icons.inventory_2_outlined,
                                const Color(0xFF8B5CF6), // Purple
                                () {
                                  CommonWidget.navigateToScreen(
                                    context, 
                                    const PackageListActivity()
                                  );
                                },
                              ),
                                        ),
                                      ],
                                    ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                "Offers",
                                Icons.local_offer_outlined,
                                const Color(0xFFF59E0B), // Orange
                                () {
                                  CommonWidget.navigateToScreen(
                                    context, 
                                    const EnhancedOfferListScreen()
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildQuickActionCard(
                                "Manage Bookings",
                                Icons.calendar_today_outlined,
                                const Color(0xFF3B82F6), // Blue
                                () {
                                  CommonWidget.navigateToScreen(
                                    context, 
                                    const BookingListActivity()
                                  );
                                },
                              ),
                            ),
                                ],
                              ),
                              const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                              child: _buildQuickActionCard(
                                "View Analytics",
                                Icons.analytics_outlined,
                                const Color(0xFF6366F1), // Indigo
                                () {
                                  // TODO: Navigate to analytics screen
                                  CommonWidget.successShowSnackBarFor(
                                    context, 
                                    "Analytics feature coming soon!"
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                                    Expanded(
                              child: _buildQuickActionCard(
                                "Quick Add",
                                Icons.add_circle_outline,
                                const Color(0xFF14B8A6), // Teal
                                () {
                                  _showQuickAddOptions(context);
                                },
                              ),
                            ),
                          ],
                        ),
                            ],
                          ),
                        ),
                  
                  const SizedBox(height: 25),
                  
                  // Recent Bookings
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Recent Bookings",
                              style: TextStyle(
                                fontFamily: "PopSemi",
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                CommonWidget.navigateToScreen(
                                  context, 
                                  const BookingListActivity()
                                );
                              },
                              child: Text(
                                "View All",
                                style: TextStyle(
                                  fontFamily: "PopReg",
                                  fontSize: 14,
                                  color: ColorClass.base_color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        if (records.isEmpty)
                      Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                        child: Column(
                          children: [
                                Icon(
                                  Icons.book_online_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No bookings yet",
                                  style: TextStyle(
                                    fontFamily: "PopSemi",
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Your bookings will appear here",
                                  style: TextStyle(
                                    fontFamily: "PopReg",
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: records.length > 3 ? 3 : records.length,
                            itemBuilder: (context, index) {
                              return _buildBookingCard(records[index]);
                            },
                      ),
                    ],
                  ),
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Offers Section
                  if (offerListData.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Active Offers",
                                style: TextStyle(
                                  fontFamily: "PopSemi",
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  CommonWidget.navigateToScreen(
                                    context, 
                                    const EnhancedOfferListScreen()
                                  );
                                },
                                child: Text(
                                  "View All",
                                  style: TextStyle(
                                    fontFamily: "PopReg",
                                    fontSize: 14,
                                    color: ColorClass.base_color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              itemCount: offerListData.length,
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                return _buildOfferCard(offerListData[index]);
                              },
            ),
          ),
        ],
                      ),
                    ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build metric cards
  Widget _buildMetricCard(String title, String value, IconData icon, Color iconColor, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: "PopSemi",
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111827),
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: "PopSemi",
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build quick action cards
  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 22,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: "PopSemi",
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build booking cards
  Widget _buildBookingCard(Records booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: ModernDesignSystem.spacingM),
      padding: const EdgeInsets.all(ModernDesignSystem.spacingL),
      decoration: ModernDesignSystem.modernCard(
        borderRadius: ModernDesignSystem.radiusM,
        shadows: ModernDesignSystem.shadowMedium,
      ),
                child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${booking.createdByFirstName ?? ""} ${booking.createdByLastName ?? ""}",
                      style: const TextStyle(
                        fontFamily: "PopSemi",
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Slot: ${CommonWidget.convertToLocalTime(booking.timeSlot ?? "")}",
                      style: TextStyle(
                        fontFamily: "PopReg",
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      "Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(booking.date ?? ""))}",
                      style: TextStyle(
                        fontFamily: "PopReg",
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: ModernDesignSystem.spacingM, vertical: ModernDesignSystem.spacingXS),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.orderStatus ?? "").withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                ),
                child: Text(
                  booking.orderStatus ?? "",
                  style: TextStyle(
                    fontFamily: "PopSemi",
                    fontSize: 10,
                    color: _getStatusColor(booking.orderStatus ?? ""),
                  ),
                ),
              ),
            ],
          ),
          if (booking.orderStatus == "Pending") ...[
            const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                  child: InkWell(
                            onTap: () {
                      putStatusCompleted(context, booking);
                            },
                            child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                        color: ColorClass.base_color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                        "Complete",
                                style: TextStyle(
                          color: Colors.white,
                          fontFamily: "PopSemi",
                          fontSize: 12,
                                ),
                        textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                const SizedBox(width: 8),
                        Expanded(
                  child: InkWell(
                            onTap: () {
                      _showCancelDialog(context, booking);
                            },
                            child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                        color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                        "Cancel",
                                style: TextStyle(
                                  color: Colors.white,
                          fontFamily: "PopSemi",
                          fontSize: 12,
                                ),
                        textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to build offer cards
  Widget _buildOfferCard(OfferListModelData offer) {
    return Container(
        margin: const EdgeInsets.only(right: ModernDesignSystem.spacingM),
        width: 280,
        decoration: ModernDesignSystem.modernCard(
          borderRadius: ModernDesignSystem.radiusM,
          shadows: ModernDesignSystem.shadowMedium,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
          child: Stack(
            children: [
              Image.network(
                offer.image ?? "",
                height: 150,
                width: 280,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    width: 280,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 48,
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title ?? "",
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: "PopSemi",
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer.description ?? "",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: "PopReg",
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to build pending booking card
  Widget _buildPendingBookingCard(Records booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: ModernDesignSystem.spacingM),
      padding: const EdgeInsets.all(ModernDesignSystem.spacingL),
      decoration: ModernDesignSystem.modernCard(
        borderRadius: ModernDesignSystem.radiusM,
        shadows: ModernDesignSystem.shadowMedium,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // User avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // User name and booking details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${booking.createdByFirstName ?? ""} ${booking.createdByLastName ?? ""}".trim().isEmpty 
                          ? "Customer" 
                          : "${booking.createdByFirstName ?? ""} ${booking.createdByLastName ?? ""}".trim(),
                      style: const TextStyle(
                        fontFamily: "PopSemi",
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Slot: ${booking.timeSlot ?? "Invalid time range format"}",
                      style: TextStyle(
                        fontFamily: "PopReg",
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Date: ${booking.date ?? "N/A"}",
                      style: TextStyle(
                        fontFamily: "PopReg",
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: ModernDesignSystem.spacingM, vertical: ModernDesignSystem.spacingXS),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.orderStatus ?? "pending"),
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                ),
                child: Text(
                  booking.orderStatus ?? "Pending",
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: "PopSemi",
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    putStatusCompleted(context, booking);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(ModernDesignSystem.radiusS),
                    ),
                    child: const Text(
                      "Complete",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "PopSemi",
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    _showCancelDialog(context, booking);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(ModernDesignSystem.radiusS),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "PopSemi",
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // Helper method to show cancel dialog
  void _showCancelDialog(BuildContext context, Records booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Cancel Booking"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Please provide a reason for cancellation:"),
              const SizedBox(height: 12),
              TextField(
                controller: reasone,
                decoration: const InputDecoration(
                  hintText: "Enter reason...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => CommonWidget.safePop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                CommonWidget.safePop(context);
                putStatusCancel(context, reasone.text, booking.sId.toString());
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  getCategory(BuildContext context) async {
    var response = await dataManager!.getcategory(context);
    var data = CategoryModelData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        categoryData.clear();
        categoryData.addAll(data.data!);
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  getServices(BuildContext context) async {
    try {
      var response = await dataManager!.getVendorServices(context);
      print("🔍 Vendor Services API Response: ${response.statusCode} - ${response.body}");
      
      if (response.statusCode == 404) {
        print("❌ Vendor services not found - vendorId might be missing");
        return;
      }
      
      var data = ServicesModelData.fromJson(jsonDecode(response.body));
      print("🔍 Parsed Vendor Services Data: ${data.data?.length ?? 0} services");
      if (data.status == "success") {
        setState(() {
          servicesData.clear();
          servicesData.addAll(data.data!);
          print("🔍 Vendor Services Data Updated: ${servicesData.length} services in state");
        });
      } else {
        print("❌ Vendor Services API Error: ${data.message}");
        // Don't show error snackbar here as it might be expected for new vendors
      }
    } catch (e) {
      print("❌ Error in getServices: $e");
      // Don't show error snackbar here as it might be expected for new vendors
    }
  }

  getBookingListFilter(BuildContext context) async {
    try {
      var response = await dataManager!.getBookingListFilter(context, "Pending");
      print("🔍 Booking List API Response: ${response.statusCode} - ${response.body}");
      
      if (response.statusCode == 404) {
        print("❌ Booking list not found - vendorId might be missing");
        setState(() {
          records.clear();
        });
        return;
      }
      
      var data = BookingListBean.fromJson(jsonDecode(response.body));
      if (data.status == "success") {
        setState(() {
          records.clear();
          records.addAll(data.data!.records!);
        });
        print("✅ Booking list loaded successfully: ${records.length} bookings");
      } else {
        setState(() {
          records.clear();
        });
        print("❌ Booking list API error: ${data.message}");
        // Don't show error snackbar here as it might be expected for new vendors
      }
    } catch (e) {
      print("❌ Error in getBookingListFilter: $e");
      setState(() {
        records.clear();
      });
      // Don't show error snackbar here as it might be expected for new vendors
    }
  }

  getoffer(BuildContext context) async {
    var response = await dataManager!.getOfferList(context);
    var data = OfferListModelBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        offerListData.clear();
        offerListData.addAll(data.data!);
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  getNotifications(BuildContext context) async {
    var response = await dataManager!.getNotification(context);
    var data = NotificationDataBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        notificationsList.clear();
        notificationsList.addAll(data.data!.notifications!);
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  makeOffLine(BuildContext context) async {
    var response = await dataManager!.makeOffLine(context);
    var data = VendorDetailsMainBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        isShopOpen = data.data!.isShopOpen!;
      });
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  putStatusCompleted(BuildContext context, Records data) async {
    var response = await dataManager!.putStatusCompleted(context, data.sId.toString());
    var responseData = CompletedModelBean.fromJson(jsonDecode(response.body));
    if (responseData.status == "success") {
      CommonWidget.successShowSnackBarFor(context, responseData.message ?? "");
      getBookingListFilter(context);
    } else {
      CommonWidget.errorShowSnackBarFor(context, responseData.message ?? "");
    }
  }

  putStatusCancel(BuildContext context, String reason, String sId) async {
    var response = await dataManager!.putStatusCancel(context, reason, sId);
    var responseData = CompletedModelBean.fromJson(jsonDecode(response.body));
    if (responseData.status == "success") {
      CommonWidget.successShowSnackBarFor(context, responseData.message ?? "");
      getBookingListFilter(context);
    } else {
      CommonWidget.errorShowSnackBarFor(context, responseData.message ?? "");
    }
  }

  void _showQuickAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Quick Add",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAddOption(
                    "Add Service",
                    Icons.design_services,
                    Colors.green,
                    () {
                      CommonWidget.safePop(context);
                      CommonWidget.navigateToScreen(
                        context,
                        UltraSimpleAddService(),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAddOption(
                    "Add Package",
                    Icons.inventory_2,
                    Colors.purple,
                    () {
                      CommonWidget.safePop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPackageActivity(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAddOption(
                    "Create Offer",
                    Icons.local_offer,
                    Colors.orange,
                    () {
                      CommonWidget.safePop(context);
                      CommonWidget.navigateToScreen(
                        context,
                        const EnhancedOfferScreen(),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAddOption(
                    "Add Existing",
                    Icons.add_box,
                    Colors.teal,
                    () {
                      CommonWidget.safePop(context);
                      _showAddExistingOptions(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddExistingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Add Existing Items",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildAddExistingOption(
              "Browse Services",
              "Add from existing service templates",
              Icons.design_services,
              Colors.green,
              () {
                CommonWidget.safePop(context);
                CommonWidget.navigateToScreen(
                  context,
                  const ServicesListActivity(),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAddExistingOption(
              "Browse Packages",
              "Add from existing package templates",
              Icons.inventory_2,
              Colors.purple,
              () {
                CommonWidget.safePop(context);
                CommonWidget.navigateToScreen(
                  context,
                  const PackageListActivity(),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAddExistingOption(
              "Browse Offers",
              "Add from existing offer templates",
              Icons.local_offer,
              Colors.orange,
              () {
                CommonWidget.safePop(context);
                CommonWidget.navigateToScreen(
                  context,
                  const EnhancedOfferListScreen(),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddOption(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddExistingOption(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}






