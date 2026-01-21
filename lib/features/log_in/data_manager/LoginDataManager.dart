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
  SharedPreferences sharedPreferences;
  ApiFuntions apiFuntions = ApiFuntions();

  LoginDataManager(this.sharedPreferences) {
    start();
  }

  start() async {
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
          IosDeviceInfo iosInfo = await deviceInfo!.iosInfo;
          deviceType = iosInfo.model ?? "Unknown";
          osVersion = "IOS${iosInfo.systemVersion ?? "Unknown"}";
          deviceMake = 'ios';
          deviceModel = iosInfo.utsname.machine ?? "Unknown";
          imei = iosInfo.identifierForVendor ?? "";
        }
      } else {
        IosDeviceInfo iosInfo = await deviceInfo!.iosInfo;
        deviceType = iosInfo.model ?? "Unknown";
        osVersion = "IOS${iosInfo.systemVersion ?? "Unknown"}";
        deviceMake = 'ios';
        deviceModel = iosInfo.utsname.machine ?? "Unknown";
        imei = iosInfo.identifierForVendor ?? "";
      }
    } catch (e) {
      // Fallback values if device info fails
      deviceType = "Unknown";
      osVersion = "Unknown";
      deviceMake = Platform.isIOS ? "ios" : "Android";
      deviceModel = "Unknown";
      imei = "";
    }
  }

  // Method to handle Firebase phone verification with callback
  Future<String> sendFirebaseOTP(String mobileNo, Function(String verificationId) onCodeSent, Function(String error) onError) async {
    
    // Bypass numbers - skip Firebase OTP and return mock verification ID
    final bypassNumbers = <String>[];
    final normalizedPhone = mobileNo.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (bypassNumbers.contains(normalizedPhone) || bypassNumbers.any((bypass) => normalizedPhone.endsWith(bypass.replaceAll('+', '')))) {
      
      // Return a mock verification ID for bypass numbers
      final mockVerificationId = 'BYPASS_VERIFICATION_ID_${mobileNo.replaceAll(RegExp(r'[^0-9]'), '')}';
      onCodeSent(mockVerificationId);
      return mockVerificationId;
    }
    
    try {
      // Check if Firebase is initialized
      try {
        FirebaseAuth.instance;
      } catch (e) {
        onError('Firebase is not initialized. Please restart the app.');
        return '';
      }
      
      // Check if Firebase app is initialized
      try {
        FirebaseApp app = Firebase.app();
      } catch (e) {
        onError('Firebase app is not initialized. Please restart the app.');
        return '';
      }
      
      FirebaseAuth auth = FirebaseAuth.instance;
      
      // Format phone number - ensure it starts with + and contains only valid characters
      String formattedPhone = mobileNo.trim();
      
      
      // Remove any spaces, dashes, or other formatting characters
      formattedPhone = formattedPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      
      // Ensure it starts with +
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+$formattedPhone';
      }
      
      
      // Validate the format: should be + followed by 7-15 digits (E.164 format)
      // E.164 allows 1-15 digits after the country code
      String digitsOnly = formattedPhone.substring(1); // Remove the +
      if (digitsOnly.length < 7 || digitsOnly.length > 15) {
        onError('Phone number must be between 7 and 15 digits (including country code).');
        return '';
      }
      
      if (!RegExp(r'^\+\d+$').hasMatch(formattedPhone)) {
        onError('Phone number can only contain digits after the country code.');
        return '';
      }
      
      String? verificationId;
      bool codeSentSuccessfully = false;
      
      
      // Since APNs is already configured (notifications working), we can use the same implementation
      await auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMsg = e.message ?? 'Unknown error';
          String errorCode = e.code ?? 'unknown';
          
          
          // Handle specific error codes
          if (errorCode == 'too-many-requests') {
            onError('Too many verification attempts from this device.\n\nFirebase has temporarily blocked requests due to unusual activity.\n\nPlease wait 1-2 hours before trying again, or use a different device/phone number for testing.');
          } else if (errorCode == 'internal-error') {
            if (Platform.isIOS) {
              onError('Phone authentication error on iOS.\n\nMost common causes:\n1. Testing on iOS Simulator (Phone Auth does NOT work on simulator - use real device)\n2. APNs not configured for Phone Auth\n3. Invalid provisioning profile\n\n⚠️ CRITICAL: Test on a REAL iPhone/iPad, NOT simulator!\n\nSee FIREBASE_PHONE_AUTH_SETUP.md for detailed steps.');
            } else {
              onError('Phone authentication error. Please try again or contact support.');
            }
          } else if (errorCode == 'invalid-phone-number' || errorCode == 'invalid-verification-code') {
            onError('Invalid phone number format. Please check the country code and phone number.');
          } else if (errorCode == 'quota-exceeded' || errorMsg.contains('quota')) {
            onError('SMS quota exceeded. Please try again later or contact support.');
          } else if (errorMsg.contains('invalid') || errorMsg.contains('format') || errorCode.contains('invalid')) {
            onError('Invalid phone number format. Please check and try again. Error: $errorCode');
          } else if (errorMsg.contains('network') || errorMsg.contains('connection') || errorCode.contains('network')) {
            onError('Network error. Please check your connection and try again.');
          } else {
            onError('Verification failed: $errorMsg (Code: $errorCode)');
          }
        },
        codeSent: (String verId, int? resendToken) {
          verificationId = verId;
          codeSentSuccessfully = true;
          onCodeSent(verId);
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
      );
      
      
      // If code was sent successfully, return the verification ID even if it's null
      // The callback has already been called, so we don't need to wait
      if (codeSentSuccessfully) {
        return verificationId ?? '';
      }
      
      return verificationId ?? '';
    } catch (e) {
      
      // Check if OTP was already sent (codeSent callback might have been called)
      // If so, don't show error to user since OTP was successfully sent
      if (e.toString().contains('TimeoutException') || 
          e.toString().contains('timeout') ||
          e.toString().contains('Future') ||
          e.toString().contains('async')) {
        // These are likely timeout or async completion issues, not actual failures
        // If codeSent was called, the OTP was sent successfully
        // Don't call onError if this is just a timeout/async issue
        // The codeSent callback would have already been called
        return '';
      }
      
      String errorMsg = 'Failed to send OTP: $e';
      if (Platform.isIOS && (e.toString().contains('nil') || e.toString().contains('APNs'))) {
        errorMsg = 'iOS Phone Auth requires APNs configuration. Please configure APNs in Firebase Console → Project Settings → Cloud Messaging → Upload APNs Authentication Key.';
      }
      onError(errorMsg);
      return '';
    } finally {
    }
  }
  Future<http.Response> postOTP(String otpNo, String verificationId, String mobileNo, BuildContext context) async {
    try {
      // Bypass numbers - skip Firebase verification
      final bypassNumbers = <String>[];
      final normalizedPhone = mobileNo.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
      final isBypass = bypassNumbers.contains(normalizedPhone) || 
                       bypassNumbers.any((bypass) => normalizedPhone.endsWith(bypass.replaceAll('+', ''))) ||
                       verificationId.startsWith('BYPASS_');
      
      String? idToken;
      
      if (isBypass) {
        // Use a mock token - backend will bypass verification for this number
        idToken = 'BYPASS_TOKEN_${mobileNo.replaceAll(RegExp(r'[^0-9]'), '')}';
      } else {
        FirebaseAuth auth = FirebaseAuth.instance;
        
        // Create credential from verification ID and OTP
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: otpNo,
        );
        
        // Sign in with credential to verify OTP
        UserCredential userCredential = await auth.signInWithCredential(credential);
        
        // Get Firebase ID token
        idToken = await userCredential.user?.getIdToken();
        
        if (idToken == null) {
          throw Exception('Failed to get Firebase ID token');
        }
        
      }
      
      // Format phone number with country code for backend
      String formattedPhone = mobileNo.trim();
      if (!formattedPhone.startsWith('+')) {
        if (formattedPhone.length == 10) {
          formattedPhone = '+1$formattedPhone';
        } else if (formattedPhone.length == 11 && formattedPhone.startsWith('1')) {
          formattedPhone = '+$formattedPhone';
        } else {
          formattedPhone = '+1$formattedPhone';
        }
      }
      
      
      // Send Firebase ID token to backend for verification and user creation
      return apiFuntions.postdatauser(context, Constant.verifyOtp, <String, dynamic>{
        "firebaseIdToken": idToken,
        "mobile": formattedPhone, // Send with country code
        "fcmToken": sharedPreferences.getString(Constant.fbtoken) ?? "",
        "deviceId": imei
      });
    } catch (e) {
      // Return error response
      return http.Response(
        '{"status": "error", "message": "OTP verification failed: $e"}',
        400,
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  Future<http.Response> postUserDetails(String firstName,String lastName,String email,String profileImage, String id, BuildContext context, {String? locationName, double? lat, double? lng}) {
        Map<String, dynamic> payload = {
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "image": profileImage
        };
        
        // Add location if provided
        if (locationName != null && lat != null && lng != null) {
          payload["location"] = {
            "name": locationName,
            "coordinates": {
              "lat": lat,
              "long": lng
            }
          };
        }
        
        return apiFuntions.putdatauser(context, "${Constant.updateUserDetails}$id", payload);
  }
  Future<http.Response> postImage(List<File> file, BuildContext context, {bool skipAutoNavigation = false}) {
        return apiFuntions.sendMultipartRequest(context, Constant.uploadFile, file, <String , dynamic>{}, skipAutoNavigation: skipAutoNavigation);
  }
  Future<http.Response> getUserDetails(BuildContext context) {
        return apiFuntions.getdatauser(context, Constant.getUserDetails);
  }

  Future<http.Response> markTourShown(BuildContext context) async {
    // Use the existing update-details endpoint as a workaround since the new endpoint may not be deployed
    try {
      String? userId = sharedPreferences.getString(Constant.UserID);
      if (userId == null || userId.isEmpty) {
        // If userId is not available, try to get it from user details
        final userDetailsResponse = await getUserDetails(context);
        if (userDetailsResponse.statusCode == 200) {
          final jsonData = jsonDecode(userDetailsResponse.body);
          if (jsonData['status'] == 'success' && jsonData['data'] != null && jsonData['data'].isNotEmpty) {
            userId = jsonData['data'][0]['_id']?.toString();
          }
        }
      }
      
      if (userId == null || userId.isEmpty) {
        return http.Response('{"status":"error","message":"User ID not found"}', 400);
      }
      
      // First get current user details to preserve existing data
      Map<String, dynamic> payload = {};
      final currentUserResponse = await getUserDetails(context);
      if (currentUserResponse.statusCode == 200) {
        final jsonData = jsonDecode(currentUserResponse.body);
        if (jsonData['status'] == 'success' && jsonData['data'] != null && jsonData['data'].isNotEmpty) {
          final userData = jsonData['data'][0];
          // Preserve all existing user data
          payload['firstName'] = userData['firstName'] ?? "";
          payload['lastName'] = userData['lastName'] ?? "";
          if (userData['email'] != null) payload['email'] = userData['email'];
          if (userData['image'] != null) payload['image'] = userData['image'];
          if (userData['location'] != null) payload['location'] = userData['location'];
        }
      } else {
        // Fallback if we can't get user details - use empty strings for required fields
        payload['firstName'] = "";
        payload['lastName'] = "";
      }
      
      // Always set tour_shown to true (even if field doesn't exist in user object)
      payload['tour_shown'] = true;
      
      return apiFuntions.putdatauser(context, "${Constant.updateUserDetails}$userId", payload);
    } catch (e) {
      return http.Response('{"status":"error","message":"$e"}', 500);
    }
  }



}
