import 'dart:convert';

import 'package:car_app/Common/CommonBean.dart';
import 'package:car_app/features/offer_model/data_manager/offer_data_manager.dart';
import 'package:car_app/features/offer_model/ui/offer_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonPopUp.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../../../Common/ContainerDecoration.dart';
import '../../resister_vendor_model/ui/registor_vendor_activity.dart';
import '../model/offer_list_model_bean.dart';

class OfferListScreen extends StatefulWidget {
  String value;
  OfferListScreen(this.value, {super.key});

  @override
  State<OfferListScreen> createState() => _OfferListScreenState();
}

class _OfferListScreenState extends State<OfferListScreen> {
  ApiFuntions apiFuntions = ApiFuntions();
  OfferDataManager? servicesDataManager;
  SharedPreferences? sharedPreferences;
  List<OfferListModelData> offerListData = [];
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
    servicesDataManager = OfferDataManager(sharedPreferences!);
    setState(() {
      venderId = sharedPreferences!.getString(Constant.vendorId) ?? "";
    });
    if (venderId != "") getCategory(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            CommonWidget.gettopbar("Offers", context, isBack: widget.value == "Home"?true:false),
            if (venderId != "")
              Expanded(
                  child: offerListData.length > 0
                      ? ListView.builder(
                          itemCount: offerListData.length,
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            var data = offerListData[index];
                            return GestureDetector(
                              onTap: () {
                                /*CommonWidget.navigateToScreen(context,
                                SpecialistsActivity(data.sId.toString()));*/
                              },
                              child: Container(
                                  margin: EdgeInsets.fromLTRB(15, 5, 15, 5),
                                  padding: EdgeInsets.all(10),
                                  decoration: ContainerDecoration
                                      .getboderwithshadowfillcolorblueE7F0FF(
                                    colorbg: data.isCurrentlyActive
                                        ? 0xffF8FCFF
                                        : 0xFFEEEEEE,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ClipOval(
                                            child: Image.network(
                                              data.image ?? "",
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
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Expanded(
                                              child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CommonWidget.getTextWidgetPopSemi(
                                                  data.service?.serviceTitle
                                                          .toString() ??
                                                      "",
                                                  color: ColorClass.base_color),
                                              CommonWidget.getTextWidgetPopSemi(
                                                  data.title ?? ""),
                                              CommonWidget.getTextWidgetPopReg(
                                                  "Discount : ${data.discount ?? ""}%"),
                                            ],
                                          ))
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      CommonWidget.getTextWidgetPopReg(
                                          data.description ?? "",
                                          textAlign: TextAlign.start),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CommonWidget.getTextWidgetPopReg(
                                                "${CommonWidget.getDateFormat(data.validFrom!)}-${CommonWidget.getDateFormat(data.validUntil!)}",
                                                color: Colors.grey[500]!,
                                                textAlign: TextAlign.start),
                                          ),
                                          SizedBox(
                                            height: 20,
                                            child: Switch(
                                                activeColor:
                                                    ColorClass.base_color,
                                                inactiveThumbColor: Colors.red,
                                                inactiveTrackColor:
                                                    Colors.red[100],
                                                value: data.isCurrentlyActive,
                                                onChanged: (onChanged) {
                                                  if (onChanged) {
                                                    postOfferUpdate(context,
                                                        data.sId.toString());
                                                  } else {
                                                    postOfferUpdate(context,
                                                        data.sId.toString());
                                                  }
                                                }),
                                          ),
                                          InkWell(
                                              onTap: () {
                                                CommonPopUp.showalertDialog(
                                                    context,
                                                    "",
                                                    "Are you sure - You want to delete offer permanently?",
                                                    "No",
                                                    "Yes",
                                                    "info",
                                                        () => Navigator.pop(context), () async {
                                                  Navigator.pop(context);
                                                  deleteOffer(context, data.sId.toString());
                                                }, 195,
                                                    positivetitlecolorButton: ColorClass.red,
                                                    navtextColorButton: ColorClass.green,
                                                    isboldtitle: false);
                                                //deleteOffer(context, data.sId.toString());
                                              },
                                              child: Icon(
                                                Icons.delete_forever,
                                                size: 30,
                                                color: Colors.red[400],
                                              ))
                                        ],
                                      ),
                                    ],
                                  )),
                            );
                          })
                      : Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, color: ColorClass.base_color, size: 24),
                          SizedBox(width: 8),
                          Expanded(
                            child: CommonWidget.getTextWidgetTitle(
                              "No offers yet! Tap the '+' button below to create an exciting deal and attract more bookings.",
                              color: Colors.black87,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),

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
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(
                      builder: (context) => OfferScreen(),
                    ),
                  )
                      .then((onValue) {
                    if (onValue == true && venderId != "") getCategory(context);
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
    var response = await servicesDataManager!.getOfferList(context);
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

  postOfferUpdate(BuildContext context, String id) async {
    var response = await servicesDataManager!.postOfferUpdate(context, id);
    var data = CommonBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      getCategory(context);
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
  deleteOffer(BuildContext context, String id) async {
    var response = await servicesDataManager!.deleteOffer(context, id);
    var data = CommonBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      getCategory(context);
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
}
