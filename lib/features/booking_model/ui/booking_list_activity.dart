import 'dart:convert';

import 'package:car_app/Common/CommonWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Common/Color.dart';
import '../../../Common/ContainerDecoration.dart';
import '../data_model/booking_data_manager.dart';
import '../data_model/booking_list_bean.dart';
import '../model/complete_model_bean.dart';

class BookingListActivity extends StatefulWidget {
  const BookingListActivity({super.key});

  @override
  State<BookingListActivity> createState() => _BookingListActivityState();
}

class _BookingListActivityState extends State<BookingListActivity> {
  BookingDataManager? dataManager;
  SharedPreferences? sharedPreferences;
  List<Records> records = [];
  var filterType = "Completed";
  TextEditingController reasone = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = BookingDataManager(sharedPreferences!);
    DateTime dateTime = DateTime.now();
    print("dateTime.timeZoneName------${dateTime.timeZoneName}");
    print("dateTime.timeZoneOffset------${dateTime.timeZoneOffset}");
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    print(currentTimeZone);
    //getBookingList(context);
    getBookingListFilter(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CommonWidget.gettopbar("Booking", context),
          Container(
            margin: EdgeInsets.only(top: 10, right: 15, left: 15, bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        filterType = "Completed";
                        getBookingListFilter(context);
                      });
                    },
                    child: CommonWidget.getButtonWidget(
                        height: 30,
                        "Completed",
                        filterType == "Completed"
                            ? ColorClass.base_color
                            : Colors.white,
                        ColorClass.base_color,
                        textcolor: filterType == "Completed"
                            ? Colors.white
                            : ColorClass.base_color),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        filterType = "Pending";
                        getBookingListFilter(context);
                      });
                    },
                    child: CommonWidget.getButtonWidget(
                        height: 30,
                        "Pending",
                        filterType == "Pending"
                            ? ColorClass.base_color
                            : Colors.white,
                        ColorClass.base_color,
                        textcolor: filterType == "Pending"
                            ? Colors.white
                            : ColorClass.base_color),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        filterType = "Cancelled";
                        getBookingListFilter(context);
                      });
                    },
                    child: CommonWidget.getButtonWidget(
                        height: 30,
                        "Cancelled",
                        filterType == "Cancelled"
                            ? ColorClass.base_color
                            : Colors.white,
                        ColorClass.base_color,
                        textcolor: filterType == "Cancelled"
                            ? Colors.white
                            : ColorClass.base_color),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: records.length,
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    var data = records[index];
                    return GestureDetector(
                      onTap: () {
                        //CommonWidget.navigateToScreen(context, SpecialistsActivity(data.sId.toString()));
                      },
                      child: Container(
                          margin: EdgeInsets.fromLTRB(15, 5, 15, 5),
                          padding: EdgeInsets.all(10),
                          decoration: ContainerDecoration
                              .getboderwithshadowfillcolorblueE7F0FF(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipOval(
                                    child: Image.network(
                                      data.createdByImage ?? "",
                                      height: 60,
                                      width: 60,
                                      filterQuality: FilterQuality.low,
                                      fit: BoxFit.cover,
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
                                          "${data.createdByFirstName ?? " "} ${data.createdByLastName ?? " "}",
                                          color: ColorClass.base_color,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CommonWidget.getTextRich(
                                                  "Slot : ",
                                                  "${CommonWidget.convertToLocalTime(data.timeSlot ?? " ")}",
                                                ),
                                                CommonWidget.getTextRich(
                                                  "Price : ",
                                                  "${data.price ?? " "}",
                                                ),
                                                CommonWidget.getTextRich(
                                                  "Date : ",
                                                  "${DateFormat('dd-MM-yyyy').format(DateTime.parse(data.date ?? ""))}",
                                                ),
                                              ],
                                            ),
                                            InkWell(
                                              onTap: () {
                                                try {
                                                  final Uri emailLaunchUri =
                                                      Uri(
                                                    scheme: 'tel',
                                                    path: data.createdByMobile,
                                                  );
                                                  launchUrl(emailLaunchUri);
                                                } catch (e) {
                                                  print(e);
                                                }
                                              },
                                              child: Container(
                                                  height: 35,
                                                  width: 35,
                                                  padding: EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      color: ColorClass
                                                          .base_color),
                                                  child: Icon(
                                                    Icons.call,
                                                    color: Colors.white,
                                                    size: 25,
                                                  )),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
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
                                            height: 30),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
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
                                            height: 30),
                                      ),
                                    )
                                  ],
                                ),

                              if (data.orderStatus == "Cancelled" && data.cancelledBy != "" &&
                                  data.cancelledBy != null)
                                CommonWidget.getTextRich(
                                    "Cancelled By : ","${data.cancelledBy ?? " "}"),
                              if (data.orderStatus == "Cancelled" &&
                                  data.commentByUser != "" &&
                                  data.commentByUser != null)
                                CommonWidget.getTextRich(
                                    "Remark : ", "${data.commentByUser ?? " "}"),
                              if (data.orderStatus == "Cancelled" &&
                                  data.commentByVendor != "" &&
                                  data.commentByVendor != null)
                                CommonWidget.getTextRich(
                                    "Remark : ", "${data.commentByVendor ?? " "}"),
                            ],
                          )),
                    );
                  }))
        ],
      ),
    );
  }

  getBookingList(BuildContext context) async {
    var response = await dataManager!.getBookingList(context);
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

  getBookingListFilter(BuildContext context) async {
    var response = await dataManager!.getBookingListFilter(context, filterType);
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

  putStatusCompleted(BuildContext context, Records datas) async {
    var response = await dataManager!.putStatusCompleted(context, datas.sId.toString());
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

  showDetailPopUp(
    BuildContext context,
    Records data,
  ) {
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
                      image: AssetImage("assets/images/cross.png"),
                      height: 25,
                      width: 25,
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 25, right: 25),
                      width: double.infinity,
                      child: Text(
                        "Reason For Cancel", // ?? "",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: ColorClass.base_color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                        margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: Divider(
                          height: 3,
                          color: Color(0xffdedede),
                        )),
                    Container(
                        margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: Column(
                          children: [
                            CommonWidget.getTextWidgetPopReg(
                                "You will not be able to undo this process once continue! Are you want to cancel this booking request?",
                                textsize: 12),
                            Container(
                              margin: EdgeInsets.only(top: 10, bottom: 10),
                              height: 120,
                              child: TextField(
                                controller: reasone,
                                maxLines: 5,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: "Krub500",
                                    fontSize: 16),
                                decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)),
                                        borderSide: BorderSide(
                                            color: ColorClass.light_browne,
                                            width: 1,
                                            style: BorderStyle.solid)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)),
                                        borderSide: BorderSide(
                                            color: ColorClass.light_browne,
                                            width: 1,
                                            style: BorderStyle.solid)),
                                    contentPadding:
                                        EdgeInsets.fromLTRB(10, 10, 10, 10),
                                    filled: true,
                                    fillColor: Colors.green[50],
                                    hintText: "Enter Reason....",
                                    hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)),
                                        borderSide: BorderSide(
                                            color: ColorClass.light_browne))),
                                //controller: userid,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                      margin: EdgeInsets.only(right: 5),
                                      child: CommonWidget.getButtonWidget(
                                          "No",
                                          Colors.green[300]!,
                                          Colors.green[300]!)),
                                )),
                                Expanded(
                                    child: GestureDetector(
                                  onTap: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    //FocusManager.instance.primaryFocus?.unfocus();
                                    Navigator.pop(context);
                                    putStatusCancel(context, data);
                                  },
                                  child: Container(
                                      margin: EdgeInsets.only(left: 5),
                                      child: CommonWidget.getButtonWidget("Yes",
                                          Colors.red[400]!, Colors.red[400]!)),
                                ))
                              ],
                            )
                          ],
                        )),
                  ],
                ),
              ),
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
}
