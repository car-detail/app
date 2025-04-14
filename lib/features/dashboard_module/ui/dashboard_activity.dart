import 'dart:convert';

import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/features/dashboard_module/model/vendor_details_main_bean.dart';
import 'package:car_app/features/home_module/ui/home_activity.dart';
import 'package:car_app/features/log_in/ui/edit_user_details_activity.dart';
import 'package:car_app/features/log_in/ui/profile_activity.dart';
import 'package:car_app/features/offer_model/ui/offer_screen.dart';
import 'package:car_app/features/resister_vendor_model/ui/edit_vendor_activity.dart';
import 'package:car_app/features/services_model/ui/add_services_activity.dart';
import 'package:car_app/features/services_model/ui/services_list_activity.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Common/Color.dart';
import '../../../Common/CommonBean.dart';
import '../../../Common/Constant.dart';
import '../../explore_module/ui/explore_list_activity.dart';
import '../../home_module/data_manager/home_data_manager.dart';
import '../../offer_model/ui/offer_list_screen.dart';
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
      ServicesListActivity(),
      OfferListScreen("Main"),
      ProfileVendorListActivity(),
    ]);
    start();
    super.initState();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = HomeDataManager(sharedPreferences!);
    if (sharedPreferences!.getString(Constant.vendorId) != "" &&
        sharedPreferences!.getString(Constant.vendorId) != null)
    getdetails(context);
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
    var response = await dataManager!.getdetails(context);
    var data = VendorDetailsMainBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        isValid = data.data!.isShopOpen!;
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isValid
          ? _pageNo[selectedpage]
          : Container(
              child: Column(
                children: [
                  CommonWidget.gettopbar("Store Status", context,
                      isBack: false),
                  Expanded(
                      child: Container(
                    margin: EdgeInsets.all(15),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CommonWidget.getTextWidgetPopbold(
                            "Your Store is now Offline, Do you want to make it Online?"),
                        SizedBox(
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
      bottomNavigationBar: isValid
          ? ConvexAppBar(
              backgroundColor: ColorClass.base_color,
              color: Colors.white,
              items: const [
                TabItem(icon: Icons.home, title: 'Home'),
                TabItem(icon: Icons.design_services, title: 'Serves'),
                TabItem(icon: Icons.local_offer_outlined, title: 'Offers'),
                //TabItem(icon: Icons.chat, title: 'Chat'),
                TabItem(icon: Icons.supervised_user_circle, title: 'Profile'),
              ],
              initialActiveIndex: selectedpage,
              onTap: (int i) => setState(() {
                selectedpage = i;
              }),
            )
          : null,
    );
  }
}
