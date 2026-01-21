import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class OfferDataManager{
  SharedPreferences sharedPreferences;

  OfferDataManager(this.sharedPreferences);

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
  getServicesList(BuildContext context) {
    return apiFuntions.getdatauser(context,
        "${Constant.getServicesList}${sharedPreferences.getString(Constant.vendorId) ?? ""}");
  }
  getOfferList(BuildContext context) {
    var vendorId = sharedPreferences.getString(Constant.vendorId) ?? "";
    var url = "${Constant.getOffer}$vendorId";
    
    
    var response = apiFuntions.getdatauser(context, url);
    
    // Log response when it completes
    response.then((res) {
    }).catchError((e) {
    });
    
    return response;
  }
  getOfferByServiceId(BuildContext context, String id) {
    return apiFuntions.getdatauser(context,
        "${Constant.getOfferByServiceId}$id");
  }

  postOfferUpdate(BuildContext context, String id) {
    return apiFuntions.patchdatauser(context,
        "${Constant.postOfferUpdate}$id", {});
  }
  deleteOffer(BuildContext context, String id) {
    return apiFuntions.deletedatauser(context,
        "${Constant.offerDelete}$id");
  }
  addOffer(
      BuildContext context,
      String title,
      String description,
      String discount,
      String validFrom,
      String validUntil,
      String serviceId,
      String image) {
    return apiFuntions.postdatauser(
      context,
      Constant.addOffer,
      <String, dynamic>{
        "title": title,
        "vendor": sharedPreferences.getString(Constant.vendorId) ?? "",
        "service": serviceId,
        "description": description,
        "image": image,
        "discount": discount.isEmpty ? null : (double.tryParse(discount)),
        "validFrom": "${DateTime.now().year.toString().padLeft(4, '0')}-"
            "${DateTime.now().month.toString().padLeft(2, '0')}-"
            "${DateTime.now().day.toString().padLeft(2, '0')} 00:00:00.000",
        "validUntil": validUntil.isEmpty ? null : validUntil,
        "location": {
          "name": sharedPreferences.getString(Constant.location) ?? "",
          "coordinates": {
            "long": double.parse(sharedPreferences.getString(Constant.long) ?? "0.0"),
            "lat": double.parse(sharedPreferences.getString(Constant.lat) ?? "0.0"),

          }
        },
        "isActive": true,
      },
      skipAutoNavigation: true,
    );
  }
}