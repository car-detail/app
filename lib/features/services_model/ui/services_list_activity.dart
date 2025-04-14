import 'dart:convert';

import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/ContainerDecoration.dart';
import 'package:car_app/features/services_model/ui/add_services_activity.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Color.dart';
import '../../../Common/Constant.dart';
import '../../resister_vendor_model/ui/registor_vendor_activity.dart';
import '../../specialists_module/ui/specialists_activity.dart';
import '../data_manager/services_data_manager.dart';
import '../model/services_list_bean.dart';

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
    if (venderId != "")
      getCategory(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            CommonWidget.gettopbar("Services", context, isBack: false),
            if (venderId != "")
              Expanded(
                  child: servicesData.length > 0
                      ? ListView.builder(
                          itemCount: servicesData.length,
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            var data = servicesData[index];
                            return GestureDetector(
                              onTap: () {
                                CommonWidget.navigateToScreen(context,
                                    SpecialistsActivity(data.sId.toString()));
                              },
                              child: Container(
                                  margin: EdgeInsets.fromLTRB(15, 5, 15, 5),
                                  padding: EdgeInsets.all(10),
                                  decoration: ContainerDecoration
                                      .getboderwithshadowfillcolorblueE7F0FF(),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ClipOval(
                                            child: Image.network(
                                              data.coverImage ?? "",
                                              height: 60,
                                              width: 60,
                                              filterQuality: FilterQuality.low,
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
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CommonWidget.getTextWidgetTitle(
                                                  data.serviceTitle ?? "",
                                                  color: ColorClass.base_color,
                                                ),
                                                CommonWidget.getTextRich(
                                                    "", data.about ?? "",
                                                    maxLine: 2, textsize: 12)
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                              child: CommonWidget.getTextRich(
                                                  "Capacity : ",
                                                  data.timeSlotCapacity ?? "")),
                                          Expanded(
                                              child: CommonWidget.getTextRich(
                                                  "Duration : ",
                                                  data.serviceDuration ?? "")),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                              child: CommonWidget.getTextRich(
                                                  "Price : ",
                                                  data.price.toString() ?? "")),
                                          Expanded(
                                              child: CommonWidget.getTextRich(
                                                  "Category : ",
                                                  data.categoryName ?? "")),
                                        ],
                                      ),
                                      CommonWidget.getTextRich("Mobile : ",
                                          data.mobile.toString() ?? ""),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 20,
                                          ),
                                          CommonWidget.getTextWidget300(
                                              data.location!.name.toString(),
                                              12)
                                        ],
                                      ),
                                      SizedBox(height: 5,),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if(data.averageRating != null && data.averageRating != 0)
                                            Row(
                                              children: [
                                                Image.asset(
                                                  CommonWidget.getImagePath("stars1.png"),
                                                  height: 20,
                                                  width: 20,
                                                ),
                                                CommonWidget.getTextWidget300(
                                                    " ${data.averageRating.toString() ?? ""} (${data.totalReviews.toString() ?? ""} views)",
                                                    14)
                                              ],
                                            ),
                                          if(data.offers.length >0)
                                            CommonWidget.getButtonWidget("Offer Applied", Colors.orange[300]!, Colors.orange[300]!, height: 30, size: 12),

                                        ],
                                      ),

                                    ],
                                  )),
                            );
                          })
                      : Center(
                          child: CommonWidget.getTextWidgetTitle(
                              "Add your first service by clicking on the '+' button below."),
                        ))
            else
              Expanded(
                  child: Container(
                margin: EdgeInsets.all(15),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CommonWidget.getTextWidget500(
                          "You Need to Add your shop first."),
                      SizedBox(
                        height: 10,
                      ),
                      InkWell(
                        onTap: () {
                          CommonWidget.navigateToScreen(
                              context, RegistorVendorActivity());
                        },
                        child: CommonWidget.getButtonWidget("Add Shop",
                            ColorClass.base_color, ColorClass.base_color,
                            height: 30),
                      )
                    ]),
              ))
          ],
        ),
        floatingActionButton: venderId != "null"
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddServicesActivity(),
                    ),
                  ).then((onValue){
                    if(onValue == true && venderId != "")
                    getCategory(context);
                  });
                },
                backgroundColor: ColorClass.base_color,
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                )) // Hides the FAB
            : null);
  }

  getCategory(BuildContext context) async {
    var response = await servicesDataManager!.getServicesList(context);
    var data = ServicesListBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        servicesData.clear();
        servicesData.addAll(data.data!);
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
}
