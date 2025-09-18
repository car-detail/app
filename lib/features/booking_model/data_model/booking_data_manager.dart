import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class BookingDataManager {
  SharedPreferences sharedPreferences;

  BookingDataManager(this.sharedPreferences);

  ApiFuntions apiFuntions = ApiFuntions();

  getServiceDetails(BuildContext context, String id) {
    return apiFuntions.getdatauser(context, "${Constant.serviceDetails}$id");
  }

  getBookingList(BuildContext context) {
    return apiFuntions.getdatauser(context,
        "${Constant.getBookingList}${sharedPreferences.getString(Constant.vendorId) ?? ""}?pageNumber=1&count=12");
  }

  //http://13.232.212.175:7007/v1/bookings/get-bookings/60d21b4667d0d8992e610c85?pageNumber=1&bookingStatusFilter=Completed&count=12
  getBookingListFilter(BuildContext context, String filterType) {
    return apiFuntions.getdatauser(context,
        "${Constant.getBookingList}${sharedPreferences.getString(Constant.vendorId) ?? ""}?pageNumber=1&bookingStatusFilter=$filterType&count=12");
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
