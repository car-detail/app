import 'dart:convert';
// import 'dart:ffi'; // Not available on web platform

import 'package:flutter/services.dart';
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
  final GlobalKey? shopStatusKey;
  final GlobalKey? quickAccessKey;
  
  HomeActivity(
    this.offline, {
    this.shopStatusKey,
    this.quickAccessKey,
    super.key,
  });

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
  PageController? offerPageController;
  int currentOfferPage = 0;
  String vendorName = ""; // Store vendor display name

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    offerPageController = PageController();
    start();
  }

  @override
  void dispose() {
    offerPageController?.dispose();
    super.dispose();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = HomeDataManager(sharedPreferences!);
    
    final vendorIdValue = sharedPreferences!.getString(Constant.vendorId) ?? "";
    setState(() {
      vendorId = vendorIdValue;
    });
    

    if (vendorIdValue.isNotEmpty) {
      getdetails(context);
      getServices(context); // Load services data for Business Overview
    } else {
      // Don't make API calls if there's no vendorId
    }
  }

  getdetails(BuildContext context) async {
    if (!mounted) return;
    try {
      var response = await dataManager!.getdetails(context);
      
      if (response.statusCode == 404) {
        if (mounted && context.mounted) {
          // Only show error if vendor was previously registered
          final hasVendorId = sharedPreferences?.getString(Constant.vendorId)?.isNotEmpty ?? false;
          if (hasVendorId) {
            CommonWidget.errorShowSnackBarFor(
              context, 
              "Unable to load your business details. Please check your connection."
            );
          }
        }
        return;
      }
      
      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(
            context, 
            "Unable to load business details. Please try again."
          );
        }
        return;
      }
      
      // Check if response is valid JSON
      try {
      var data = VendorDetailsMainBean.fromJson(jsonDecode(response.body));
        if (data.status == "success" && data.data != null) {
          if (mounted) {
        setState(() {
              isShopOpen = data.data?.isShopOpen ?? true;
              vendorName = data.data?.displayName ?? "";
        });
          }
          if (data.data?.isShopOpen == true && mounted && context.mounted) {
          getBookingListFilter(context);
          getoffer(context);
          getNotifications(context);
        }
      } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(
              context, 
              data.message ?? "Unable to load business details."
            );
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(
            context, 
            "Received invalid response from server. Please try again."
          );
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(
          context, 
          "Error loading business details: ${e.toString()}. Please check your connection."
        );
      }
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
    // Set status bar style when this screen builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: ColorClass.base_color,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    });
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Transparent so green background shows
        statusBarIconBrightness: Brightness.light, // White icons
        statusBarBrightness: Brightness.dark, // For iOS
        systemNavigationBarColor: ColorClass.base_color,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Green status bar background - MUST be at the very top
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
          // Header with store status and notifications
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorClass.base_color,
                  ColorClass.base_color.withOpacity(0.9),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorClass.base_color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top row with vendor name and notifications
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Vendor name on the left
                                Expanded(
                                  child: Text(
                          vendorName.isNotEmpty ? vendorName : "My Business",
                                    style: const TextStyle(
                                      color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Pop600",
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Notification icon on the right
                      GestureDetector(
                        onTap: () {
                          CommonWidget.navigateToScreen(
                              context, NotificationActivity(notificationsList));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                              if (notificationsList.isNotEmpty)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      '${notificationsList.length > 9 ? "9+" : notificationsList.length}',
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
                ),
                const SizedBox(height: 16),
                // Store status card
                if (vendorId != "")
                  Container(
                    key: widget.shopStatusKey,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.store_rounded,
                          color: isShopOpen ? ColorClass.base_color : Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              const Text(
                                "Shop Status",
                                style: TextStyle(
                                  fontFamily: "Pop600",
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isShopOpen 
                                      ? ColorClass.base_color.withOpacity(0.1)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: isShopOpen ? ColorClass.base_color : Colors.grey[400],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isShopOpen ? "Online" : "Offline",
                                      style: TextStyle(
                                        fontFamily: "Pop500",
                                        fontSize: 11,
                                        color: isShopOpen ? ColorClass.base_color : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            activeThumbColor: ColorClass.base_color,
                            inactiveThumbColor: Colors.grey[400],
                            inactiveTrackColor: Colors.grey[200],
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
                                "",
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
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (mounted && context.mounted) {
                  await getdetails(context);
                  await getServices(context);
                }
              },
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
                              Text(
                                "Recent Bookings",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontFamily: "Pop500",
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (!mounted) return;
                                  try {
                                  CommonWidget.navigateToScreen(
                                    context,
                                    const BookingListActivity(),
                                  );
                                  } catch (e) {
                                    if (mounted && context.mounted) {
                                      CommonWidget.errorShowSnackBarFor(
                                        context,
                                        "Unable to open bookings. Please try again."
                                      );
                                    }
                                  }
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  "View All",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF1CB273),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Show only the first 3 pending bookings
                          ...records.take(3).map((booking) => _buildPendingBookingCard(booking)),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                  
                  // Business Metrics Cards
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            "Bookings",
                            "${records.length}",
                            "calendar_blue.png",
                            const Color(0xFF3B82F6), // Blue
                            0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            "Services",
                            "${servicesData.length}",
                            "assignment.png",
                            const Color(0xFFF59E0B), // Orange
                            1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            "Rating",
                            "4.8",
                            "stars_icon.png",
                            const Color(0xFFFBBF24), // Amber
                            2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Quick Actions
                  Container(
                    key: widget.quickAccessKey,
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        Text(
                          "Quick Actions",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: "Pop500",
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                "Services",
                                Icons.auto_awesome_rounded,
                                const Color(0xFF10B981), // Green
                                () {
                                  CommonWidget.navigateToScreen(
                                    context, 
                                    const ServicesListActivity()
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionCard(
                                "Packages",
                                Icons.card_giftcard_rounded,
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                "Offers",
                                Icons.local_fire_department_rounded,
                                const Color(0xFFF59E0B), // Orange
                                () {
                                  CommonWidget.navigateToScreen(
                                    context, 
                                    const EnhancedOfferListScreen()
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionCard(
                                "Manage Bookings",
                                Icons.event_available_rounded,
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                "View Analytics",
                                Icons.trending_up_rounded,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionCard(
                                "Quick Add",
                                Icons.add_circle_rounded,
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
                            Text(
                              "Recent Bookings",
                              style: TextStyle(
                                fontFamily: "Pop500",
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.grey[600],
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
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.book_online_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No bookings yet",
                                  style: TextStyle(
                                    fontFamily: "Pop500",
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Your bookings will appear here",
                                  style: TextStyle(
                                    fontFamily: "Pop400",
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
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
                  
                  const SizedBox(height: 20),
                  
                  // Offers Section
                  if (offerListData.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                  "View All",
                                  style: TextStyle(
                                        fontFamily: "PopSemi",
                                    fontSize: 14,
                                    color: ColorClass.base_color,
                                        fontWeight: FontWeight.w600,
                                  ),
                                ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 12,
                                      color: ColorClass.base_color,
                              ),
                            ],
                          ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          offerListData.isEmpty
                              ? Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "No offers available",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: "Pop400",
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    SizedBox(
                                      height: 200,
                                      child: PageView.builder(
                                        controller: offerPageController,
                                        onPageChanged: (index) {
                                          setState(() {
                                            currentOfferPage = index;
                                          });
                                        },
                                        itemCount: offerListData.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 0),
                                            child: _buildFullWidthOfferCard(offerListData[index]),
                                          );
                                        },
                                      ),
                                    ),
                                    if (offerListData.length > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: List.generate(
                                            offerListData.length,
                                            (index) => Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.symmetric(horizontal: 4),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: currentOfferPage == index
                                                    ? ColorClass.base_color
                                                    : Colors.grey[300],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
        ],
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
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

  // Helper method to build metric cards - Minimal design with realistic icons
  Widget _buildMetricCard(String title, String value, String iconAsset, Color iconColor, int index) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              CommonWidget.getImagePath(iconAsset),
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.info_outline,
                  color: iconColor,
                  size: 32,
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.1,
              fontFamily: "Pop500",
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
              fontFamily: "Pop400",
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method to build quick action cards - Enhanced design
  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontFamily: "Pop600",
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

  // Helper method to build booking cards - Simple design
  Widget _buildBookingCard(Records booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
                child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.grey,
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
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Slot: ${CommonWidget.convertToLocalTime(booking.timeSlot ?? "")}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      "Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(booking.date ?? ""))}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.orderStatus ?? "").withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.orderStatus ?? "",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
                  child: ElevatedButton(
                    onPressed: () {
                      putStatusCompleted(context, booking);
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1CB273),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                      ),
                              ),
                              child: const Text(
                        "Complete",
                                style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                const SizedBox(width: 8),
                        Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showCancelDialog(context, booking);
                            },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                      ),
                              ),
                              child: const Text(
                        "Cancel",
                                style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
  // Build Full Width Offer Card for Carousel
  Widget _buildFullWidthOfferCard(OfferListModelData offer) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background Image or Color
            if (offer.image != null && offer.image!.isNotEmpty)
              Image.network(
                offer.image!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorClass.base_color,
                          ColorClass.base_color.withOpacity(0.7),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorClass.base_color,
                      ColorClass.base_color.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            // Content Overlay
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.orange[300],
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            offer.title ?? "Offer",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: "Pop600",
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offer.description ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (offer.discount != null && offer.discount! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${offer.discount}% OFF",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.all_inclusive,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Never expires",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (offer.isActive ?? true) ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (offer.isActive ?? true) ? "Active" : "Inactive",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

  // Build Offer Card (keeping for compatibility if needed elsewhere)
  Widget _buildOfferCard(OfferListModelData offer) {
    final isExpired = offer.validUntil != null && 
                     offer.validUntil!.isNotEmpty &&
                     DateTime.parse(offer.validUntil!).isBefore(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(right: 16),
        width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        ),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
            // Background Image
              Image.network(
                offer.image ?? "",
                height: 150,
                width: 280,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    width: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorClass.base_color.withOpacity(0.3),
                        ColorClass.base_color.withOpacity(0.6),
                      ],
                    ),
                  ),
                    child: const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                      size: 48,
                    ),
                  );
                },
              ),
            
            // Discount Badge - Top Right
            if (offer.discount != null && offer.discount! > 0)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "OFF",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "PopBold",
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${offer.discount}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: "PopBold",
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Expired Badge - Top Left
            if (isExpired)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "EXPIRED",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "PopSemi",
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            
            // Bottom Gradient Overlay with Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                      Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                    children: [
                    // Title
                      Text(
                      offer.title ?? "Special Offer",
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: "PopSemi",
                          fontWeight: FontWeight.w600,
                        fontSize: 16,
                        height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    // Description
                    if (offer.description != null && offer.description!.isNotEmpty)
                      Text(
                        offer.description!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontFamily: "PopReg",
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Validity Info
                    if (offer.validUntil != null && offer.validUntil!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: isExpired 
                                ? Colors.red[300] 
                                : Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Valid until ${CommonWidget.getDateFormat(offer.validUntil!)}",
                            style: TextStyle(
                              color: isExpired 
                                  ? Colors.red[300] 
                                  : Colors.white.withOpacity(0.8),
                              fontFamily: "PopReg",
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.all_inclusive_rounded,
                            size: 12,
                            color: Colors.green[300],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Never expires",
                            style: TextStyle(
                              color: Colors.green[300],
                              fontFamily: "PopReg",
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
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
      
      if (response.statusCode == 404) {
        return;
      }
      
      var data = ServicesModelData.fromJson(jsonDecode(response.body));
      if (data.status == "success") {
        setState(() {
          servicesData.clear();
          servicesData.addAll(data.data!);
        });
      } else {
        // Don't show error snackbar here as it might be expected for new vendors
      }
    } catch (e) {
      // Don't show error snackbar here as it might be expected for new vendors
    }
  }

  getBookingListFilter(BuildContext context) async {
    try {
      var response = await dataManager!.getBookingListFilter(context, "Pending");
      
      if (response.statusCode == 404) {
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
      } else {
        setState(() {
          records.clear();
        });
        // Don't show error snackbar here as it might be expected for new vendors
      }
    } catch (e) {
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
                        const UltraSimpleAddService(),
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






