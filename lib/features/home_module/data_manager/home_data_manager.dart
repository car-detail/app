import 'package:car_app/Common/Constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class HomeDataManager {

  SharedPreferences sharedPreferences;
  HomeDataManager(this.sharedPreferences);
  ApiFuntions apiFuntions = ApiFuntions();

  getcategory(BuildContext context) {
    return apiFuntions.getdatauser(context, Constant.category);
  }
  getAllServices(BuildContext context) {
    return apiFuntions.getdatauser(context, "${Constant.getAllService}pageNumber=1&count=20&sortBy=createdAt");
  }

  getBookingListFilter(BuildContext context, String filterType) {
    return apiFuntions.getdatauser(context,
        "${Constant.getBookingList}${sharedPreferences.getString(Constant.vendorId) ?? ""}?pageNumber=1&bookingStatusFilter=$filterType&count=12");
  }
  getOfferList(BuildContext context) {
    return apiFuntions.getdatauser(context,
        "${Constant.getOffer}${sharedPreferences.getString(Constant.vendorId) ?? ""}");
  }
  makeOffLine(BuildContext context) {
    return apiFuntions.putdatauser(context,
        "${Constant.makeOffLine}${sharedPreferences.getString(Constant.vendorId) ?? ""}", {});
  }
  getdetails(BuildContext context) {
    return apiFuntions.getdatauser(context,
        "${Constant.getdetailsVendeor}${sharedPreferences.getString(Constant.vendorId) ?? ""}");
  }
  putStatusCompleted(BuildContext context, String id) {
    return apiFuntions.putdatauser(
        context,
        "${Constant.completeBooking}$id",
        <String, dynamic>{
          "commentByVendor": "Done"
        });
  }
  putStatusCancel(BuildContext context, String reason,String sId) {
    return apiFuntions.putdatauser(
        context,
        "${Constant.cancelBooking}$sId",
        <String, dynamic>{
          "commentByVendor": reason
        });
  }
}