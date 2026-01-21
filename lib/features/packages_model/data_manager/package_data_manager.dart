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
    
    
    var response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );
    
    
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
    List<String>? customServices,
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
    
    // Add optional fields if provided
    if (smallVehiclePrice != null && smallVehiclePrice.isNotEmpty) {
      body["smallVehiclePrice"] = int.tryParse(smallVehiclePrice) ?? 0;
    }
    if (largeVehiclePrice != null && largeVehiclePrice.isNotEmpty) {
      body["largeVehiclePrice"] = int.tryParse(largeVehiclePrice) ?? 0;
    }
    if (packageTier != null && packageTier.isNotEmpty) {
      body["packageTier"] = packageTier;
    }
    if (isBestSeller != null) {
      body["isBestSeller"] = isBestSeller;
    }
    if (customServices != null && customServices.isNotEmpty) {
      body["customServices"] = customServices;
    }
    
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
    // Use vendor-specific endpoint to get all packages (including inactive ones for vendor view)
    var url = "${Constant.baseurl}${Constant.getVendorPackages}$vendorId";
    
    
    var token = sharedPreferences!.getString(Constant.accessToken) ?? "";
    
    try {
      var response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
      );
      
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> updatePackage(
    BuildContext context,
    String packageId,
    String packageName,
    String packageDescription,
    String packagePrice,
    String packageDuration,
    List<String> servicesIncluded,
    bool isActive, {
    String? smallVehiclePrice,
    String? largeVehiclePrice,
    String? packageTier,
    bool? isBestSeller,
    List<String>? customServices,
  }) async {
    var url = "${Constant.baseurl}${Constant.versionNumber}/packages/$packageId";
    
    var body = {
      "packageName": packageName,
      "description": packageDescription,
      "price": int.tryParse(packagePrice) ?? 0,
      "servicesIncluded": servicesIncluded,
      "isActive": isActive,
    };
    
    // Add optional fields if provided
    if (smallVehiclePrice != null && smallVehiclePrice.isNotEmpty) {
      body["smallVehiclePrice"] = int.tryParse(smallVehiclePrice) ?? 0;
    }
    if (largeVehiclePrice != null && largeVehiclePrice.isNotEmpty) {
      body["largeVehiclePrice"] = int.tryParse(largeVehiclePrice) ?? 0;
    }
    if (packageTier != null && packageTier.isNotEmpty) {
      body["packageTier"] = packageTier;
    }
    if (isBestSeller != null) {
      body["isBestSeller"] = isBestSeller;
    }
    if (customServices != null && customServices.isNotEmpty) {
      body["customServices"] = customServices;
    }
    
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

  Future<http.Response> togglePackageStatus(BuildContext context, String packageId, bool isActive) async {
    // Use the toggle endpoint - backend automatically toggles the status
    var url = "${Constant.baseurl}${Constant.versionNumber}/packages/toggle-package/$packageId";
    
    var token = sharedPreferences!.getString(Constant.accessToken) ?? "";
    return await http.patch(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );
  }
}
