import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class OfferDataManager{
  SharedPreferences sharedPreferences;

  OfferDataManager(this.sharedPreferences);

  ApiFuntions apiFuntions = ApiFuntions();
  postImage(List<File> file, BuildContext context) {
    return apiFuntions.sendMultipartRequest(
      context,
      "${Constant.uploadFile}",
      file,
      <String, dynamic>{},
    );
  }
  getServicesList(BuildContext context) {
    return apiFuntions.getdatauser(context,
        "${Constant.getServicesList}${sharedPreferences.getString(Constant.vendorId) ?? ""}");
  }
  getOfferList(BuildContext context) {
    return apiFuntions.getdatauser(context,
        "${Constant.getOffer}${sharedPreferences.getString(Constant.vendorId) ?? ""}");
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
      "${Constant.addOffer}",
      <String, dynamic>{
        "title": title,
        "vendor": sharedPreferences.getString(Constant.vendorId) ?? "",
        "service": serviceId,
        "description": description,
        "image": image,
        "discount": discount,
        "validFrom": validFrom,
        "validUntil": validUntil,
        "location": {
          "name": sharedPreferences.getString(Constant.location) ?? "",
          "coordinates": {
            "lat": double.parse(sharedPreferences.getString(Constant.lat) ?? "0.0"),
            "long": double.parse(sharedPreferences.getString(Constant.long) ?? "0.0")
          }
        },
        "isActive": true,
      },
    );
  }
}