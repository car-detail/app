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
    // Only include location if we have valid (non-zero) coordinates.
    // If lat/long are missing or 0.0, the server falls back to the vendor's
    // authoritative location stored in MongoDB.
    final rawLat = sharedPreferences.getString(Constant.lat) ?? "0.0";
    final rawLong = sharedPreferences.getString(Constant.long) ?? "0.0";
    final lat = double.tryParse(rawLat) ?? 0.0;
    final lng = double.tryParse(rawLong) ?? 0.0;
    final hasValidLocation = lat.abs() > 0.0001 && lng.abs() > 0.0001;

    final Map<String, dynamic> body = <String, dynamic>{
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
      "isActive": true,
    };

    if (hasValidLocation) {
      body["location"] = {
        "name": sharedPreferences.getString(Constant.location) ?? "",
        "coordinates": {"long": lng, "lat": lat},
      };
    }

    return apiFuntions.postdatauser(
      context,
      Constant.addOffer,
      body,
      skipAutoNavigation: true,
    );
  }


  editOffer(
      BuildContext context,
      String offerId,
      String title,
      String description,
      String discount,
      String validUntil,
      String serviceId,
      String image) {
    var data = <String, dynamic>{
        "title": title,
        "service": serviceId,
        "description": description,
        "image": image,
    };
    if (validUntil.isNotEmpty) {
      data["validUntil"] = validUntil;
    } else {
      data["validUntil"] = null;
    }
    if (discount.isNotEmpty) {
      data["discount"] = double.tryParse(discount);
    } else {
      data["discount"] = null;
    }

    return apiFuntions.patchdatauser(
      context,
      "${Constant.editOffer}$offerId",
      data,
    );
  }

  duplicateOffer(BuildContext context, String offerId, String? validUntil) {
    return apiFuntions.postdatauser(
      context,
      "${Constant.duplicateOffer}$offerId",
      <String, dynamic>{
        if (validUntil != null) "validUntil": validUntil,
      },
      skipAutoNavigation: true,
    );
  }
}