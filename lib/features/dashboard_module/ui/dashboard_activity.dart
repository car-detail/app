import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/ShimmerLoader.dart';
import 'package:car_app/Common/ModernDesignSystem.dart';
import 'package:car_app/Common/TourGuide.dart';
import 'package:car_app/features/dashboard_module/model/vendor_details_main_bean.dart';
import 'package:car_app/features/home_module/ui/home_activity.dart';
import 'package:car_app/features/services_model/ui/services_list_activity.dart';
import 'package:car_app/features/booking_model/ui/booking_list_activity.dart';
import 'package:car_app/features/log_in/data_manager/LoginDataManager.dart';
import 'package:car_app/features/log_in/model/vendor_details_bean.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Common/Color.dart';
import '../../../Common/Constant.dart';
import '../../home_module/data_manager/home_data_manager.dart';
import '../../profile_model/ui/profile_vendor_list_activity.dart';
import '../../resister_vendor_model/ui/registor_vendor_activity.dart';

class DashboardActivity extends StatefulWidget {
  const DashboardActivity({super.key});

  @override
  State<DashboardActivity> createState() => _DashboardActivityState();
}

class _DashboardActivityState extends State<DashboardActivity> {
  int selectedpage = 0;
  HomeDataManager? dataManager;
  SharedPreferences? sharedPreferences;
  bool? tourShown; // This comes from database - tour_shown field
  LoginDataManager? loginDataManager;
  
  // Tour guide keys
  final GlobalKey _homeNavKey = GlobalKey();
  final GlobalKey _bookingsNavKey = GlobalKey();
  final GlobalKey _profileNavKey = GlobalKey();
  
  // Home screen tour guide keys
  final GlobalKey _shopStatusKey = GlobalKey();
  final GlobalKey _quickAccessKey = GlobalKey();

  @override
  void initState() {
    start();
    super.initState();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = HomeDataManager(sharedPreferences!);
    loginDataManager = LoginDataManager(sharedPreferences!);
    
    final vendorId = sharedPreferences!.getString(Constant.vendorId);
    
    if (vendorId != null && vendorId.isNotEmpty) {
      getdetails(context);
      _loadVendorDetails();
    } else {
      // Show a message to complete registration
      if (context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Please complete your vendor registration first");
      }
    }
  }
  
