import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class RatingReviewDataManager {
  SharedPreferences sharedPreferences;

  RatingReviewDataManager(this.sharedPreferences);

  ApiFuntions apiFuntions = ApiFuntions();

  addRating(
      BuildContext context, double rate, String review, String serviceId) {
    return apiFuntions.postdatauser(context, Constant.addRating, {
      "serviceId": serviceId,
      "userId": sharedPreferences.getString(Constant.id),
      "reviewText": review,
      "rating": rate
    });
  }
  editRating(
      BuildContext context, double rate, String review, String serviceId, String reviewId) {
    return apiFuntions.patchdatauser(context, "${Constant.editRating}$reviewId", {
      "serviceId": serviceId,
      "userId": sharedPreferences.getString(Constant.id),
      "reviewText": review,
      "rating": rate
    });
  }

  getReviewRateList(BuildContext context, String id) {
    return apiFuntions.getdatauser(context,
        "${Constant.getReviewRate}$id?page=1&limit=12&userId=");
  }
}
