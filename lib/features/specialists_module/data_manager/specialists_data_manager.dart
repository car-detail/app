import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class SpecialistsDataManager{
  SharedPreferences sharedPreferences;
  SpecialistsDataManager(this.sharedPreferences);
  ApiFuntions apiFuntions = ApiFuntions();

  getServiceDetails(BuildContext context, String id) {
    return apiFuntions.getdatauser(context, "${Constant.serviceDetails}$id");
  }

  Future<http.Response> getVendorPackages(BuildContext context, String vendorId) async {
    try {
      return await apiFuntions.getdatauser(
        context,
        "${Constant.getVendorPackages}$vendorId",
        cycle: false,
      );
    } catch (e) {
      print("❌ Error in getVendorPackages API call: $e");
      return http.Response('{"status":"error","message":"API call failed: $e"}', 500);
    }
  }
}