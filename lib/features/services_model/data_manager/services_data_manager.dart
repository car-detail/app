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
      Constant.uploadFile,
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
      String serviceImage,
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
      "coverImage": serviceImage, // Use coverImage for backward compatibility
      "mobile": mobile,
      "location": {
        "name": sharedPreferences.getString(Constant.location) ?? "",
        "coordinates": {
          "long": double.parse(sharedPreferences.getString(Constant.long) ?? "0.0"),
          "lat": double.parse(sharedPreferences.getString(Constant.lat) ?? "0.0")
        }
      }
    };
    
    print("🔧 API Payload being sent:");
    print("🔧 serviceTitle: $title");
    print("🔧 about: $about");
    print("🔧 timeSlotCapacity: $timeSlot");
    print("🔧 price: $price");
    print("🔧 serviceDuration: $duration");
    print("🔧 categoryName: $catName");
    print("🔧 categoryId: $categoryId");
    print("🔧 coverImage: $serviceImage");
    print("🔧 mobile: $mobile");
    print("🔧 Full payload: $payload");
    
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
      String mobile) {
    return apiFuntions.putdatauser(
      context,
      "${Constant.updateService}$serviceId",
      <String, dynamic>{
        "serviceTitle": title,
        "about": about,
        "timeSlotCapacity": timeSlot,
        "price": price,
        "serviceDuration": duration,
        "categoryName": catName,
        "categoryId": categoryId,
        "coverImage": serviceImage, // Use coverImage for backward compatibility
        "mobile": mobile,
      },
    );
  }
}
