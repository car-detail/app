import 'dart:convert';
import 'dart:ffi';

import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonBean.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/categories_module/ui/categories_list_activity.dart';
import 'package:car_app/features/home_module/data_manager/home_data_manager.dart';
import 'package:car_app/features/offer_model/ui/offer_list_screen.dart';
import 'package:car_app/features/specialists_module/ui/specialists_activity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Common/CommonPopUp.dart';
import '../../../Common/ContainerDecoration.dart';
import '../../booking_model/data_model/booking_list_bean.dart';
import '../../booking_model/model/complete_model_bean.dart';
import '../../dashboard_module/model/vendor_details_main_bean.dart';
import '../../notification_model/ui/notification_activity.dart';
import '../../offer_model/model/offer_list_model_bean.dart';
import '../model/category_model_data.dart';
import '../model/services_model_data.dart';

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
  var vendorId = "";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = HomeDataManager(sharedPreferences!);
    //getCategory(context);
    //getServices(context);
    setState(() {
      vendorId = sharedPreferences!.getString(Constant.vendorId)??"";
    });

    if (sharedPreferences!.getString(Constant.vendorId) != "" &&
        sharedPreferences!.getString(Constant.vendorId) != null) {
      getBookingListFilter(context);
      getoffer(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(top: 45, bottom: 10),
            color: ColorClass.base_color,
            child: Row(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 10),
                  height: 10,
                  width: 10,
                ),
                Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                        CommonWidget.getTextWidget500(
                            sharedPreferences?.getString(Constant.location) ??
                                "",
                            color: Colors.white),
                      ],
                    )),
                GestureDetector(
                  onTap: () {
                    CommonWidget.navigateToScreen(
                        context, NotificationActivity());
                  },
                  child: Container(
                      margin: EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 30,
                      )),
                )
              ],
            ),
          ),
          if (vendorId != "")
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Your Store is Online",
                          style: TextStyle(
                            fontFamily: "PopSemi",
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Do you want to make it Offline?",
                          style: TextStyle(
                            fontFamily: "PopSemi",
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    activeColor: ColorClass.base_color,
                    inactiveThumbColor: Colors.red,
                    inactiveTrackColor: Colors.red[100],
                    value: true,
                    onChanged: (val) {
                      CommonPopUp.showalertDialog(
                        context,
                        "",
                        "Are you sure you want to make the store offline?",
                        "No",
                        "Yes",
                        "offline",
                            () => Navigator.pop(context),
                            () async {
                          Navigator.pop(context);
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

          Container(
            margin: EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if(offerListData.length > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CommonWidget.getTextWidget500("Offers"),
                      GestureDetector(
                        onTap: () {
                          CommonWidget.navigateToScreen(
                              context, OfferListScreen("Home"));
                        },
                        child: CommonWidget.getTextWidget300("See All", 14,
                            color: ColorClass.base_color),
                      )
                    ],
                  ),
                if(offerListData.length > 0)
                  SizedBox(
                    height: 5,
                  ),
                if(offerListData.length > 0)
                  Container(
                    height: 150,
                    child: ListView.builder(
                        itemCount: offerListData.length,
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              CommonWidget.navigateToScreen(
                                  context,
                                  SpecialistsActivity(
                                      offerListData[index].service?.id
                                          .toString() ?? ""));
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: 10),
                              width: 280,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                      child: Image.network(
                                        offerListData[index].image ?? "",
                                        height: 150,
                                        fit: BoxFit.fill,
                                        width: 270, errorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/chat_profile.png',
                                          fit: BoxFit.cover,
                                          height: 60,
                                          width: 60,
                                        );
                                      },
                                      )),
                                  Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Container(
                                          margin: EdgeInsets.fromLTRB(
                                              0, 0, 0, 0),
                                          child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.end,
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                color:
                                                Colors.black.withOpacity(0.5),
                                                margin:
                                                EdgeInsets.only(right: 10),
                                                padding: EdgeInsets.only(
                                                  left: 5,
                                                  right: 5,
                                                ),
                                                child: CommonWidget
                                                    .getTextWidget500(
                                                    "Get ${offerListData[index]
                                                        .discount}% off",
                                                    size: 14,
                                                    color: Colors.white,
                                                    textAlign: TextAlign.start),
                                              ),
                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.5),
                                                    borderRadius:
                                                    const BorderRadius.only(
                                                      bottomRight:
                                                      Radius.circular(15),
                                                      bottomLeft:
                                                      Radius.circular(15),
                                                    )),
                                                margin:
                                                const EdgeInsets.only(
                                                    right: 10),
                                                padding: const EdgeInsets.only(
                                                    right: 5,
                                                    left: 5,
                                                    bottom: 5),
                                                child: Text(
                                                  maxLines: 2,
                                                  offerListData[index]
                                                      .description ??
                                                      "",
                                                  style: const TextStyle(
                                                    fontFamily: "Pop500",
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.start,
                                                  overflow: TextOverflow
                                                      .ellipsis,
                                                ),
                                              ),
                                            ],
                                          ))),
                                ],
                              ),
                            ),
                          );
                        }),
                  ),
              ],
            ),
          ),
          if (records.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: CommonWidget.getTextWidget500("Current Bookings"),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: records.length,
                padding: const EdgeInsets.only(bottom: 16),
                itemBuilder: (context, index) {
                  final data = records[index];

                  return GestureDetector(
                    onTap: () {
                      // CommonWidget.navigateToScreen(context, SpecialistsActivity(data.sId.toString()));
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  data.createdByImage ?? "",
                                  height: 80,
                                  width: 60,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.low,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 80,
                                    width: 60,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.person, color: Colors.grey[600]),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CommonWidget.getTextWidgetTitle(
                                      "${data.createdByFirstName ?? ""} ${data.createdByLastName ?? ""}",
                                      color: Colors.green.shade900, // Darker shade of green
                                      textsize: 15,                 // Slightly bigger
                                      textAlign: TextAlign.start,   // Better alignment for labels
                                    ),
                                    const SizedBox(height: 3), // Adds spacing between each row
                                    // Slot with compact UI
                                    CommonWidget.getTextRich(
                                      "Slot: ",
                                      CommonWidget.convertToLocalTime(data.timeSlot ?? ""),
                                      titlecolor: Colors.black,
                                      valuecolor: Colors.green.shade600,
                                      textsize: 12, // Reduced font size
                                    ),

// Price with compact UI
                                    CommonWidget.getTextRich(
                                      "Price: ",
                                      "${data.price ?? "-"}",
                                      titlecolor: Colors.black,
                                      valuecolor: Colors.green.shade600,
                                      textsize: 12, // Consistent small font
                                    ),

// Date with compact UI
                                    CommonWidget.getTextRich(
                                      "Date: ",
                                      DateFormat('dd-MM-yyyy').format(DateTime.parse(data.date ?? "")),
                                      titlecolor: Colors.black,
                                      valuecolor: Colors.green.shade600,
                                      textsize: 12, // Reduced font size
                                    ),

                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () {
                                  try {
                                    final Uri phoneUri = Uri(
                                      scheme: 'tel',
                                      path: data.createdByMobile,
                                    );
                                    launchUrl(phoneUri);
                                  } catch (e) {
                                    print(e);
                                  }
                                },
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ColorClass.base_color,
                                  ),
                                  child: const Icon(Icons.call, color: Colors.white, size: 22),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (data.orderStatus == "Pending")
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      putStatusCompleted(context, data);
                                    },
                                    child: CommonWidget.getButtonWidget(
                                      "Completed",
                                      ColorClass.base_color,
                                      ColorClass.base_color,
                                      height: 36,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      showDetailPopUp(context, data);
                                    },
                                    child: CommonWidget.getButtonWidget(
                                      "Cancel",
                                      Colors.white,
                                      ColorClass.base_color,
                                      textcolor: ColorClass.base_color,
                                      height: 36,
                                    ),
                                  ),
                                ),
                              ],
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else if (offerListData.isEmpty && records.isEmpty) ...[
            Expanded(
              child: Center(
                child: CommonWidget.getTextWidgetPopSemi(
                  "Pro Tip: Boost your chances of getting bookings by running attractive offers!",
                  size: 13,
                  color: Colors.grey[700]!,
                ),
              ),

            )
          ]

        ],
      ),
    );
  }

  putStatusCompleted(BuildContext context, Records datas) async {
    var response = await dataManager!.putStatusCompleted(
        context, datas.sId.toString());
    var data = CompletedModelBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      getBookingListFilter(context);
    }
  }

  putStatusCancel(BuildContext context, Records datas) async {
    var response = await dataManager!
        .putStatusCancel(context, reasone.text, datas.sId.toString());
    var data = CompletedModelBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      reasone.text = "";
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      getBookingListFilter(context);
    }
  }

  showDetailPopUp(BuildContext context,
      Records data,) {
    AlertDialog alert = AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      content: Container(
          height: 330,
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.only(top: 10, right: 10),
                    child: Image(
                      image: AssetImage("assets/images/delete.png"),
                      height: 25,
                      width: 25,
                    ),
                  ),
                ),
              ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100], // Light modern background
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Reason for Cancel",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorClass.base_color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              Divider(color: Colors.grey[300], thickness: 1),
              SizedBox(height: 10),
              CommonWidget.getTextWidgetPopReg(
                "You will not be able to undo this process once continued.\nAre you sure you want to cancel this booking request?",
                textAlign: TextAlign.center,
                textsize: 12,
              ),
              SizedBox(height: 12),
              TextField(
                controller: reasone,
                maxLines: 4,
                keyboardType: TextInputType.text,
                style: TextStyle(
                  color: Colors.black87,
                  fontFamily: "Krub500",
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: "Enter reason...",
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  fillColor: Colors.grey[200], // soft background
                  filled: true,
                  contentPadding: EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: ColorClass.base_color, width: 1.5),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "No",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.pop(context);
                        putStatusCancel(context, data);
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: ColorClass.base_color, // Primary color of your app
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Yes",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        )
        ],
          )),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
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
    var response = await dataManager!.getAllServices(context);
    var data = ServicesModelData.fromJson(jsonDecode(response.body));
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

  getBookingListFilter(BuildContext context) async {
    var response = await dataManager!.getBookingListFilter(context, "Pending");
    var data = BookingListBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        records.clear();
        records.addAll(data.data!.records!);
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      setState(() {
        records.clear();
      });
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
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
  makeOffLine(BuildContext context) async {
    var response = await dataManager!.makeOffLine(context);
    var data = VendorDetailsMainBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      widget.offline(data.data!.isShopOpen!);
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
}
