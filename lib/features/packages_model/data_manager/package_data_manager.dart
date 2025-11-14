import 'dart:convert';
import 'package:car_app/Api/ApiFuntion.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PackageDataManager {
  SharedPreferences? sharedPreferences;

  PackageDataManager(SharedPreferences sharedPreferences) {
    this.sharedPreferences = sharedPreferences;
  }

  Future<http.Response> getAllServices(BuildContext context) async {
    var vendorId = sharedPreferences!.getString(Constant.vendorId);
    var url = "${Constant.baseurl}${Constant.versionNumber}/services/vendor/$vendorId";
    var token = sharedPreferences!.getString(Constant.accessToken) ?? "";
    
    print("🔍 PackageDataManager.getAllServices()");
    print("🔍 Vendor ID: $vendorId");
    print("🔍 URL: $url");
    
    var response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );
    
    print("📡 Response Status: ${response.statusCode}");
    print("📡 Response Body: ${response.body}");
    
    return response;
  }

  Future<http.Response> createPackage(
    BuildContext context,
    String packageName,
    String packageDescription,
    String packagePrice,
    String packageDuration,
    List<String> servicesIncluded, {
    String? smallVehiclePrice,
    String? largeVehiclePrice,
    String? packageTier,
    bool? isBestSeller,
  }) async {
    var vendorId = sharedPreferences!.getString(Constant.vendorId);
    var url = "${Constant.baseurl}${Constant.createPackage}";
    
    var body = {
      "packageName": packageName,
      "description": packageDescription,
      "price": int.tryParse(packagePrice) ?? 0,
      "servicesIncluded": servicesIncluded,
      "vendorId": vendorId,
    };
    
    var token = sharedPreferences!.getString(Constant.accessToken) ?? "";
    return await http.post(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> getAllPackages(BuildContext context) async {
    var vendorId = sharedPreferences!.getString(Constant.vendorId);
    var url = "${Constant.baseurl}${Constant.getAllPackages}?vendorId=$vendorId";
    
    var token = sharedPreferences!.getString(Constant.accessToken) ?? "";
    return await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );
  }

  Future<http.Response> updatePackage(
    BuildContext context,
    String packageId,
    String packageName,
    String packageDescription,
    String packagePrice,
    String packageDuration,
    List<String> servicesIncluded,
    bool isActive,
  ) async {
    var url = "${Constant.baseurl}${Constant.versionNumber}/packages/$packageId";
    
    var body = {
      "packageName": packageName,
      "description": packageDescription,
      "price": int.tryParse(packagePrice) ?? 0,
      "servicesIncluded": servicesIncluded,
      "isActive": isActive,
    };
    
    var token = sharedPreferences!.getString(Constant.accessToken) ?? "";
    return await http.patch(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> deletePackage(BuildContext context, String packageId) async {
    var url = "${Constant.baseurl}${Constant.versionNumber}/packages/$packageId";
    
    var token = sharedPreferences!.getString(Constant.accessToken) ?? "";
    return await http.delete(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );
  }
}
