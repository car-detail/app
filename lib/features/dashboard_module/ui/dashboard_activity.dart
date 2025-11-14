import 'dart:convert';

import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/ShimmerLoader.dart';
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
        setState(() {
          isValid = value;
        });
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
    } else {
      print("❌ No vendorId found - vendor needs to complete registration");
      // Show a message to complete registration
      CommonWidget.errorShowSnackBarFor(context, "Please complete your vendor registration first");
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
      setState(() {
        isValid = data.data!.isShopOpen!;
      });
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
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
        setState(() {
          isValid = data.data!.isShopOpen!;
        });
        print("✅ Vendor details loaded successfully");
      } else {
        print("❌ API returned error: ${data.message}");
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to load vendor details");
      }
    } catch (e) {
      print("❌ Error in getdetails: $e");
      CommonWidget.errorShowSnackBarFor(context, "Error loading vendor details: ${e.toString()}");
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isValid
            ? _pageNo[selectedpage]
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
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
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
    return GestureDetector(
      onTap: () => setState(() => selectedpage = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? ColorClass.base_color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? ColorClass.base_color : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: ColorClass.base_color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : ColorClass.dark_gray_base,
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? ColorClass.base_color : ColorClass.dark_gray_base,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
