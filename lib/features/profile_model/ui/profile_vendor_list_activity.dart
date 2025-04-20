import 'dart:convert';
import 'dart:io';

import 'package:car_app/Common/Color.dart';
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
import '../../resister_vendor_model/ui/registor_vendor_activity.dart';
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
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/login_image.png'),
              fit: BoxFit.cover)),
      child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: ContainerDecoration.getboderwithshadowfillcolorblueE7F0FF(borderRadius: 30),
                padding: EdgeInsets.all(8),
                height: 40,
                width: 40,
                margin: EdgeInsets.only(top: 45, right: 15),
                child: InkWell(
                  onTap: () {
                    CommonPopUp.showalertDialog(
                        context,
                        "",
                        "Are you sure - You want to logout?",
                        "No",
                        "Yes",
                        "info",
                            () => Navigator.pop(context), () async {
                      Navigator.pop(context);
                      sharedPreferences!.clear();
                      CommonWidget.navigateToKillAllScreen(context, LoginActivity("Login"));
                      //logout();
                    }, 190,
                        positivetitlecolorButton: ColorClass.red,
                        navtextColorButton: ColorClass.green,
                        isboldtitle: false);
                  },
                  child: Image.asset(
                    CommonWidget.getImagePath("log_out.png"),
                    height: 20,
                    width: 20,
                    color: ColorClass.base_color,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: Platform.isIOS
                      ? EdgeInsets.only(
                          top: 245,left: 20, right: 20
                        )
                      : EdgeInsets.only(
                          top: 165,left: 20, right: 20
                        ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (dataNew != null)
                          Container(
                            decoration: ContainerDecoration
                                .getboderwithshadowfillcolorblueE7F0FF(),
                            padding: EdgeInsets.all(15),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.topRight,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context)
                                          .push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProfileActivity(),
                                        ),
                                      )
                                          .then((onValue) {
                                        if (onValue == true) {
                                          getUser(context);
                                        }
                                      });
                                    },
                                    child: Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: ColorClass.base_color,
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    CommonWidget.getTextWidgetTitle(
                                        "Personal Details",
                                        color: ColorClass.base_color,
                                        textsize: 16),
                                    ClipOval(
                                      child: Image.network(
                                        dataNew?.image ?? "",
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/images/chat_profile.png',
                                            fit: BoxFit.cover,
                                            height: 60,
                                            width: 60,
                                          );
                                        },
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CommonWidget.getTextRich(
                                                  "First Name : ",
                                                  dataNew?.firstName ?? ""),
                                              CommonWidget.getTextRich(
                                                  "Last Name : ",
                                                  dataNew?.lastName ?? ""),
                                              CommonWidget.getTextRich(
                                                  "Email : ",
                                                  dataNew?.email ?? ""),
                                              CommonWidget.getTextRich(
                                                  "Mobile : ",
                                                  dataNew?.mobile ?? ""),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        SizedBox(
                          height: 10,
                        ),
                        if (dataNew != null &&
                            dataNew!.vendorDetails!.length > 0 &&
                            dataNew!.vendorDetails![0].sId != "")
                          Container(
                              decoration: ContainerDecoration
                                  .getboderwithshadowfillcolorblueE7F0FF(),
                              padding: EdgeInsets.all(15),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: InkWell(
                                      onTap: () {
                                        /*CommonWidget.navigateToScreen(
                                    context, EditVendorActivity());*/
                                        Navigator.of(context)
                                            .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditVendorActivity(),
                                          ),
                                        )
                                            .then((onValue) {
                                          if (onValue == true) {
                                            getUser(context);
                                          }
                                        });
                                      },
                                      child: Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: ColorClass.base_color,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      CommonWidget.getTextWidgetTitle(
                                          "Vendor Details",
                                          color: ColorClass.base_color,
                                          textsize: 16),
                                      ClipOval(
                                        child: Image.network(
                                          dataNew?.vendorDetails![0]
                                                  .displayPicture ??
                                              "",
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/images/chat_profile.png',
                                              fit: BoxFit.cover,
                                              height: 80,
                                              width: 80,
                                            );
                                          },
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CommonWidget.getTextRich(
                                                    "Shop Name : ",
                                                    dataNew?.vendorDetails![0]
                                                            .displayName ??
                                                        ""),
                                                CommonWidget.getTextRich(
                                                    "Email : ",
                                                    dataNew?.vendorDetails![0]
                                                            .officialEmail ??
                                                        ""),
                                                CommonWidget.getTextRich(
                                                    "Mobile : ",
                                                    dataNew?.vendorDetails![0]
                                                            .mobile ??
                                                        ""),
                                                if (dataNew?.vendorDetails![0]
                                                            .openTime !=
                                                        "" &&
                                                    dataNew?.vendorDetails![0]
                                                            .openTime !=
                                                        null)
                                                  CommonWidget.getTextRich(
                                                      "Shop Time : ",
                                                      "${CommonWidget.convertToLocalTimeWithAMPM(dataNew?.vendorDetails![0].openTime ?? "")}-${CommonWidget.convertToLocalTimeWithAMPM(dataNew?.vendorDetails![0].closeTime ?? "")}"),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .location_on_outlined,
                                                      size: 20,
                                                    ),
                                                    CommonWidget.getTextWidget300(
                                                        dataNew
                                                                ?.vendorDetails![
                                                                    0]
                                                                .location!
                                                                .name
                                                                .toString() ??
                                                            "",
                                                        12)
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ))
                        else
                          InkWell(
                              onTap: () {
                                Navigator.of(context)
                                    .push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RegistorVendorActivity(),
                                  ),
                                )
                                    .then((onValue) {
                                  if (onValue == true) {
                                    getUser(context);
                                  }
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(top: 15),
                                child: CommonWidget.getButtonWidget(
                                    "Add Shop",
                                    ColorClass.base_color,
                                    ColorClass.base_color,
                                    height: 30),
                              ))
                      ],
                    ),
                  ),
                ),
              )
            ],
          )),
    );
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
        /*sharedPreferences!.setString(Constant.isEmailVerified,
          data.data?[0].isEmailVerified.toString() ?? "");*/
        sharedPreferences!
            .setString(Constant.mobile, data.data?[0].mobile ?? "");
        sharedPreferences!.setString(
            Constant.isNewUser, data.data?[0].isNewUser.toString() ?? "");
        sharedPreferences!
            .setString(Constant.roleName, data.data?[0].roleName ?? "");
        sharedPreferences!
            .setString(Constant.id, data.data?[0].sId.toString() ?? "");
        if (data.data![0].vendorDetails!.isNotEmpty)
          sharedPreferences!.setString(Constant.vendorId,
              data.data?[0].vendorDetails![0].sId.toString() ?? "");
      }
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
}
