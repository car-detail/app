import 'dart:convert';
import 'dart:io';

import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonBean.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/ContainerDecoration.dart';
import 'package:car_app/features/log_in/ui/LoginActivity.dart';
import 'package:car_app/features/log_in/ui/edit_user_details_activity.dart';
import 'package:car_app/features/resister_vendor_model/ui/edit_vendor_activity.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/CommonPopUp.dart';
import '../../../Common/Constant.dart';
import '../../log_in/model/vendor_details_bean.dart';
import '../../log_in/ui/profile_activity.dart';
import '../../resister_vendor_model/ui/registor_vendor_activity_simple.dart';
import '../data_manager/profile_list_data_manager.dart';

class ProfileVendorListActivity extends StatefulWidget {
  const ProfileVendorListActivity({super.key});

  @override
  State<ProfileVendorListActivity> createState() =>
      _ProfileVendorListActivityState();
}

class _ProfileVendorListActivityState extends State<ProfileVendorListActivity> {
  ApiFuntions apiFuntions = ApiFuntions();
  ProfileListDataManager? dataManager;
  late SharedPreferences? sharedPreferences;
  final bool _isPasswordVisible = false;
  int maxLength = 10;
  VendorDetailData? dataNew;
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
    dataManager = ProfileListDataManager(sharedPreferences!);
    venderId = sharedPreferences!.getString(Constant.vendorId) ?? "";
    getUser(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // Enhanced Header
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Profile",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dataNew?.firstName != null 
                              ? "Welcome back, ${dataNew!.firstName}!"
                              : "Manage your account",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        _showLogoutDialog(context);
                      },
                      child: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
                child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                    // Personal Details Card
                    if (dataNew != null) _buildPersonalDetailsCard(),
                    const SizedBox(height: 20),
                    // Shop Details Card
                    if (dataNew != null &&
                        dataNew!.vendorDetails!.isNotEmpty &&
                        dataNew!.vendorDetails![0].sId != "")
                      _buildShopDetailsCard()
                    else
                      _buildAddShopCard(),
                    const SizedBox(height: 20),
                    // Settings Card
                    _buildSettingsCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            )
          ],
        ));
  }

  Widget _buildPersonalDetailsCard() {
    return Container(
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
                                child: Column(
                                  children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorClass.base_color.withOpacity(0.1),
                  ColorClass.base_color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
                                      children: [
                Icon(
                  Icons.person,
                  color: ColorClass.base_color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Personal Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorClass.base_color,
                  ),
                ),
                const Spacer(),
                                        InkWell(
                                          onTap: () {
                                            Navigator.of(context)
                                                .push(
                                              MaterialPageRoute(
                        builder: (context) => const ProfileActivity(),
                                              ),
                                            )
                                                .then((onValue) {
                                              if (onValue == true) {
                                                getUser(context);
                                              }
                                            });
                                          },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ColorClass.base_color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                                                      "Edit",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                                ),
                              ),
                            ],
                          ),
                        ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Image
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: ColorClass.base_color.withOpacity(0.1),
                        child: ClipOval(
                          child: Image.network(
                            dataNew?.image ?? "",
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 50,
                                color: ColorClass.base_color,
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ColorClass.base_color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                              color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Details
                _buildDetailRow("Name", "${dataNew?.firstName ?? ""} ${dataNew?.lastName ?? ""}"),
                if (dataNew?.email != null && dataNew!.email!.isNotEmpty)
                  _buildDetailRow("Email", dataNew?.email ?? ""),
                _buildDetailRow("Mobile", dataNew?.mobile ?? ""),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopDetailsCard() {
    return Container(
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
      child: Column(
                                  children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.green.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
                                          children: [
                                            const Icon(
                  Icons.store,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Shop Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context)
                                            .push(
                                          MaterialPageRoute(
                        builder: (context) => const EditVendorActivity(),
                                          ),
                                        )
                                            .then((onValue) {
                                          if (onValue == true) {
                                            getUser(context);
                                          }
                                        });
                                      },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                                              "Edit",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Shop Image
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: ClipOval(
                      child: Image.network(
                        dataNew?.vendorDetails![0].displayPicture ?? "",
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.store,
                            size: 50,
                            color: Colors.green,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Details
                _buildDetailRow("Shop Name", dataNew?.vendorDetails![0].displayName ?? ""),
                _buildDetailRow("Email", dataNew?.vendorDetails![0].officialEmail ?? "N/A"),
                _buildDetailRow("Mobile", dataNew?.vendorDetails![0].mobile ?? ""),
                if (dataNew?.vendorDetails![0].openTime != "" && dataNew?.vendorDetails![0].openTime != null)
                  _buildDetailRow("Shop Hours", 
                      "${CommonWidget.convertToLocalTimeWithAMPM(dataNew?.vendorDetails![0].openTime ?? "")} - ${CommonWidget.convertToLocalTimeWithAMPM(dataNew?.vendorDetails![0].closeTime ?? "")}"),
                _buildDetailRow("Location", dataNew?.vendorDetails![0].location!.name ?? ""),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddShopCard() {
    return Container(
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.1),
                  Colors.orange.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.add_business,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Add Your Shop",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.store,
                    size: 48,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "No Shop Added Yet",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Add your shop details to start offering services and manage your business.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                              Navigator.of(context)
                                  .push(
                                MaterialPageRoute(
                        builder: (context) => const RegistorVendorActivitySimple(),
                                ),
                              )
                                  .then((onValue) {
                                if (onValue == true) {
                                  getUser(context);
                                }
                              });
                            },
                  icon: const Icon(Icons.add_business),
                  label: const Text("Add Shop"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.1),
                  Colors.red.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.settings,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  "Account Settings",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: InkWell(
                          onTap: () {
                _showDeleteAccountDialog(context);
                          },
                          child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Delete Account",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.red.withOpacity(0.6),
                      size: 16,
                    ),
                    ],
                  ),
                ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            "Logout",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to logout?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: ColorClass.base_color,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                sharedPreferences!.clear();
                CommonWidget.navigateToKillAllScreen(
                    context, LoginActivity("Login"));
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            "Delete Account",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                deleteAccount();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  getRowDetails(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CommonWidget.getTextWidget500(title, size: 14),
        CommonWidget.getTextWidget400(value, 14)
      ],
    );
  }

  deleteAccount() async {
    var response = await dataManager!.deleteAccount(context);
    var data = CommonBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      CommonWidget.navigateToKillAllScreen(context, LoginActivity("Login"));
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  getUser(BuildContext context) async {
    var response = await dataManager!.getUserDetails(context);
    var data = VendorDetailBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      if (data.data!.isNotEmpty) {
        setState(() {
          dataNew = data.data![0];
        });
        sharedPreferences!
            .setString(Constant.firstName, data.data?[0].firstName ?? "");
        sharedPreferences!
            .setString(Constant.lastName, data.data?[0].lastName ?? "");
        sharedPreferences!.setString(Constant.email, data.data?[0].email ?? "");
        sharedPreferences!
            .setString(Constant.mobile, data.data?[0].mobile ?? "");
        sharedPreferences!.setString(
            Constant.isNewUser, data.data?[0].isNewUser.toString() ?? "");
        sharedPreferences!
            .setString(Constant.roleName, data.data?[0].roleName ?? "");
        sharedPreferences!
            .setString(Constant.id, data.data?[0].sId.toString() ?? "");
        if (data.data![0].vendorDetails!.isNotEmpty) {
          sharedPreferences!.setString(Constant.vendorId,
              data.data?[0].vendorDetails![0].sId.toString() ?? "");
        }
      }
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
}