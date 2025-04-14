import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class LoginDataManager {
  String deviceType = "";
  String osVersion = "";
  String deviceMake = "";
  String deviceModel = "";
  PackageInfo? packageInfo;
  String appVersionCode = "";
  String appVersionName = "";
  String imei = "";
  DeviceInfoPlugin? deviceInfo;
  AndroidDeviceInfo? androidInfo;
  late ApiFuntions apis;
  SharedPreferences sharedPreferences;
  ApiFuntions apiFuntions = ApiFuntions();

  LoginDataManager(this.sharedPreferences) {
    start();
  }

  start() async {
    deviceInfo = DeviceInfoPlugin();
    packageInfo = await PackageInfo.fromPlatform();
    appVersionCode = packageInfo!.buildNumber;
    appVersionName = packageInfo!.version;
    if (Platform.isAndroid) {
      androidInfo = await deviceInfo!.androidInfo;
      deviceType = androidInfo!.device;
      osVersion = androidInfo!.version.release;
      //deviceMake = androidInfo!.manufacturer;
      deviceMake = "Android";
      deviceModel = androidInfo!.model;
      imei = "";
    } else {
      IosDeviceInfo iosInfo = await deviceInfo!.iosInfo;
      deviceType = iosInfo.model;
      osVersion = "IOS${iosInfo.systemVersion}";
      deviceMake = 'ios'; // Since iOS devices have the same manufacturer
      deviceModel = iosInfo.utsname.machine;
      imei = iosInfo.identifierForVendor ?? "";
    }
  }

  Future<http.Response> postlogin(String mobileNo, BuildContext context) {
    print(
        "sharedPreferences?.getString(Constant.fbtoken)${sharedPreferences.getString(Constant.fbtoken)}");
    return apiFuntions.postdatauser(context, Constant.generateOTP, <String, dynamic>{
      "mobile": mobileNo
    });
  }
  Future<http.Response> postOTP(String otpNo,String sesionId,String mobileNo, BuildContext context) {
    print(
        "sharedPreferences?.getString(Constant.fbtoken)${sharedPreferences.getString(Constant.fbtoken)}");
    return apiFuntions.postdatauser(context, Constant.verifyOtp, <String, dynamic>{
        "session_id": sesionId,
        "otp_input": otpNo,
        "mobile": mobileNo,
        "fcmToken": "",
        "deviceId": imei
    });
  }
  Future<http.Response> postUserDetails(String firstName,String lastName,String email,String profileImage, String id, BuildContext context) {
        return apiFuntions.putdatauser(context, "${Constant.updateUserDetails}${id}", <String, dynamic>{
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "image": profileImage
        });
  }
  Future<http.Response> postImage(List<File> file, BuildContext context) {
        return apiFuntions.sendMultipartRequest(context, "${Constant.uploadFile}",file, <String , dynamic>{}, );
  }
  Future<http.Response> getUserDetails(BuildContext context) {
        return apiFuntions.getdatauser(context, Constant.getUserDetails);
  }



}
