import 'dart:convert';

import 'package:car_app/Common/Color.dart';
import 'package:car_app/features/ZoomImageList.dart';
import 'package:car_app/features/booking_model/ui/booking_list_activity.dart';
import 'package:car_app/features/home_module/model/services_model_data.dart';
import 'package:car_app/features/specialists_module/ui/view_offer_list_via_detail.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Common/CommonWidget.dart';
import '../../booking_model/ui/booking_activity.dart';
import '../../rating_model/ui/rating_review_screen.dart';
import '../data_manager/specialists_data_manager.dart';
import '../model/services_details_model_data.dart';

class SpecialistsActivity extends StatefulWidget {
  String servicesData;

  SpecialistsActivity(this.servicesData, {super.key});

  @override
  State<SpecialistsActivity> createState() => _SpecialistsActivityState();
}

class _SpecialistsActivityState extends State<SpecialistsActivity> {
  SpecialistsDataManager? dataManager;
  SharedPreferences? sharedPreferences;
  ServicesDetailsData servicesDetailsData =
      ServicesDetailsData(detailImages: []);
  List<String> detailImages = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = SpecialistsDataManager(sharedPreferences!);
    getServicesDetails(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: Stack(
              children: [
                if (servicesDetailsData.coverImage != "" &&
                    servicesDetailsData.coverImage != null)
                  GestureDetector(
                    onTap: () {
                      CommonWidget.navigateToScreen(
                          context,
                          ZoomableImageList(imageUrls: [
                            servicesDetailsData.coverImage ?? ""
                          ]));
                    },
                    child: Container(
                      width: double.infinity,
                      child: Image.network(
                        servicesDetailsData.coverImage ?? "",
                        height: MediaQuery.sizeOf(context).height * 0.5,
                        fit: BoxFit.cover,
                      ),
                    ),
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
                      Container(
                        height: 40,
                        width: 40,
                      )
                      /*Image.asset(
                        CommonWidget.getImagePath("bookmark.png"),
                        height: 40,
                        width: 40,
                      ),*/
                    ],
                  ),
                ),
                if (detailImages.length > 0)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)),
                      margin: EdgeInsets.only(bottom: 10),
                      alignment: Alignment.bottomLeft,
                      height: 110,
                      width: 330,
                      child: Center(
                        child: ListView.builder(
                            itemCount: detailImages.length,
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  CommonWidget.navigateToScreen(
                                      context,
                                      ZoomableImageList(
                                        imageUrls: detailImages,
                                        currentIndex: index,
                                      ));
                                },
                                child: Container(
                                  width: 110,
                                  height: 140,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(20)),
                                        child: Image.network(
                                          detailImages[index] ?? "",
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.fill,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/images/car_image.png',
                                              fit: BoxFit.cover,
                                              height: 100,
                                              width: 100,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                      ),
                    ),
                  )
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
                              servicesDetailsData.categoryName ?? "", 14,
                              color: ColorClass.base_color),
                          padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                          decoration: BoxDecoration(
                              color: Color(0xff1CB2731A),
                              borderRadius: BorderRadius.circular(20))),

                      if(servicesDetailsData.averageRating != null)
                        Row(
                          children: [
                            Image.asset(
                              CommonWidget.getImagePath("stars1.png"),
                              height: 20,
                              width: 20,
                            ),
                            CommonWidget.getTextWidget300(
                                " ${servicesDetailsData.averageRating.toString() ?? ""} (${servicesDetailsData.totalReviews.toString() ?? ""} views)",
                                14)
                          ],
                        ),

                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  CommonWidget.getTextWidget500(
                      servicesDetailsData.serviceTitle ?? "",
                      size: 18),
                  CommonWidget.getTextWidget300(
                      servicesDetailsData.location?.name ?? "", 14,
                      color: ColorClass.dark_gray_base),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                          padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                          decoration: BoxDecoration(
                              color: Color(0xff1CB2731A),
                              borderRadius: BorderRadius.circular(20)),
                          child: CommonWidget.getTextWidget300("About", 14,
                              color: ColorClass.base_color)),
                      GestureDetector(
                        onTap: () {
                          CommonWidget.navigateToScreen(
                              context, BookingListActivity());
                        },
                        child: Container(
                          padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: ColorClass.base_color)),
                          child: CommonWidget.getTextWidget300("Bookings", 14,
                              color: Colors.black),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          CommonWidget.navigateToScreen(
                              context,
                              ZoomableImageList(
                                  imageUrls: servicesDetailsData.detailImages));
                        },
                        child: Container(
                          padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: ColorClass.base_color)),
                          child: CommonWidget.getTextWidget300("Gallery", 14,
                              color: Colors.black),
                        ),
                      ),
                      InkWell(
                        onTap: (){
                            CommonWidget.navigateToScreen(
                                context,
                                RatingReviewScreen(servicesDetailsData));
                        },
                        child: Container(
                          padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: ColorClass.base_color)),
                          child: CommonWidget.getTextWidget300("Reviews", 14,
                              color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  CommonWidget.getTextWidget500("About"),
                  CommonWidget.getTextWidget300(
                      servicesDetailsData.about ?? "", 14,
                      color: ColorClass.dark_gray_base),
                  SizedBox(
                    height: 10,
                  ),
                  CommonWidget.getTextWidget500("Services Provider"),
                  SizedBox(
                    height: 10,
                  ),
                  if (servicesDetailsData.vendorId?.displayPicture != "" &&
                      servicesDetailsData.vendorId?.displayPicture != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ClipOval(
                            child: Image.network(
                          servicesDetailsData.vendorId?.displayPicture ?? "",
                          height: 70,
                          width: 70,
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/car_image.png',
                              fit: BoxFit.cover,
                              height: 70,
                              width: 70,
                            );
                          },
                        )),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CommonWidget.getTextWidget500(
                                  servicesDetailsData.vendorId?.displayName ??
                                      "",
                                  textAlign: TextAlign.start,
                                  color: ColorClass.base_color),
                              CommonWidget.getTextWidget300(
                                  "Services Provider", 14,
                                  textAlign: TextAlign.start),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            try {
                              final Uri emailLaunchUri = Uri(
                                scheme: 'tel',
                                path: servicesDetailsData.vendorId?.mobile,
                              );
                              launchUrl(emailLaunchUri);
                            } catch (e) {
                              print(e);
                            }
                          },
                          child: Image.asset(
                            CommonWidget.getImagePath("phone.png"),
                            height: 40,
                            width: 40,
                          ),
                        ),
                        /*Image.asset(
                        CommonWidget.getImagePath("chat.png"),
                        height: 40,
                        width: 40,
                      ),*/
                      ],
                    ),
                  if(servicesDetailsData.offers.length>0)
                  SizedBox(height: 10,),
                  if(servicesDetailsData.offers.length>0)
                    InkWell(
                        onTap: (){
                          CommonWidget.navigateToScreen(context, ViewOfferListViaDetail(servicesDetailsData));
                        },
                        child: CommonWidget.getButtonWidget("View Offer", ColorClass.base_color, ColorClass.base_color))
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  getServicesDetails(BuildContext context) async {
    var response =
        await dataManager!.getServiceDetails(context, widget.servicesData);
    var data = ServicesDetailsBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        servicesDetailsData = data.data!;
        detailImages.clear();
        detailImages.addAll(data.data!.detailImages!);
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
}
