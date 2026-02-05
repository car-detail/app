class Constant {
  // Updated base URL with /api prefix - requires full app restart (not hot reload)
  static var baseurl = "http://localhost:7007/api/"; //dev
  // static var baseurl = "https://l3ww2hjs-7007.inc1.devtunnels.ms/";
  // static var baseurl = "http://13.234.217.235:3001/api/"; //dev
  //static var baseurl = "https://cp6zsf8t-7007.inc1.devtunnels.ms/"; //dev
  // static var baseurl = "https://cf5f40e34c76.ngrok-free.app/"; //ngrok tunnel
  static var versionNumber = "v1";

  //static var generateOTP = "auth/otp-generate-vendor/bypass";
  //static var verifyOtp = "auth/otp-verify-vendor/bynt                                                                                                                                      pass";
  static var generateOTP = "auth/otp-generate-vendor";
  static var verifyOtp = "auth/otp-verify-vendor";
  static var forceUpdate = "cahrz-vendor-versions";

  static var getUserDetails = "$versionNumber/user/get-vendor-details";
  static var deleteUserApiUrl = "$versionNumber/user/vendor-user/";
  static var updateUserDetails = "$versionNumber/user/update-details/";
  static var category = "$versionNumber/category";
  static var getServicesList = "$versionNumber/services/vendor/";
  static var getOffer = "$versionNumber/offers/get-offers/";
  static var getNotifications = "$versionNumber/notification?limit=100&page=1&userId=";
  static var makeOffLine = "$versionNumber/vendor/update-shop-status/";
  static var getdetailsVendeor = "$versionNumber/vendor/";
  static var getOfferByServiceId = "$versionNumber/offers/get-offers-service/";
  static var postOfferUpdate = "$versionNumber/offers/toggle-offer/";
  static var offerDelete = "$versionNumber/offers/delete-offer/";
  static var getAllService = "$versionNumber/services/get-all-services?";
  static var getVendorDetails = "$versionNumber/vendor/my-business";
  static var updateVendor = "$versionNumber/vendor/update_vendor/";
  static var serviceDetails = "$versionNumber/services/service-details/";
  static var getBookingList = "$versionNumber/bookings/get-bookings/";
  static var completeBooking = "$versionNumber/bookings/complete-booking/";
  static var cancelBooking = "$versionNumber/bookings/cancel-vendor/";
  static var captureVendor = "$versionNumber/vendor/capture-vendor-service";
  //static var captureVendor = "${versionNumber}/vendor/capture-vendor";
  static var uploadFile = "$versionNumber/upload/file";
  static var addServices = "$versionNumber/services/add-service";
  static var updateService = "$versionNumber/services/update-service/";
  static var addOffer = "$versionNumber/offers/add-offer";
  static var addRating = "$versionNumber/ratings-review/add-rating-review";
  static var editRating = "$versionNumber/ratings-review/edit-rating-review/";
  static var getReviewRate = "$versionNumber/ratings-review/get-reviews/";
  
  // Package APIs
  static var createPackage = "$versionNumber/packages/create-package";
  static var getAllPackages = "$versionNumber/packages";
  static var getVendorPackages = "$versionNumber/packages/vendor/";
  static var updatePackage = "$versionNumber/packages/update-package";
  static var deletePackage = "$versionNumber/packages/delete-package";
  static var markTourShown = "$versionNumber/user/mark-tour-shown";

  static double textsise14 = 14;

  /// Key prefix for storing Firebase force-resend token per phone (avoids reCAPTCHA after first verification).
  static String firebasePhoneResendTokenPrefix = "firebase_phone_resend_";

  static String navid = "navid";
  static String roleType = "roleType";
  static String rupee = "₹";
  static String fbtoken = "fbtoken";
  static String UserID = "UserID";

  static String accessToken = "accessToken";
  static String refreshToken = "refreshToken";
  static String refreshTokenExpireTime = "refreshTokenExpireTime";

  static String firstName = "firstName";
  static String lastName = "lastName";
  static String image = "image";
  static String email = "email";
  static String isEmailVerified = "isEmailVerified";
  static String mobile = "mobile";
  static String isNewUser = "isNewUser";
  static String roleName = "roleName";
  static String id = "id";
  static String vendorId = "vendorId";
  static String location = "location";
  static String long = "long";
  static String lat = "lat";
}
