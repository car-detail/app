import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final SharedPreferences sharedPreferences;
  final ApiFuntions apiFuntions = ApiFuntions();

  LoginDataManager(this.sharedPreferences) {
    start();
  }

  Future<void> start() async {
    try {
      deviceInfo = DeviceInfoPlugin();
      packageInfo = await PackageInfo.fromPlatform();
      appVersionCode = packageInfo?.buildNumber ?? "";
      appVersionName = packageInfo?.version ?? "";

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          androidInfo = await deviceInfo!.androidInfo;
          deviceType = androidInfo?.device ?? "Unknown";
          osVersion = androidInfo?.version.release ?? "Unknown";
          deviceMake = "Android";
          deviceModel = androidInfo?.model ?? "Unknown";
          imei = "";
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo!.iosInfo;
          deviceType = iosInfo.model ?? "Unknown";
          osVersion = "iOS ${iosInfo.systemVersion ?? "Unknown"}";
          deviceMake = "iOS";
          deviceModel = iosInfo.utsname.machine ?? "Unknown";
          imei = iosInfo.identifierForVendor ?? "";
        }
      } else {
        // Web fallback (limited info)
        final iosInfo = await deviceInfo!.iosInfo; // Note: may not be accurate on web
        deviceType = iosInfo.model ?? "Unknown";
        osVersion = "iOS ${iosInfo.systemVersion ?? "Unknown"}";
        deviceMake = "iOS";
        deviceModel = iosInfo.utsname.machine ?? "Unknown";
        imei = iosInfo.identifierForVendor ?? "";
      }
    } catch (e) {
      // Fallback values
      deviceType = "Unknown";
      osVersion = "Unknown";
      deviceMake = Platform.isIOS ? "iOS" : "Android";
      deviceModel = "Unknown";
      imei = "";
    }
  }

  /// Sends OTP via Firebase Phone Auth.
  /// Returns the verificationId (or mock one for bypass).
  Future<String> sendFirebaseOTP(
    String mobileNo,
    Function(String verificationId) onCodeSent,
    Function(String error) onError,
  ) async {
    // Test phone numbers that automatically return a test verification code
    // These are provided by Firebase for testing without needing real SMS
    final testPhoneNumbers = {
      '+11234567890': '123456',
      '+16505551234': '789456',
      '+12125551234': '456789',
      '+919876543210': '111222',
    };
    // Check if this is a test phone number
    String formattedMobile = mobileNo.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!formattedMobile.startsWith('+')) {
      formattedMobile = '+$formattedMobile';
    }
    
    if (testPhoneNumbers.containsKey(formattedMobile)) {
      // For test numbers, simulate successful verification
      // The verification code is stored in the map
      String testVerificationCode = testPhoneNumbers[formattedMobile]!;
      final mockVerificationId = 'TEST_VERIFICATION_ID_${formattedMobile.replaceAll(RegExp(r'[^0-9+]'), '')}_${testVerificationCode}';
      
      // Store the test verification code in shared preferences for later use
      await sharedPreferences.setString('test_verification_code_${formattedMobile}', testVerificationCode);
      
      onCodeSent(mockVerificationId);
      return mockVerificationId;
    }
    
    // Bypass logic (your original)
    final bypassNumbers = <String>[];
    final normalizedPhone = mobileNo.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (bypassNumbers.contains(normalizedPhone) ||
        bypassNumbers.any((bypass) => normalizedPhone.endsWith(bypass.replaceAll('+', '')))) {
      final mockVerificationId = 'BYPASS_VERIFICATION_ID_${mobileNo.replaceAll(RegExp(r'[^0-9]'), '')}';
      onCodeSent(mockVerificationId);
      return mockVerificationId;
    }

    try {
      // Ensure Firebase is ready
      FirebaseAuth.instance;
      Firebase.app();

      final auth = FirebaseAuth.instance;

      // Normalize phone → E.164 format
      String formattedPhone = mobileNo.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+$formattedPhone';
      }

      // Basic validation
      final digitsOnly = formattedPhone.substring(1);
      if (digitsOnly.length < 7 || digitsOnly.length > 15 || !RegExp(r'^\d+$').hasMatch(digitsOnly)) {
        onError('Invalid phone number format. Use international format (e.g. +12025550123).');
        return '';
      }

      String? verificationId;
      bool codeSentSuccessfully = false;

      // Key for storing resend token & timestamp
      final resendTokenKey = '${Constant.firebasePhoneResendTokenPrefix}_$digitsOnly';
      final lastSentKey = '${Constant.firebasePhoneResendTokenPrefix}_lastSent_$digitsOnly';

      int? forceResendToken = sharedPreferences.getInt(resendTokenKey);

      // Optional: clear old token during development/testing (uncomment when needed)
      // await sharedPreferences.remove(resendTokenKey);
      // forceResendToken = null;

      // Invalidate token if older than ~12 minutes (most realistic safe window)
      final lastSentMs = sharedPreferences.getInt(lastSentKey) ?? 0;
      final ageMinutes = (DateTime.now().millisecondsSinceEpoch - lastSentMs) ~/ 60000;
      if (ageMinutes > 12 || ageMinutes < 0) {
        forceResendToken = null;
        await sharedPreferences.remove(resendTokenKey);
      }

      await auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendToken,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verification (Android) — usually not needed to handle here
        },
        verificationFailed: (FirebaseAuthException e) {
          String msg = e.message ?? 'Unknown error';
          String code = e.code ?? 'unknown';

          if (code == 'too-many-requests') {
            onError('Too many attempts. Firebase blocked this device temporarily.\nWait 1–2 hours or try another number/device.');
          } else if (code == 'invalid-phone-number') {
            onError('Invalid phone number format.');
          } else if (code == 'quota-exceeded') {
            onError('SMS quota exceeded for this project.');
          } else if (Platform.isIOS && (msg.contains('APNs') || msg.contains('nil'))) {
            onError('iOS phone auth issue: APNs not configured or simulator used.\nTest on real device + check Firebase APNs setup.');
          } else {
            onError('Verification failed: $msg (code: $code)');
          }
        },
        codeSent: (String verId, int? resendToken) {
          verificationId = verId;
          codeSentSuccessfully = true;

          if (resendToken != null) {
            sharedPreferences.setInt(resendTokenKey, resendToken);
            sharedPreferences.setInt(lastSentKey, DateTime.now().millisecondsSinceEpoch);
          }

          onCodeSent(verId);
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
          // Optional: you can notify UI here if needed
        },
      );

      return verificationId ?? '';
    } catch (e) {
      // Timeout / async issues often mean codeSent was called already → don't error
      if (e.toString().contains('Timeout') || e.toString().contains('timeout')) {
        return '';
      }

      String msg = 'Failed to send OTP: $e';
      if (Platform.isIOS && e.toString().contains('APNs')) {
        msg = 'iOS requires APNs key in Firebase console → Cloud Messaging.';
      }
      onError(msg);
      return '';
    }
  }

  Future<http.Response> postOTP(
    String otpNo,
    String verificationId,
    String mobileNo,
    BuildContext context, {
    String? firebaseIdToken,
  }) async {
    try {
      // Test phone numbers that automatically return a test verification code
      final testPhoneNumbers = {
        '+11234567890': '123456',
        '+16505551234': '789456',
        '+12125551234': '456789',
        '+919876543210': '111222',
      };
      
      String formattedMobile = mobileNo.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!formattedMobile.startsWith('+')) {
        formattedMobile = '+$formattedMobile';
      }
      
      // Check if this is a test phone number and the OTP matches the expected test code
      bool isTestNumber = testPhoneNumbers.containsKey(formattedMobile);
      bool isValidTestCode = isTestNumber && testPhoneNumbers[formattedMobile] == otpNo;
      
      final bypassNumbers = <String>[];
      final normalizedPhone = mobileNo.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
      final isBypass = bypassNumbers.contains(normalizedPhone) ||
          bypassNumbers.any((b) => normalizedPhone.endsWith(b.replaceAll('+', ''))) ||
          verificationId.startsWith('BYPASS_') ||
          verificationId.startsWith('TEST_');

      String? idToken = firebaseIdToken;

      if (idToken == null) {
        if (isBypass || isValidTestCode) {
          // Use bypass token for bypass numbers, test token for test numbers
          if (verificationId.startsWith('TEST_')) {
            idToken = 'TEST_TOKEN_${mobileNo.replaceAll(RegExp(r'[^0-9]'), '')}_${otpNo}';
          } else {
            idToken = 'BYPASS_TOKEN_${mobileNo.replaceAll(RegExp(r'[^0-9]'), '')}';
          }
        } else {
          final auth = FirebaseAuth.instance;
          final credential = PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: otpNo,
          );

          final userCredential = await auth.signInWithCredential(credential);
          idToken = await userCredential.user?.getIdToken();

          if (idToken == null) {
            throw Exception('No ID token after sign-in');
          }
        }
      }

      // Format phone consistently for backend
      String formattedPhone = mobileNo.trim();
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = formattedPhone.length == 10
            ? '+91$formattedPhone' // Default to India for 10 digits
            : formattedPhone.length == 11 && formattedPhone.startsWith('1')
                ? '+$formattedPhone'
                : '+91$formattedPhone';
      }

      return apiFuntions.postdatauser(context, Constant.verifyOtp, {
        "firebaseIdToken": idToken,
        "mobile": formattedPhone,
        "fcmToken": sharedPreferences.getString(Constant.fbtoken) ?? "",
        "deviceId": imei,
      }, skipAutoNavigation: true);
    } catch (e) {
      return http.Response(
        jsonEncode({"status": "error", "message": "OTP verification failed: $e"}),
        400,
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<http.Response> postUserDetails(
    String firstName,
    String lastName,
    String email,
    String profileImage,
    String id,
    BuildContext context, {
    String? locationName,
    double? lat,
    double? lng,
  }) {
    final payload = <String, dynamic>{
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "image": profileImage,
    };

    if (locationName != null && lat != null && lng != null) {
      payload["location"] = jsonEncode({
        "name": locationName,
        "coordinates": {"lat": lat, "long": lng},
      });
    }

    return apiFuntions.putdatauser(context, "${Constant.updateUserDetails}$id", payload);
  }

  Future<http.Response> postImage(
    List<File> file,
    BuildContext context, {
    bool skipAutoNavigation = false,
  }) {
    return apiFuntions.sendMultipartRequest(
      context,
      Constant.uploadFile,
      file,
      {},
      skipAutoNavigation: skipAutoNavigation,
    );
  }

  Future<http.Response> getUserDetails(BuildContext context) {
    return apiFuntions.getdatauser(context, Constant.getUserDetails);
  }

  Future<http.Response> getVendorDetails(BuildContext context) {
    return apiFuntions.getdatauser(context, Constant.getVendorDetails);
  }

  Future<http.Response> getVendorServices(BuildContext context, String vendorId) {
    return apiFuntions.getdatauser(context, "${Constant.getServicesList}$vendorId");
  }

  Future<http.Response> syncFcmToken(BuildContext context) async {
    try {
      final userId = sharedPreferences.getString(Constant.id);
      final fcmToken = sharedPreferences.getString(Constant.fbtoken);

      if (userId == null || userId.isEmpty || fcmToken == null || fcmToken.isEmpty) {
        return http.Response(
          jsonEncode({"status": "error", "message": "Missing user ID or FCM token"}),
          400,
        );
      }

      return apiFuntions.putdatauser(
        context,
        "${Constant.updateUserDetails}$userId",
        {"fcmToken": fcmToken},
      );
    } catch (e) {
      return http.Response(
        jsonEncode({"status": "error", "message": "$e"}),
        500,
      );
    }
  }

  Future<http.Response> markTourShown(BuildContext context) async {
    try {
      String? userId = sharedPreferences.getString(Constant.UserID);

      // Fallback: fetch user ID if missing
      if (userId == null || userId.isEmpty) {
        final res = await getUserDetails(context);
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body);
          if (json['status'] == 'success' && json['data']?.isNotEmpty == true) {
            userId = json['data'][0]['_id']?.toString();
          }
        }
      }

      if (userId == null || userId.isEmpty) {
        return http.Response(
          jsonEncode({"status": "error", "message": "User ID not found"}),
          400,
        );
      }

      // Preserve existing fields
      final payload = <String, dynamic>{};
      final currentRes = await getUserDetails(context);
      if (currentRes.statusCode == 200) {
        final json = jsonDecode(currentRes.body);
        if (json['status'] == 'success' && json['data']?.isNotEmpty == true) {
          final data = json['data'][0];
          payload['firstName'] = data['firstName'] ?? "";
          payload['lastName'] = data['lastName'] ?? "";
          if (data['email'] != null) payload['email'] = data['email'];
          if (data['image'] != null) payload['image'] = data['image'];
          if (data['location'] != null) {
            // Convert location map to string if needed
            if (data['location'] is Map) {
              payload['location'] = jsonEncode(data['location']);
            } else {
              payload['location'] = data['location'];
            }
          }
        }
      } else {
        payload['firstName'] = "";
        payload['lastName'] = "";
      }

      payload['tour_shown'] = true;

      return apiFuntions.putdatauser(
        context,
        "${Constant.updateUserDetails}$userId",
        payload,
      );
    } catch (e) {
      return http.Response(
        jsonEncode({"status": "error", "message": "$e"}),
        500,
      );
    }
  }
}