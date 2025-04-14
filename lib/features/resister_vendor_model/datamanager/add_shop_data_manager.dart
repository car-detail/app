import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class AddShopDataManager {
  SharedPreferences sharedPreferences;

  AddShopDataManager(this.sharedPreferences);

  ApiFuntions apiFuntions = ApiFuntions();

  getAllServices(BuildContext context) {
    return apiFuntions.getdatauser(context,
        "${Constant.getAllService}pageNumber=1&count=20&sortBy=createdAt");
  }
  getcategory(BuildContext context) {
    return apiFuntions.getdatauser(context, Constant.category);
  }
  getVendorDetails(BuildContext context) {
    return apiFuntions.getdatauser(context,
        "${Constant.getVendorDetails}");
  }

  postImage(List<File> file, BuildContext context) {
    return apiFuntions.sendMultipartRequest(
      context,
      "${Constant.uploadFile}",
      file,
      <String, dynamic>{},
    );
  }

  captureVendor(
      String displayName,
      String email,
      String mobile,
      String profileImage,
      String openTime,
      String closeTime,
      String title,
      String about,
      String timeSlot,
      String price,
      String duration,
      String catName,
      String categoryId,
      List<String> detailImage,
      String coverImage,
      BuildContext context) async {
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    return apiFuntions
        .postdatauser(context, "${Constant.captureVendor}", <String, dynamic>{
      "displayName": displayName,
      "officialEmail": email,
      "mobile": mobile,
      "displayPicture": profileImage,
      "location": {
        "name": sharedPreferences.getString(Constant.location) ?? "",
        "coordinates": {
          "long": double.parse(sharedPreferences.getString(Constant.long)??"0.0"),
          "lat": double.parse(sharedPreferences.getString(Constant.lat) ?? "0.0")
        }
      },
      "openTime": openTime,
      "closeTime": closeTime,
      "timeZone": currentTimeZone,
      "serviceTitle": title,
      "about": about,
      "timeSlotCapacity": timeSlot,
      "price": price,
      "serviceDuration": duration,
      "categoryName": "Car wash.",
      "categoryId": "6717403221480d697d60d26d",
      "detailImages": detailImage,
      "coverImage": coverImage,
    });
  }
  editCaptureVendor(
      String displayName,
      String email,
      String mobile,
      String profileImage,
      String openTime,
      String closeTime,
      BuildContext context) async {
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    return apiFuntions
        .putdatauser(context, "${Constant.updateVendor}${sharedPreferences.getString(Constant.vendorId)??""}", <String, dynamic>{
      "displayName": displayName,
      "officialEmail": email,
      "mobile": mobile,
      "displayPicture": profileImage,
      "location": {
        "name": sharedPreferences.getString(Constant.location) ?? "",
        "coordinates": {
          "lat": double.parse(sharedPreferences.getString(Constant.lat) ?? "0.0"),
          "long": double.parse(sharedPreferences.getString(Constant.long)??"0.0")
        }
      },
      "openTime": openTime,
      "closeTime": closeTime,
      "timeZone": currentTimeZone
    });
  }
}
