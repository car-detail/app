import 'dart:convert';

import 'package:car_app/Common/BaseActivity.dart';
import 'package:car_app/features/booking_model/model/booking_model_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Common/Color.dart';
import '../../../Common/CommonPopUp.dart';
import '../../../Common/CommonWidget.dart';
import '../../home_module/model/services_model_data.dart';
import '../../specialists_module/data_manager/specialists_data_manager.dart';
import '../../specialists_module/model/services_details_model_data.dart';
import '../data_model/booking_data_manager.dart';

class BookingActivity extends StatefulWidget {
  ServicesData servicesData;

  BookingActivity(this.servicesData, {super.key});

  @override
  State<BookingActivity> createState() => _BookingActivityState();
}

class _BookingActivityState extends State<BookingActivity> {
  BookingDataManager? dataManager;
  SharedPreferences? sharedPreferences;
  BookingModelData bookingdata = BookingModelData(detailImages: []);
  List<String> detailImages = [];
  var isPickUp = false;
  var timeController = TextEditingController();
  var dateController = TextEditingController();
  var dateString = "";
  var timeString = "";
  var messageController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = BookingDataManager(sharedPreferences!);
    getServicesDetails(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 250,
            child: Stack(
              children: [
                if (bookingdata.coverImage != "" &&
                    bookingdata.coverImage != null)
                  Image.network(
                    bookingdata.coverImage ?? "",
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                Container(
                  margin: EdgeInsets.only(top: 45, left: 10, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Image.asset(
                          CommonWidget.getImagePath("backspace.png"),
                          height: 40,
                          width: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: Container(
            margin: EdgeInsets.all(15),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                          child: CommonWidget.getTextWidget300(
                              bookingdata.categoryName ?? "", 14,
                              color: ColorClass.base_color),
                          padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                          decoration: BoxDecoration(
                              color: Color(0xff1CB2731A),
                              borderRadius: BorderRadius.circular(20))),
                      Row(
                        children: [
                          Image.asset(
                            CommonWidget.getImagePath("stars1.png"),
                            height: 20,
                            width: 20,
                          ),
                          CommonWidget.getTextWidget300(" 4.8 (568 views)", 14)
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  CommonWidget.getTextWidget500(bookingdata.serviceTitle ?? "",
                      size: 18),
                  CommonWidget.getTextWidget300(
                      bookingdata.location?.name ?? "", 14,
                      color: ColorClass.dark_gray_base),
                  SizedBox(
                    height: 5,
                  ),
                  CommonWidget.getTextWidget500("Book A Slot",
                      color: ColorClass.base_color),
                  SizedBox(
                    height: 5,
                  ),
                  CommonWidget.getTextWidget300("Service Type", 14),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    children: [
                      /*InkWell(
                        onTap: () {
                          setState(() {
                            isPickUp = true;
                          });
                        },
                        child: CommonWidget.getButtonWidget("Pick Up",
                            getColorPickColor(), ColorClass.base_color,
                            textcolor: isPickUp == true
                                ? Colors.white
                                : ColorClass.base_color),
                      ),*/
                      /*SizedBox(
                        width: 5,
                      ),*/
                      InkWell(
                        onTap: () {
                          setState(() {
                            isPickUp = false;
                          });
                        },
                        child: CommonWidget.getButtonWidget("Self Service",
                            getColorSelfColor(), ColorClass.base_color,
                            textcolor: isPickUp == true
                                ? ColorClass.base_color
                                : Colors.white),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  CommonWidget.getTextWidget300("Service Type", 14),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              isPickUp = true;
                            });
                          },
                          child: CommonWidget
                              .getTextFieldWithgrayboderandclickable(
                                  "Date", dateController, () {
                            CommonPopUp.showdateNewDialog(context, (date) {
                              String formattedDate =
                                  DateFormat('dd-MM-yyyy').format(date);
                              print(formattedDate);
                              setState(() {
                                dateController.text = formattedDate;
                                dateString =
                                    DateFormat('dd-MM-yyyy').format(date);
                              });
                            }, DateTime.now(), DateTime.now(), DateTime(2050));
                          }, "clander"),
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              isPickUp = false;
                            });
                          },
                          child: CommonWidget
                              .getTextFieldWithgrayboderandclickable(
                                  "Time", timeController, () {
                            CommonPopUp.showTimeDialog(context, (time) {
                              timeController.text =
                                  time.format(context).toString();
                            });
                          }, "clock"),
                        ),
                      )
                    ],
                  ),
                  CommonWidget.getTextWidget300(
                      "Estimate service time will be 1hr 50mins.", 12),
                  SizedBox(
                    height: 10,
                  ),
                  CommonWidget.getTextWidget500("Note for Service Provider"),
                  CommonWidget.getTextFieldWithgrayboder("Enter the instructions", messageController)
                ],
              ),
            ),
          )),
          Container(
              margin: EdgeInsets.fromLTRB(15, 0, 15, 25),
              child: CommonWidget.getButtonWidget(
                  "Continue", ColorClass.base_color, ColorClass.base_color,
                  textcolor: Colors.white))
        ],
      ),
    );
  }

  getServicesDetails(BuildContext context) async {
    var response = await dataManager!
        .getServiceDetails(context, widget.servicesData.sId.toString());
    var data = BookingModelBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        bookingdata = data.data!;
        detailImages.clear();
        detailImages.addAll(data.data!.detailImages);
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  getColorPickColor() {
    if (isPickUp) {
      return ColorClass.base_color;
    } else {
      return ColorClass.base_light_color;
    }
  }

  getColorSelfColor() {
    if (isPickUp) {
      return ColorClass.base_light_color;
    } else {
      return ColorClass.base_color;
    }
  }
}
