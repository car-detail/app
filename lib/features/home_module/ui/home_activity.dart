import 'dart:convert';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart';
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
import '../../services_model/ui/services_list_activity.dart';
import '../../booking_model/ui/booking_list_activity.dart';
import '../../offer_model/ui/enhanced_offer_screen.dart';
import '../../packages_model/ui/add_package_activity.dart';
import '../../packages_model/ui/package_list_activity.dart';
import '../../notification_model/ui/notification_activity.dart';
import '../../services_model/ui/modern_add_service_activity.dart';
import 'location_picker_screen.dart';

class HomeActivity extends StatefulWidget {
  Function(bool value) offline;
  final Function(int index)? onTabChange;
  final GlobalKey? shopStatusKey;
  final GlobalKey? quickAccessKey;
  
  HomeActivity(
    this.offline, {
    this.onTabChange,
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
  double vendorRating = 0.0;
  Timer? _refreshTimer;

  // Analytics fields
  int todayBookingsCount = 0;
  double weeklyRevenue = 0.0;
  int pendingBookings = 0;
  int completedBookings = 0;
  int cancelledBookings = 0;
  int totalReviews = 0;
  bool isAnalyticsLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    offerPageController = PageController();
    start();
    // Auto-refresh every 60 seconds as a fallback
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        start();
      }
    });

    // Instant refresh when a push notification is received
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        print("🔔 Notification received in foreground, refreshing data...");
        // Play notification sound
        try {
          _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-500.wav'));
        } catch (e) {
          debugPrint("Failed to play sound: $e");
        }
        start();
      }
    });
  }

  @override
  void dispose() {
    offerPageController?.dispose();
    _refreshTimer?.cancel();
    _audioPlayer.dispose();
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
      getAnalytics(context);
    } else {
      // Don't make API calls if there's no vendorId
    }
  }

  getAnalytics(BuildContext context) async {
    if (!mounted) return;
    try {
      var response = await dataManager!.getVendorAnalytics(context);
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] != null) {
          var data = body['data'];
          if (mounted) {
            setState(() {
              todayBookingsCount = data['todayBookings'] ?? 0;
              weeklyRevenue = (data['weeklyRevenue'] ?? 0).toDouble();
              pendingBookings = data['pendingBookings'] ?? 0;
              completedBookings = data['completedBookings'] ?? 0;
              cancelledBookings = data['cancelledBookings'] ?? 0;
              totalReviews = data['totalReviews'] ?? 0;
              vendorRating = (data['averageRating'] ?? 0.0).toDouble();
              isAnalyticsLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch analytics: $e");
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
            // Main content
            Column(
        children: [
          // Header with store status and notifications
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: ModernDesignSystem.brandGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorClass.base_color.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Welcome back 👋",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: "Pop400",
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        vendorName.isNotEmpty ? vendorName : "My Business",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: "Pop600",
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                      const SizedBox(width: 12),
                      // Notification icon on the right
                      GestureDetector(
                        onTap: () {
                          debugPrint('🔔 Vendor App: Opening notifications with ${notificationsList.length} items');
                          CommonWidget.navigateToScreen(
                              context, NotificationActivity(notificationsList));
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              if (notificationsList.any((n) {
                                String? lastReadStr = sharedPreferences?.getString(Constant.lastReadNotificationsAt);
                                if (lastReadStr == null) return true;
                                DateTime lastRead = DateTime.parse(lastReadStr);
                                return n.createdAt != null && DateTime.parse(n.createdAt!).isAfter(lastRead);
                              }))
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
                                    child: Builder(
                                      builder: (context) {
                                        int unreadCount = notificationsList.where((n) {
                                          String? lastReadStr = sharedPreferences?.getString(Constant.lastReadNotificationsAt);
                                          if (lastReadStr == null) return true;
                                          DateTime lastRead = DateTime.parse(lastReadStr);
                                          return n.createdAt != null && DateTime.parse(n.createdAt!).isAfter(lastRead);
                                        }).length;
                                        return Text(
                                          '${unreadCount > 9 ? "9+" : unreadCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        );
                                      }
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
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.store_rounded,
                          color: Colors.white,
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
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: isShopOpen ? const Color(0xFF1CB273) : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isShopOpen ? "Online" : "Offline",
                                      style: TextStyle(
                                        fontFamily: "Pop500",
                                        fontSize: 11,
                                        color: isShopOpen ? const Color(0xFF1CB273) : Colors.grey[600],
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
                            activeColor: Colors.white,
                            activeTrackColor: Colors.white.withOpacity(0.4),
                            inactiveThumbColor: Colors.grey[400],
                            inactiveTrackColor: Colors.grey[200],
                            value: isShopOpen,
                            onChanged: (val) {
                              if (isShopOpen) {
                                // Instead of simple dialog, show duration selector when turning offline
                                _showOfflineDurationSelector(context);
                              } else {
                                // Simple dialog when turning online
                                CommonPopUp.showalertDialog(
                                  context,
                                  "",
                                  "Are you sure you want to make the store online?",
                                  "No",
                                  "Yes",
                                  "",
                                  () => CommonWidget.safePop(context),
                                  () async {
                                    CommonWidget.safePop(context);
                                    makeOffLine(context, targetStatus: true);
                                  },
                                  190,
                                  positivetitlecolorButton: ColorClass.red,
                                  navtextColorButton: ColorClass.green,
                                  isboldtitle: false,
                                );
                              }
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

                  if (records.isNotEmpty)
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
                                  fontFamily: "Pop600",
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: Colors.black87,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (widget.onTabChange != null) {
                                    widget.onTabChange!(1);
                                  } else {
                                    CommonWidget.navigateToScreen(
                                      context,
                                      const BookingListActivity()
                                    );
                                  }
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
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: records.length > 3 ? 3 : records.length,
                            itemBuilder: (context, index) {
                              return _buildBookingCard(records[index]);
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  
                  // Business Metrics Cards & Analytics Dashboard
                  if (vendorId.isNotEmpty)
                    _buildDashboardAnalyticsCard(),
                  
                  const SizedBox(height: 25),
                  
                  // Quick Actions
                  Container(
                    key: widget.quickAccessKey,
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        const Text(
                          "Quick Actions",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Colors.black87,
                            fontFamily: "Pop600",
                            letterSpacing: -0.5,
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
                                "Bookings",
                                Icons.event_available_rounded,
                                const Color(0xFF3B82F6), // Blue
                                () {
                                  if (widget.onTabChange != null) {
                                    widget.onTabChange!(1);
                                  } else {
                                    CommonWidget.navigateToScreen(
                                      context, 
                                      const BookingListActivity()
                                    );
                                  }
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

  // Helper method to build metric cards - Gradient design
  Widget _buildMetricCard(String title, String value, String iconAsset, Color iconColor, int index) {
    final List<List<Color>> gradients = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)], // Bookings
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)], // Services
      [const Color(0xFF11998E), const Color(0xFF38EF7D)], // Rating
    ];
    final List<IconData> icons = [
      Icons.calendar_today_rounded,
      Icons.miscellaneous_services_rounded,
      Icons.star_rounded,
    ];
    final gradientColors = gradients[index % gradients.length];
    final iconData = icons[index % icons.length];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconData,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.1,
              fontFamily: "Pop600",
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.85),
              fontFamily: "Pop400",
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method to build quick action cards - Compact neutral design
  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: "Pop600",
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardAnalyticsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 4,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Business Analytics",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                ),
              ),
              if (isAnalyticsLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorClass.base_color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Live",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ColorClass.base_color,
                      fontFamily: "Pop600",
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Today's Bookings
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Bookings",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF166534),
                          fontFamily: "Pop500",
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$todayBookingsCount",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                          fontFamily: "Pop700",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Weekly Revenue
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Weekly Revenue",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E40AF),
                          fontFamily: "Pop500",
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${Constant.rupee}${weeklyRevenue.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                          fontFamily: "Pop700",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status counts row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStatus("Pending", pendingBookings, Colors.amber),
              _buildMiniStatus("Completed", completedBookings, Colors.green),
              _buildMiniStatus("Cancelled", cancelledBookings, Colors.red),
            ],
          ),
          const Divider(height: 32),
          // Ratings & Reviews
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 6),
              Text(
                vendorRating > 0 ? vendorRating.toStringAsFixed(1) : "—",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "($totalReviews reviews)",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontFamily: "Pop400",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatus(String label, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: "Pop400",
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            "$count",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: "Pop600",
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build booking cards - Modern Gen-Z design
  Widget _buildBookingCard(Records booking) {
    final statusColor = _getStatusColor(booking.orderStatus ?? "");
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1CB273), Color(0xFF00E676)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
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
                      "Slot: ${CommonWidget.formatTimeSlot(booking.timeSlot ?? "")}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      "Date: ${DateFormat(Constant.dateFormatDigits).format(DateTime.parse(booking.date ?? ""))}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor,
                          statusColor.withOpacity(0.75),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      booking.orderStatus ?? "",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (booking.createdByMobile != null && booking.createdByMobile!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final Uri launchUri = Uri(
                          scheme: 'tel',
                          path: booking.createdByMobile,
                        );
                        if (await canLaunchUrl(launchUri)) {
                          await launchUrl(launchUri);
                        } else {
                          if (context.mounted) {
                            CommonWidget.errorShowSnackBarFor(context, "Could not launch dialer");
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorClass.base_color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.call,
                          color: ColorClass.base_color,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
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
      ),
    );
  }

  // Helper method to build offer cards
  // Build Full Width Offer Card for Carousel
  Widget _buildFullWidthOfferCard(OfferListModelData offer) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
              const SizedBox(width: 8),
              // Status badge and Call button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: ModernDesignSystem.spacingM, vertical: ModernDesignSystem.spacingXS),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.orderStatus ?? "pending"),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      booking.orderStatus ?? "Pending",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: "Pop500",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (booking.createdByMobile != null && booking.createdByMobile!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final Uri launchUri = Uri(
                          scheme: 'tel',
                          path: booking.createdByMobile,
                        );
                        if (await canLaunchUrl(launchUri)) {
                          await launchUrl(launchUri);
                        } else {
                          if (context.mounted) {
                            CommonWidget.errorShowSnackBarFor(context, "Could not launch dialer");
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorClass.base_color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.call,
                          color: ColorClass.base_color,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
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
          final rated = servicesData.where((s) => (s.averageRating ?? 0) > 0).toList();
          vendorRating = rated.isEmpty ? 0.0 : rated.map((s) => s.averageRating!.toDouble()).reduce((a, b) => a + b) / rated.length;
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
      debugPrint('📅 getBookingListFilter: Fetching Pending bookings...');
      var response = await dataManager!.getBookingListFilter(context, "Pending");
      debugPrint('📅 getBookingListFilter: Status Code: ${response.statusCode}');
      
      if (!mounted) return;
      
      if (response.statusCode == 404) {
        debugPrint('📅 getBookingListFilter: 404 - Clearing records');
        setState(() {
          records.clear();
        });
        return;
      }
      
      var data = BookingListBean.fromJson(jsonDecode(response.body));
      debugPrint('📅 getBookingListFilter: Response Status: ${data.status}');
      if (data.status == "success") {
        debugPrint('📅 getBookingListFilter: Found ${data.data?.records?.length ?? 0} records');
        setState(() {
          records.clear();
          List<Records> fetchedRecords = data.data!.records!;
          // Sort records by date and timeSlot (descending - most recent first)
          fetchedRecords.sort((a, b) {
            int dateCompare = (b.date ?? "").compareTo(a.date ?? "");
            if (dateCompare != 0) return dateCompare;
            return (b.timeSlot ?? "").compareTo(a.timeSlot ?? "");
          });
          records.addAll(fetchedRecords);
        });
      } else {
        debugPrint('📅 getBookingListFilter: Status not success - clearing records');
        setState(() {
          records.clear();
        });
      }
    } catch (e, stackTrace) {
      debugPrint('📅 getBookingListFilter Error: $e');
      debugPrint('📅 StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          records.clear();
        });
      }
    }
  }

  getoffer(BuildContext context) async {
    var response = await dataManager!.getOfferList(context);
    if (!mounted) return;
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
    try {
      debugPrint('🔔 Vendor App: Fetching notifications...');
      var response = await dataManager!.getNotification(context);
      if (!mounted) return;
      debugPrint('🔔 Vendor App: Response status ${response.statusCode}');
      var data = NotificationDataBean.fromJson(jsonDecode(response.body));
      debugPrint('🔔 Vendor App: Parsed - status: ${data.status}, count: ${data.data?.notifications?.length ?? 0}');
      if (data.status == "success") {
        setState(() {
          notificationsList.clear();
          notificationsList.addAll(data.data!.notifications!);
          debugPrint('🔔 Vendor App: State updated with ${notificationsList.length} notifications');
        });
      } else {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Vendor App: Error in getNotifications: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _showOfflineDurationSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Go Offline",
              style: TextStyle(
                fontSize: 20,
                fontFamily: "Pop600",
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Choose how long you'd like to stay offline. You can still accept future bookings.",
              style: TextStyle(
                fontSize: 14,
                fontFamily: "Pop400",
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 25),
            
            _buildDurationOption(
              icon: Icons.today,
              title: "Just for Today",
              subtitle: "Shop will automatically open tomorrow",
              onTap: () {
                final today = DateTime.now();
                final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
                CommonWidget.safePop(context);
                makeOffLine(context, targetStatus: false, offlineUntil: endOfDay.toIso8601String());
              },
            ),
            const SizedBox(height: 15),
            
            _buildDurationOption(
              icon: Icons.calendar_month,
              title: "Until a Specific Date",
              subtitle: "Shop will stay offline until your chosen date",
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: ColorClass.base_color,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                
                if (picked != null) {
                  final endOfPickedDay = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
                  CommonWidget.safePop(context);
                  makeOffLine(context, targetStatus: false, offlineUntil: endOfPickedDay.toIso8601String());
                }
              },
            ),
            const SizedBox(height: 15),
            
            _buildDurationOption(
              icon: Icons.do_not_disturb_on,
              title: "Until I Turn it Back On",
              subtitle: "Manual control over your shop status",
              onTap: () {
                CommonWidget.safePop(context);
                makeOffLine(context, targetStatus: false);
              },
              isLast: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorClass.base_color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: ColorClass.base_color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: "Pop600",
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: "Pop400",
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  makeOffLine(BuildContext context, {bool? targetStatus, String? offlineUntil}) async {
    bool nextStatus = targetStatus ?? !isShopOpen;
    var response = await dataManager!.makeOffLine(
      context, 
      isShopOpen: nextStatus,
      offlineUntil: offlineUntil
    );
    if (!mounted) return;
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
    try {
      debugPrint('📅 putStatusCompleted: Marking booking ${data.sId} as Completed');
      var response = await dataManager!.putStatusCompleted(context, data.sId.toString());
      if (!mounted) return;
      var responseData = CompletedModelBean.fromJson(jsonDecode(response.body));
      debugPrint('📅 putStatusCompleted: Status: ${responseData.status}');
      if (responseData.status == "success") {
        CommonWidget.successShowSnackBarFor(context, responseData.message ?? "");
        debugPrint('📅 putStatusCompleted: Success - Refreshing list');
        if (mounted && context.mounted) {
          await getBookingListFilter(context);
        }
        debugPrint('📅 putStatusCompleted: List refresh triggered');
      } else {
        CommonWidget.errorShowSnackBarFor(context, responseData.message ?? "");
      }
    } catch (e) {
      debugPrint('📅 putStatusCompleted Error: $e');
    }
  }

  putStatusCancel(BuildContext context, String reason, String sId) async {
    try {
      debugPrint('📅 putStatusCancel: Cancelling booking $sId. Reason: $reason');
      var response = await dataManager!.putStatusCancel(context, reason, sId);
      if (!mounted) return;
      var responseData = CompletedModelBean.fromJson(jsonDecode(response.body));
      debugPrint('📅 putStatusCancel: Status: ${responseData.status}');
      if (responseData.status == "success") {
        CommonWidget.successShowSnackBarFor(context, responseData.message ?? "");
        debugPrint('📅 putStatusCancel: Success - Refreshing list');
        if (mounted && context.mounted) {
          await getBookingListFilter(context);
        }
        debugPrint('📅 putStatusCancel: List refresh triggered');
      } else {
        CommonWidget.errorShowSnackBarFor(context, responseData.message ?? "");
      }
    } catch (e) {
      debugPrint('📅 putStatusCancel Error: $e');
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
                        const ModernAddServiceActivity(),
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






