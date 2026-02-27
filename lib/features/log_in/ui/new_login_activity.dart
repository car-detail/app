import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Api/ApiFuntion.dart';
import '../../../Common/BaseActivity.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../data_manager/LoginDataManager.dart';
import '../model/GenerateOTPModelBean.dart';
import '../../dashboard_module/ui/dashboard_activity.dart';
import '../../resister_vendor_model/ui/simple_add_shop_activity.dart';

/// Fresh, clean login screen for vendor app
/// Uses direct API-based authentication without Firebase Phone Auth
class NewLoginActivity extends StatefulWidget {
  const NewLoginActivity({super.key});

  @override
  State<NewLoginActivity> createState() => _NewLoginActivityState();
}

class _NewLoginActivityState extends State<NewLoginActivity> {
  var mobileController = TextEditingController();
  String selectedCountryCode = '+1'; // Default to US
  String selectedCountryIsoCode = 'US';
  ApiFuntions apiFuntions = ApiFuntions();
  LoginDataManager? loginDataManager;
  late SharedPreferences? sharedPreferences;
  bool _isLoading = false;
  bool _isOTPSent = false;
  String _verificationId = '';
  FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _resendTimer;
  int _resendCountdown = 60;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    // Set green status bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: ColorClass.base_color,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    loginDataManager = LoginDataManager(sharedPreferences!);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isOTPSent) {
          setState(() {
            _isOTPSent = false;
          });
          return false;
        }
        if (Navigator.of(context).canPop()) {
          CommonWidget.safePop(context);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header with gradient
                Container(
                  constraints: BoxConstraints(
                    minHeight: 280 + MediaQuery.of(context).padding.top,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorClass.base_color,
                        ColorClass.base_color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            // Back button
                            if (_isOTPSent)
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _isOTPSent = false;
                                  });
                                },
                              ),
                            const SizedBox(height: 60),
                            // Title
                            const Text(
                              "Get Started",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isOTPSent 
                                ? "Enter the verification code" 
                                : "Enter your mobile number to continue",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
                // Login Form
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      
                      if (!_isOTPSent) 
                        // Mobile Number Input with Country Code
                        _buildMobileInput()
                      else
                        // OTP Input
                        _buildOTPInput(),
                      
                      const SizedBox(height: 24),
                      
                      // Action Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : (_isOTPSent ? _verifyOTP : _sendOTP),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorClass.base_color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _isOTPSent ? "Verify OTP" : "Send OTP",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      if (_isOTPSent && _resendCountdown > 0)
                        Center(
                          child: Text(
                            "Resend OTP in $_resendCountdown seconds",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        )
                      else if (_isOTPSent)
                        Center(
                          child: GestureDetector(
                            onTap: _isLoading ? null : _resendOTP,
                            child: Text(
                              "Resend OTP",
                              style: TextStyle(
                                color: _isLoading ? Colors.grey : ColorClass.base_color,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileInput() {
    return Row(
      children: [
        // Country Code Picker
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: CountryCodePicker(
            onChanged: (CountryCode countryCode) {
              setState(() {
                selectedCountryCode = countryCode.dialCode ?? '+1';
                selectedCountryIsoCode = countryCode.code ?? 'US';
              });
            },
            initialSelection: 'US',
            favorite: const ['+1', 'US', '+91', 'IN'],
            showCountryOnly: false,
            showOnlyCountryWhenClosed: false,
            alignLeft: false,
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            dialogTextStyle: const TextStyle(
              fontSize: 16,
            ),
            flagWidth: 24,
            showFlag: true,
            showFlagDialog: true,
            hideMainText: false,
            hideSearch: false,
            boxDecoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Mobile Number Input
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: "1234567890",
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.phone_android,
                  color: ColorClass.base_color,
                  size: 24,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: mobileController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "Enter 6-digit code",
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.lock,
            color: ColorClass.base_color,
            size: 24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        onChanged: (value) {
          if (value.length == 6) {
            // Auto-verify when 6 digits are entered
            _verifyOTP();
          }
        },
      ),
    );
  }

  void _sendOTP() async {
    if (BaseActivity.checkEmptyField(
        editingController: mobileController,
        message: "Please Enter Mobile Number",
        context: context)) {
      return;
    }
    
    // Validate phone number based on country
    Map<String, int> validationRules = _getPhoneValidationRules(selectedCountryIsoCode);
    int minDigits = validationRules['min']!;
    int maxDigits = validationRules['max']!;
    
    String phoneDigits = mobileController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    
    // Remove country code if already included
    String countryCodeDigits = selectedCountryCode.replaceAll(RegExp(r'[^0-9]'), '');
    if (countryCodeDigits.isNotEmpty && phoneDigits.startsWith(countryCodeDigits)) {
      phoneDigits = phoneDigits.substring(countryCodeDigits.length);
    }
    
    if (phoneDigits.length < minDigits || phoneDigits.length > maxDigits) {
      CommonWidget.errorShowSnackBarFor(
        context, 
        "Please enter a valid phone number (${minDigits}-${maxDigits} digits for ${selectedCountryIsoCode})"
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      String digitsOnly = phoneDigits;
      String fullPhoneNumber = '$selectedCountryCode$phoneDigits';
      final resendTokenKey = '${Constant.firebasePhoneResendTokenPrefix}$digitsOnly';
      _resendToken = sharedPreferences?.getInt(resendTokenKey);

      // Use Firebase Phone Auth
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed
          await _signInWithCredential(credential, "");
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          String errorMessage = "Failed to send OTP. ";
          if (e.code == 'invalid-phone-number') {
            errorMessage += "The phone number is invalid.";
          } else {
            errorMessage += e.message ?? "Please try again.";
          }
          CommonWidget.errorShowSnackBarFor(context, errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
            _isOTPSent = true;
            _verificationId = verificationId;
            _resendToken = resendToken;
            mobileController.clear();
          });
          
          if (resendToken != null) {
            String digitsOnly = phoneDigits;
            final resendTokenKey = '${Constant.firebasePhoneResendTokenPrefix}$digitsOnly';
            sharedPreferences?.setInt(resendTokenKey, resendToken);
          }
          
          _startResendTimer();
          CommonWidget.successShowSnackBarFor(context, "OTP sent successfully to $fullPhoneNumber");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timed out
          setState(() {
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      CommonWidget.errorShowSnackBarFor(context, "Error sending OTP: ${e.toString()}");
    }
  }

  void _verifyOTP() async {
    if (BaseActivity.checkEmptyField(
        editingController: mobileController,
        message: "Please Enter OTP",
        context: context)) {
      return;
    }
    
    String otp = mobileController.text.trim();
    if (otp.length != 6) {
      CommonWidget.errorShowSnackBarFor(context, "Please enter a valid 6-digit OTP");
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create phone auth credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      
      // Sign in with credential and exchange for backend token
      await _signInWithCredential(credential, otp);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      String errorMessage = "OTP verification failed. ";
      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-verification-code') {
          errorMessage += "The OTP entered is invalid.";
        } else if (e.code == 'session-expired') {
          errorMessage += "The OTP has expired. Please request a new one.";
        } else {
          errorMessage += e.message ?? "Please try again.";
        }
      } else {
        errorMessage += "Please try again.";
      }
      
      CommonWidget.errorShowSnackBarFor(context, errorMessage);
    }
  }

  void _resendOTP() {
    setState(() {
      _isLoading = true;
    });
    
    // Clear the input field
    mobileController.clear();
    
    // Resend OTP using the same phone number
    _sendOTP();
  }
  
  Future<void> _signInWithCredential(PhoneAuthCredential credential, String otp) async {
    try {
      // 1. Sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // 2. Clear mobile controller (as sign-in succeeded)
        mobileController.clear();

        // 3. Exchange Firebase token for Backend token
        // Get ID token first to avoid redundant sign-in in postOTP
        String? idToken = await userCredential.user!.getIdToken();

        // We call postOTP in LoginDataManager which sends to /auth/otp-verify-vendor
        final response = await loginDataManager!.postOTP(
          otp,
          _verificationId,
          userCredential.user!.phoneNumber ?? "",
          context,
          firebaseIdToken: idToken,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final resData = jsonDecode(response.body);
          if (resData['status'] == 'success') {
            final authData = resData['data'];
            
            // 4. Store Backend Tokens
            await sharedPreferences!.setString(Constant.accessToken, authData['accessToken'] ?? '');
            await sharedPreferences!.setString(Constant.refreshToken, authData['refreshToken'] ?? '');
            await sharedPreferences!.setString(Constant.refreshTokenExpireTime, 
                (authData['refreshTokenExpireTime'] ?? 0).toString());
            
            // 5. Fetch Backend User Details to get the correct UserID/id
            final userDetailsResponse = await loginDataManager!.getUserDetails(context);
            if (userDetailsResponse.statusCode == 200) {
              final userDetailsData = jsonDecode(userDetailsResponse.body);
              if (userDetailsData['status'] == 'success' && 
                  userDetailsData['data'] is List && 
                  (userDetailsData['data'] as List).isNotEmpty) {
                
                final userData = userDetailsData['data'][0];
                
                // 6. Store correct Backend Backend Details
                await sharedPreferences!.setString(Constant.id, userData['_id'] ?? '');
                await sharedPreferences!.setString(Constant.UserID, userData['_id'] ?? '');
                await sharedPreferences!.setString(Constant.firstName, userData['firstName'] ?? '');
                await sharedPreferences!.setString(Constant.lastName, userData['lastName'] ?? '');
                await sharedPreferences!.setString(Constant.email, userData['email'] ?? '');
                await sharedPreferences!.setString(Constant.image, userData['image'] ?? '');
                await sharedPreferences!.setString(Constant.mobile, userData['mobile'] ?? '');
              }
            }

            // 7. Store Role Info
            await sharedPreferences!.setString(Constant.roleType, "vendor");
            await sharedPreferences!.setString(Constant.roleName, "vendor");
            
            // Debug logging
            // Navigator logic follows
            
            // Persist all data
            await sharedPreferences!.reload();
            
            // 8. Check if vendor profile exists
            bool hasVendorProfile = false;
            bool hasServices = false;
            try {
              final vendorResponse = await loginDataManager!.getVendorDetails(context);
              if (vendorResponse.statusCode == 200) {
                final vendorData = jsonDecode(vendorResponse.body);
                if (vendorData['status'] == 'success' && 
                    vendorData['data'] is List && 
                    (vendorData['data'] as List).isNotEmpty) {
                  hasVendorProfile = true;
                  final vData = vendorData['data'][0];
                  final vId = vData['_id'] ?? '';
                  await sharedPreferences!.setString(Constant.vendorId, vId);

                  // 8a. Check if vendor has at least one service
                  if (vId.isNotEmpty) {
                    final servicesResponse = await loginDataManager!.getVendorServices(context, vId);
                    if (servicesResponse.statusCode == 200) {
                      final servicesData = jsonDecode(servicesResponse.body);
                      if (servicesData['status'] == 'success' && 
                          servicesData['data'] is List && 
                          (servicesData['data'] as List).isNotEmpty) {
                        hasServices = true;
                      }
                    }
                  }
                }
              }
            } catch (e) {
              // Fail-safe: if check fails, we'll try to go to dashboard
            }

            setState(() {
              _isLoading = false;
            });
            
            // 9. Navigate to dashboard or shop setup
            if (context.mounted) {
              if (hasVendorProfile && hasServices) {
                CommonWidget.navigateToKillAllScreen(context, DashboardActivity());
              } else {
                // No profile OR profile exists but no services - redirect to add shop
                CommonWidget.navigateToKillAllScreen(context, const SimpleAddShopActivity());
              }
            }
          } else {
            throw Exception(resData['message'] ?? "Backend verification failed");
          }
        } else {
          throw Exception("Server returned ${response.statusCode}");
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      String errorMessage = "Authentication failed. ";
      if (e is FirebaseAuthException) {
        errorMessage += e.message ?? "Please try again.";
      } else {
        errorMessage += e.toString();
      }
      
      CommonWidget.errorShowSnackBarFor(context, errorMessage);
    }
  }

  // Helper method for country-specific phone validation
  Map<String, int> _getPhoneValidationRules(String isoCode) {
    switch (isoCode.toUpperCase()) {
      case 'US': // United States
      case 'CA': // Canada
        return {'min': 10, 'max': 10};
      case 'IN': // India
        return {'min': 10, 'max': 10};
      case 'GB': // United Kingdom
        return {'min': 10, 'max': 11};
      case 'AU': // Australia
        return {'min': 9, 'max': 10};
      case 'DE': // Germany
        return {'min': 10, 'max': 11};
      case 'FR': // France
        return {'min': 9, 'max': 9};
      case 'JP': // Japan
        return {'min': 10, 'max': 10};
      case 'CN': // China
        return {'min': 11, 'max': 11};
      case 'BR': // Brazil
        return {'min': 10, 'max': 11};
      default:
        return {'min': 7, 'max': 15};
    }
  }
}