  Future<void> _loadVendorDetails() async {
    try {
      final response = await loginDataManager!.getUserDetails(context);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'success' && jsonData['data'] != null && jsonData['data'].isNotEmpty) {
          final vendorDetails = VendorDetailBean.fromJson(jsonData);
          if (vendorDetails.data != null && vendorDetails.data!.isNotEmpty) {
            if (mounted) {
              setState(() {
                tourShown = vendorDetails.data![0].tour_shown ?? false;
              });
              // Show tour guide only if not shown before (based on database tour_shown flag) and only on home screen
              // Only check tour_shown from database, not session flag
              if (!(tourShown ?? false) && selectedpage == 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  // Wait longer for home screen to be fully rendered, especially after navigation
                  await Future.delayed(const Duration(milliseconds: 2000));
                  // Retry up to 3 times if keys are not ready
                  int retryCount = 0;
                  while (retryCount < 3 && mounted && context.mounted && selectedpage == 0) {
                    if (_homeNavKey.currentContext != null && 
                        _shopStatusKey.currentContext != null &&
                        _quickAccessKey.currentContext != null) {
                      _showTourGuide();
                      break;
                    } else {
                      await Future.delayed(const Duration(milliseconds: 500));
                      retryCount++;
                    }
                  }
                  if (retryCount >= 3 && mounted && context.mounted && selectedpage == 0) {
                    _showTourGuide();
                  }
                });
              } else {
              }
            }
          }
        }
      }
    } catch (e) {
      // Don't show tour guide if API fails - user might have already seen it
    }
  }
  
  Future<void> _markTourAsSeen() async {
    try {
      if (loginDataManager != null) {
        final response = await loginDataManager!.markTourShown(context);
        if (response.statusCode == 200) {
          if (mounted) {
            setState(() {
              tourShown = true; // Update local state to reflect database change
            });
          }
        } else {
        }
      }
    } catch (e) {
    }
  }

  var isValid = true;

  makeItOffline() {
  }

  makeOffLine(BuildContext context, bool status) async {
    if (!mounted || !context.mounted) return;
    try {
    var response = await dataManager!.makeOffLine(context, isShopOpen: status);
      
      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(
            context, 
            "Unable to update store status. Please try again."
          );
        }
        return;
      }
      
      try {
    var data = VendorDetailsMainBean.fromJson(jsonDecode(response.body));
        if (data.status == "success" && data.data != null) {
      if (mounted) {
        setState(() {
              isValid = data.data?.isShopOpen ?? true;
        });
      }
          if (mounted && context.mounted) {
            CommonWidget.successShowSnackBarFor(
              context, 
              data.message ?? "Store status updated successfully"
            );
      }
    } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(
              context, 
              data.message ?? "Unable to update store status"
            );
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(
            context, 
            "Received invalid response. Please try again."
          );
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(
          context, 
          "Error updating store status. Please check your connection."
        );
      }
    }
  }
  getdetails(BuildContext context) async {
    if (!mounted || !context.mounted) return;
    try {
      var response = await dataManager!.getdetails(context);
      
      if (response.statusCode == 404) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(
            context, 
            "Business profile not found. Please complete your registration."
          );
        }
        return;
      }
      
      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(
            context, 
            "Unable to load business details. Please check your connection and try again."
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
              isValid = data.data?.isShopOpen ?? true;
          });
        }
      } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(
              context, 
              data.message ?? "Unable to load business details. Please try again."
            );
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(
            context, 
            "Received invalid response. Please try again later."
          );
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(
          context, 
          "Error loading business details. Please check your connection."
        );
      }
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
            SafeArea(
        child: isValid
            ? IndexedStack(
                key: const ValueKey('main_stack'),
                index: selectedpage,
                children: [
                  HomeActivity(
                    (value) {
                      if (mounted) {
                        setState(() {
                          isValid = value;
                        });
                      }
                    },
                    shopStatusKey: _shopStatusKey,
                    quickAccessKey: _quickAccessKey,
                  ),
                  _buildBookingsPage(),
                  ProfileVendorListActivity(isActive: selectedpage == 2),
                ],
              )
            : Scaffold(
                backgroundColor: Colors.grey[50],
                body: SafeArea(
                  child: Column(
                    children: [
                      // Modern Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          color: ColorClass.base_color,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          "Store Status",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: "Pop600",
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      // Main Content
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Status Icon
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: isValid 
                                        ? ColorClass.base_color.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isValid ? Icons.store : Icons.store_outlined,
                                    size: 60,
                                    color: isValid 
                                        ? ColorClass.base_color 
                                        : Colors.red[400],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                
                                // Status Message
                                Text(
                                  isValid 
                                      ? "Your Store is now Online"
                                      : "Your Store is now Offline",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontFamily: "Pop600",
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                
                                Text(
                                  isValid
                                      ? "Customers can see and book your services"
                                      : "Do you want to make it Online?",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontFamily: "Pop400",
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 48),
                                
                                // Modern Toggle Switch Card
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isValid ? "Online" : "Offline",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isValid 
                                                  ? ColorClass.base_color 
                                                  : Colors.red[400],
                                              fontFamily: "Pop600",
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isValid 
                                                ? "Tap to go offline"
                                                : "Tap to go online",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              fontFamily: "Pop400",
                                            ),
                                          ),
                                        ],
                                      ),
                                      Transform.scale(
                                        scale: 1.2,
                                        child: Switch(
                                          activeThumbColor: ColorClass.base_color,
                                          inactiveThumbColor: Colors.white,
                                          inactiveTrackColor: Colors.red[300],
                                          activeTrackColor: ColorClass.base_color.withOpacity(0.5),
                                          value: isValid,
                                          onChanged: (value) {
                                            makeOffLine(context, value);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
      ),
      bottomNavigationBar: isValid
          ? _buildModernBottomNav()
          : null,
      ),
    );
  }


  Future<String?> _getVendorId() async {
    sharedPreferences = await SharedPreferences.getInstance();
    String? vendorId = sharedPreferences?.getString(Constant.vendorId);
    return vendorId;
  }

  Widget _buildVendorRegistrationPrompt() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business,
                size: 80,
                color: ColorClass.base_color,
              ),
              const SizedBox(height: 20),
              Text(
                "Complete Vendor Registration",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ColorClass.base_color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "To manage services, you need to complete your vendor registration first.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  CommonWidget.navigateToScreen(
                    context,
                    const RegistorVendorActivity(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorClass.base_color,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "Complete Registration",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsPage() {
    return FutureBuilder<String?>(
      future: _getVendorId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: ShimmerLoader.buildCarLoadingAnimation(),
          );
        }
        
        String? vendorId = snapshot.data;
        if (vendorId == null || vendorId.isEmpty) {
          return _buildVendorRegistrationPrompt();
        }
        
        return const BookingListActivity();
      },
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            key: _homeNavKey,
            icon: Icons.home_rounded,
            label: 'Home',
            index: 0,
            isSelected: selectedpage == 0,
          ),
          _buildNavItem(
            key: _bookingsNavKey,
            icon: Icons.calendar_today_rounded,
            label: 'Bookings',
            index: 1,
            isSelected: selectedpage == 1,
          ),
          _buildNavItem(
            key: _profileNavKey,
            icon: Icons.person_rounded,
            label: 'Profile',
            index: 2,
            isSelected: selectedpage == 2,
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    Key? key,
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Expanded(
      key: key,
      child: GestureDetector(
      onTap: () {
        if (mounted && selectedpage != index) {
          setState(() => selectedpage = index);
        }
      },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                icon,
              color: isSelected ? const Color(0xFF1CB273) : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF1CB273) : Colors.grey[600],
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

  void _showTourGuide() {
    // Double check - don't show if already shown in database
    if (tourShown == true) {
      return;
    }
    
    TourGuide.showTour(
      context: context,
      tourId: 'vendor_dashboard',
      tourShown: tourShown ?? false,
      onMarkAsSeen: _markTourAsSeen, // This will be called when tour is completed or skipped
      steps: [
        TourStep(
          targetKey: _homeNavKey,
          title: "Home Tab",
          description: "View your business overview, manage services, view offers, and check your shop status",
          icon: Icons.home_rounded,
        ),
        TourStep(
          targetKey: _shopStatusKey,
          title: "Shop Status",
          description: "Toggle your shop status between online and offline. When online, customers can see and book your services",
          icon: Icons.store_rounded,
          alignment: Alignment.bottomCenter,
        ),
        TourStep(
          targetKey: _quickAccessKey,
          title: "Quick Actions",
          description: "Quickly access your services, packages, offers, and bookings. Manage all your business features from here",
          icon: Icons.dashboard_rounded,
          alignment: Alignment.bottomCenter,
        ),
        TourStep(
          targetKey: _bookingsNavKey,
          title: "Bookings Tab",
          description: "View and manage all customer bookings. See booking details, complete, or cancel bookings",
          icon: Icons.calendar_today_rounded,
        ),
        TourStep(
          targetKey: _profileNavKey,
          title: "Profile Tab",
          description: "Edit your business details, update your profile, manage settings, and view your business information",
          icon: Icons.person_rounded,
        ),
      ],
    );
  }
}
