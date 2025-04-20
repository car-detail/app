import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import 'package:flutter/material.dart';

import '../../../Common/Constant.dart';

class ServicesDataManager {
  SharedPreferences sharedPreferences;

  ServicesDataManager(this.sharedPreferences);

  ApiFuntions apiFuntions = ApiFuntions();

  postImage(List<File> file, BuildContext context) {
    return apiFuntions.sendMultipartRequest(
      context,
      "${Constant.uploadFile}",
      file,
      <String, dynamic>{},
    );
  }

  getcategory(BuildContext context) {
    return apiFuntions.getdatauser(context, Constant.category);
  }

  getServicesList(BuildContext context) {
    return apiFuntions.getdatauser(context,
        "${Constant.getServicesList}${sharedPreferences.getString(Constant.vendorId) ?? ""}");
  }

  postServies(
      BuildContext context,
      String title,
      String about,
      String timeSlot,
      String price,
      String duration,
      String catName,
      String categoryId,
      List<String> detailImage,
      String coverImage,
      String mobile) {
    return apiFuntions.postdatauser(
      context,
      "${Constant.addServices}",
      <String, dynamic>{
        "serviceTitle": title,
        "vendorId": sharedPreferences.getString(Constant.vendorId) ?? "",
        "about": about,
        "timeSlotCapacity": timeSlot,
        "price": price,
        "serviceDuration": duration,
        "categoryName": "Car wash.",
        "categoryId": "6717403221480d697d60d26d",
        "detailImages": detailImage,
        "coverImage": coverImage,
        "mobile": mobile,
        "location": {
          "name": sharedPreferences.getString(Constant.location) ?? "",
          "coordinates": {
            "lat": double.parse(sharedPreferences.getString(Constant.lat) ?? "0.0"),
            "long": double.parse(sharedPreferences.getString(Constant.long) ?? "0.0")
          }
        }
      },
    );
  }
}
