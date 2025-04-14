class Constant {
  static var baseurl = "http://13.232.212.175:7007/"; //dev
  static var versionNumber = "v1";

  static var generateOTP = "auth/otp-generate-vendor/bypass";
  static var verifyOtp = "auth/otp-verify-vendor/bypass";
  static var getUserDetails = "${versionNumber}/user/get-vendor-details";
  static var updateUserDetails = "${versionNumber}/user/update-details/";
  static var category = "${versionNumber}/category";
  static var getServicesList = "${versionNumber}/services/services-by-vendor/";
  static var getOffer = "${versionNumber}/offers/get-offers/";
  static var makeOffLine = "${versionNumber}/vendor/update-shop-status/";
  static var getdetailsVendeor = "${versionNumber}/vendor/";
  static var getOfferByServiceId = "${versionNumber}/offers/get-offers-service/";
  static var postOfferUpdate = "${versionNumber}/offers/toggle-offer/";
  static var offerDelete = "${versionNumber}/offers/delete-offer/";
  static var getAllService = "${versionNumber}/services/get-all-services?";
  static var getVendorDetails = "${versionNumber}/vendor/my-business";
  static var updateVendor = "${versionNumber}/vendor/update_vendor/";
  static var serviceDetails = "${versionNumber}/services/service-details/";
  static var getBookingList = "${versionNumber}/bookings/get-bookings/";
  static var completeBooking = "${versionNumber}/bookings/complete-booking/";
  static var cancelBooking = "${versionNumber}/bookings/cancel-vendor/";
  static var captureVendor = "${versionNumber}/vendor/capture-vendor-service";
  //static var captureVendor = "${versionNumber}/vendor/capture-vendor";
  static var uploadFile = "${versionNumber}/upload/file";
  static var addServices = "${versionNumber}/services/add-service";
  static var addOffer = "${versionNumber}/offers/add-offer";
  static var addRating = "${versionNumber}/ratings-review/add-rating-review";
  static var editRating = "${versionNumber}/ratings-review/edit-rating-review/";
  static var getReviewRate = "${versionNumber}/ratings-review/get-reviews/";

  static double textsise14 = 14;

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
