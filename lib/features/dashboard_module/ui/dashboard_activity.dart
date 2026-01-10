import 'dart:convert';

import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/ShimmerLoader.dart';
import 'package:car_app/Common/FirstTimeTutorial.dart';
import 'package:car_app/Common/ModernDesignSystem.dart';
import 'package:car_app/features/dashboard_module/model/vendor_details_main_bean.dart';
import 'package:car_app/features/home_module/ui/home_activity.dart';
import 'package:car_app/features/services_model/ui/services_list_activity.dart';
import 'package:car_app/features/booking_model/ui/booking_list_activity.dart';
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
  final List<Widget> _pageNo = [];
  HomeDataManager? dataManager;
  SharedPreferences? sharedPreferences;

  @override
  void initState() {
    // TODO: implement initState
    _pageNo.addAll([
      HomeActivity((value) {
        print(
            "offlineofflineofflineofflineofflineofflineofflineofflineofflineoffline");
        if (mounted) {
          setState(() {
            isValid = value;
          });
        }
      }),
      _buildBookingsPage(),
      const ProfileVendorListActivity(),
    ]);
    start();
    super.initState();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = HomeDataManager(sharedPreferences!);
    
    final vendorId = sharedPreferences!.getString(Constant.vendorId);
    print("🔍 Dashboard - Checking vendorId: '$vendorId'");
    print("🔍 Dashboard - All SharedPreferences keys: ${sharedPreferences!.getKeys()}");
    
    if (vendorId != null && vendorId.isNotEmpty) {
      print("✅ VendorId found, loading vendor details");
      getdetails(context);
      
      // Show tutorial for first-time users
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await FirstTimeTutorial.showDashboardTutorial(context);
      });
    } else {
      print("❌ No vendorId found - vendor needs to complete registration");
      // Show a message to complete registration
      if (context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Please complete your vendor registration first");
      }
    }
  }

  var isValid = true;

  makeItOffline() {
    print(
        "offlineofflineofflineofflineofflineofflineofflineofflineofflineoffline");
  }

  makeOffLine(BuildContext context) async {
    var response = await dataManager!.makeOffLine(context);
    var data = VendorDetailsMainBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      if (mounted) {
        setState(() {
          isValid = data.data!.isShopOpen!;
        });
      }
      if (context.mounted) {
        CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      }
    } else {
      if (context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      }
    }
  }
  getdetails(BuildContext context) async {
    try {
      var response = await dataManager!.getdetails(context);
      print("🔍 Dashboard getdetails response: ${response.statusCode} - ${response.body}");
      
      if (response.statusCode == 404) {
        print("❌ Vendor not found - vendorId might be missing");
        CommonWidget.errorShowSnackBarFor(context, "Vendor profile not found. Please complete your registration.");
        return;
      }
      
      var data = VendorDetailsMainBean.fromJson(jsonDecode(response.body));
      if (data.status == "success") {
        if (mounted) {
          setState(() {
            isValid = data.data!.isShopOpen!;
          });
        }
        print("✅ Vendor details loaded successfully");
      } else {
        print("❌ API returned error: ${data.message}");
        if (context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to load vendor details");
        }
      }
    } catch (e) {
      print("❌ Error in getdetails: $e");
      if (context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error loading vendor details: ${e.toString()}");
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isValid
            ? IndexedStack(
                key: const ValueKey('main_stack'),
                index: selectedpage,
                children: _pageNo,
              )
            : Container(
                child: Column(
                  children: [
                    CommonWidget.gettopbar("Store Status", context,
                        isBack: false),
                    Expanded(
                        child: Container(
                      margin: const EdgeInsets.all(15),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CommonWidget.getTextWidgetPopbold(
                              "Your Store is now Offline, Do you want to make it Online?"),
                          const SizedBox(
                            height: 20,
                          ),
                          SizedBox(
                            height: 20,
                            child: Switch(
                                activeColor: ColorClass.base_color,
                                inactiveThumbColor: Colors.red,
                                inactiveTrackColor: Colors.red[100],
                                value: isValid,
                                onChanged: (onChanged) {
                                  makeOffLine(context);
                                }),
                          ),
                        ],
                      ),
                    ))
                  ],
                ),
              ),
      ),
      bottomNavigationBar: isValid
          ? _buildModernBottomNav()
          : null,
    );
  }


  Future<String?> _getVendorId() async {
    sharedPreferences = await SharedPreferences.getInstance();
    String? vendorId = sharedPreferences?.getString(Constant.vendorId);
    print("🔍 Dashboard - Vendor ID check: $vendorId");
    print("🔍 Dashboard - All stored keys: ${sharedPreferences?.getKeys()}");
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
      key: const ValueKey('bottom_nav'),
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: ModernDesignSystem.shadowLarge,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(ModernDesignSystem.radiusXL),
          topRight: Radius.circular(ModernDesignSystem.radiusXL),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            index: 0,
            isSelected: selectedpage == 0,
          ),
          _buildNavItem(
            icon: Icons.calendar_today_rounded,
            label: 'Bookings',
            index: 1,
            isSelected: selectedpage == 1,
          ),
          _buildNavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            index: 2,
            isSelected: selectedpage == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    // Help text for each tab
    final helpTexts = {
      0: "Tap here to see your business overview and manage services",
      1: "Tap here to view and manage all customer bookings",
      2: "Tap here to edit your profile and business settings",
    };

    return GestureDetector(
      onTap: () {
        if (mounted && selectedpage != index) {
          setState(() => selectedpage = index);
        }
      },
      onLongPress: () {
        if (!mounted) return;
        // Show help on long press
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(icon, color: ColorClass.base_color),
                const SizedBox(width: 8),
                Text(label),
              ],
            ),
            content: Text(helpTexts[index] ?? "This is the $label section"),
            actions: [
              TextButton(
                onPressed: () => CommonWidget.safePop(context),
                child: Text(
                  "Got it!",
                  style: TextStyle(color: ColorClass.base_color),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        key: ValueKey('nav_item_$index'),
        padding: const EdgeInsets.symmetric(horizontal: ModernDesignSystem.spacingM, vertical: ModernDesignSystem.spacingS),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? ColorClass.base_color : Colors.transparent,
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : ColorClass.dark_gray_base,
                size: 22,
              ),
            ),
            const SizedBox(height: ModernDesignSystem.spacingXS),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: TextStyle(
                color: isSelected ? ColorClass.base_color : ColorClass.dark_gray_base,
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
