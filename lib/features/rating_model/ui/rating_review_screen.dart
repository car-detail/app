import 'dart:convert';

import 'package:car_app/Common/BaseActivity.dart';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonBean.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/ContainerDecoration.dart';
import 'package:car_app/features/rating_model/data_manager/RatingReviewDataManager.dart';
import 'package:car_app/features/specialists_module/model/services_details_model_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/rate_review_model_bean.dart';

class RatingReviewScreen extends StatefulWidget {
  ServicesDetailsData servicesDetailsData;

  RatingReviewScreen(this.servicesDetailsData, {super.key});

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  double value = 1.0;
  var reviewController = TextEditingController();
  RatingReviewDataManager? dataManager;
  SharedPreferences? sharedPreferences;
  List<Reviews> reviewsList = [];
  var buttonText = "Add Review";
  var isEdit = false;
  var reviewId = "";

  var showAddReviewLayout = false;

  @override
  void initState() {
    start();
    super.initState();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = RatingReviewDataManager(sharedPreferences!);
    getRateList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CommonWidget.gettopbar("Rating & Review", context),
          SizedBox(
            height: 10,
          ),
          Expanded(
              child: Container(
            margin: EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if(reviewsList.length>0)
                Expanded(
                    child: ListView.builder(
                        itemCount: reviewsList.length,
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          var data = reviewsList[index];
                          return Container(
                            padding: EdgeInsets.all(15),
                            margin: EdgeInsets.only(top: 8, bottom: 8),
                            decoration: ContainerDecoration
                                .getboderwithshadowfillcolorblueE7F0FF(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: CommonWidget.getTextWidgetPopSemi(
                                          "${data.userId?.firstName ?? ""}  ${data.userId?.lastName ?? ""}", textAlign: TextAlign.start, size: 12),
                                    ),
                                    SizedBox(width: 5,),
                                    CommonWidget.getTextWidgetPopReg(
                                        DateFormat("dd MMM yyyy").format(
                                            DateTime.parse(data.createdAt ?? "")),
                                        color: Colors.grey[500]! , textsize: 12),
                                  ],
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                CommonWidget.getTextWidgetPopSemi(
                                    "${data.userId?.email ?? ""}", size: 12),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    CommonWidget.getTextWidgetPopSemi(
                                        "Rating : ", size: 12),
                                    Image.asset(
                                      CommonWidget.getImagePath("stars1.png"),
                                      height: 20,
                                      width: 20,
                                    ),
                                    CommonWidget.getTextWidget300(
                                        " ${data.rating.toString() ?? ""}", 14)
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                CommonWidget.getTextWidgetPopReg(
                                    data.reviewText ?? "", textsize: 12)
                              ],
                            ),
                          );
                        })),
                if(reviewsList.length==0)
                Expanded(child: Center(
                  child: CommonWidget.getTextWidgetPopSemi("No Rating & Review Added Yet.",size: 16),
                ))
              ],
            ),
          ))
        ],
      ),
    );
  }

  addRating(BuildContext context) async {
    var response = await dataManager!.addRating(context, value,
        reviewController.text, widget.servicesDetailsData.sId.toString());
    var data = CommonBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      //CommonWidget.navigateToScreen(context, DashboardActivity(currentIndex: 2,));
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
  editRating(BuildContext context) async {
    var response = await dataManager!.editRating(context, value,
        reviewController.text, widget.servicesDetailsData.sId.toString(), reviewId);
    var data = CommonBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      getRateList();
      //CommonWidget.navigateToScreen(context, DashboardActivity(currentIndex: 2,));
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  getRateList() async {
    var response = await dataManager!
        .getReviewRateList(context, widget.servicesDetailsData.sId.toString());
    var data = RateReviewModelBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        reviewsList.clear();
        reviewsList.addAll(data.data!.reviews);
        if (data.data!.myReview.length > 0) {
          value = data.data!.myReview[data.data!.myReview.length - 1].rating!
              .toDouble();
          reviewController.text =
              data.data!.myReview[data.data!.myReview.length - 1].reviewText ??
                  "";
          buttonText = "Edit Review";
          showAddReviewLayout = data.data!.alreadyCustomer??false;
          isEdit = true;
          reviewId = data.data!.myReview[data.data!.myReview.length - 1].sId.toString();
        }
      });
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
}
