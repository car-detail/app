import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import 'package:flutter/material.dart';

import '../../../Common/Constant.dart';

class ServicesDataManager {
  SharedPreferences sharedPreferences;

  ServicesDataManager(this.sharedPreferences);

  ApiFuntions apiFuntions = ApiFuntions();

  postImage(List<File> file, BuildContext context, {bool skipAutoNavigation = false}) {
    return apiFuntions.sendMultipartRequest(
      context,
      Constant.uploadFile,
      file,
      <String, dynamic>{},
      skipAutoNavigation: skipAutoNavigation,
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
      String serviceImage,
      List<String> detailImages,
      String mobile) {
    
    Map<String, dynamic> payload = {
      "serviceTitle": title,
      "vendorId": sharedPreferences.getString(Constant.vendorId) ?? "",
      "about": about,
      "timeSlotCapacity": timeSlot,
      "price": price,
      "serviceDuration": duration,
      "categoryName": catName,
      "categoryId": categoryId,
      "coverImage": serviceImage,
      "detailImages": detailImages,
      "mobile": mobile,
      "location": {
        "name": sharedPreferences.getString(Constant.location) ?? "",
        "coordinates": {
          "long": double.parse(sharedPreferences.getString(Constant.long) ?? "0.0"),
          "lat": double.parse(sharedPreferences.getString(Constant.lat) ?? "0.0")
        }
      }
    };
    
    
    return apiFuntions.postdatauser(
      context,
      Constant.addServices,
      payload,
    );
  }

  updateService(
      BuildContext context,
      String serviceId,
      String title,
      String about,
      String timeSlot,
      String price,
      String duration,
      String catName,
      String categoryId,
      String serviceImage,
      List<String> detailImages,
      String mobile) {
    // Build payload with proper types
    Map<String, dynamic> payload = {
      "serviceTitle": title,
      "about": about,
      "timeSlotCapacity": timeSlot,
      "price": price.isNotEmpty ? (double.tryParse(price) ?? 0.0) : 0.0,
      "serviceDuration": duration,
      "categoryName": catName,
      "categoryId": categoryId,
      "coverImage": serviceImage,
      "detailImages": detailImages,
      "mobile": mobile,
    };
    
    
    return apiFuntions.putdatauser(
      context,
      "${Constant.updateService}$serviceId",
      payload,
    );
  }

  pauseService(BuildContext context, String serviceId, bool isPaused) {
    return apiFuntions.patchdatauser(
      context,
      "${Constant.pauseService}$serviceId",
      <String, dynamic>{
        "isPaused": isPaused,
      },
      skipAutoNavigation: true,
    );
  }
}
