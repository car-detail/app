class VendorDetailBean {
  String? status;
  String? message;
  int? statusCode;
  List<VendorDetailData>? data;

  VendorDetailBean({this.status, this.message, this.statusCode, this.data});

  VendorDetailBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    if (json['data'] != null) {
      data = <VendorDetailData>[];
      json['data'].forEach((v) {
        data!.add(VendorDetailData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    data['statusCode'] = statusCode;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VendorDetailData {
  String? sId;
  String? firstName;
  String? lastName;
  String? image;
  String? email;
  String? mobile;
  bool? isNewUser;
  String? roleName;
  List<VendorDetails>? vendorDetails;

  VendorDetailData(
      {this.sId,
        this.firstName,
        this.lastName,
        this.image,
        this.email,
        this.mobile,
        this.isNewUser,
        this.roleName,
        this.vendorDetails});

  VendorDetailData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    image = json['image'];
    email = json['email'];
    mobile = json['mobile'];
    isNewUser = json['isNewUser'];
    roleName = json['roleName'];
    if (json['vendorDetails'] != null) {
      vendorDetails = <VendorDetails>[];
      json['vendorDetails'].forEach((v) {
        vendorDetails!.add(VendorDetails.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['image'] = image;
    data['email'] = email;
    data['mobile'] = mobile;
    data['isNewUser'] = isNewUser;
    data['roleName'] = roleName;
    if (vendorDetails != null) {
      data['vendorDetails'] =
          vendorDetails!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VendorDetails {
  String? sId;
  String? displayName;
  String? officialEmail;
  String? mobile;
  String? displayPicture;
  Location? location;
  String? openTime;
  String? closeTime;
  String? timeZone;
  String? createdBy;
  bool? isActive;
  bool? isDeleted;
  bool? isShopOpen;
  bool? isVerified;
  String? createdAt;
  String? updatedAt;
  int? iV;

  VendorDetails(
      {this.sId,
        this.displayName,
        this.officialEmail,
        this.mobile,
        this.displayPicture,
        this.location,
        this.openTime,
        this.closeTime,
        this.timeZone,
        this.createdBy,
        this.isActive,
        this.isDeleted,
        this.isShopOpen,
        this.isVerified,
        this.createdAt,
        this.updatedAt,
        this.iV});

  VendorDetails.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    displayName = json['displayName'];
    officialEmail = json['officialEmail'];
    mobile = json['mobile'];
    displayPicture = json['displayPicture'];
    location = json['location'] != null
        ? Location.fromJson(json['location'])
        : null;
    openTime = json['openTime'];
    closeTime = json['closeTime'];
    timeZone = json['timeZone'];
    createdBy = json['createdBy'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    isShopOpen = json['isShopOpen'];
    isVerified = json['isVerified'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['displayName'] = displayName;
    data['officialEmail'] = officialEmail;
    data['mobile'] = mobile;
    data['displayPicture'] = displayPicture;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['openTime'] = openTime;
    data['closeTime'] = closeTime;
    data['timeZone'] = timeZone;
    data['createdBy'] = createdBy;
    data['isActive'] = isActive;
    data['isDeleted'] = isDeleted;
    data['isShopOpen'] = isShopOpen;
    data['isVerified'] = isVerified;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}

class Location {
  String? name;
  Coordinates? coordinates;

  Location({this.name, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    coordinates = json['coordinates'] != null
        ? Coordinates.fromJson(json['coordinates'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (coordinates != null) {
      data['coordinates'] = coordinates!.toJson();
    }
    return data;
  }
}

class Coordinates {
  num? lat;
  num? long;

  Coordinates({this.lat, this.long});

  Coordinates.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    long = json['long'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lat'] = lat;
    data['long'] = long;
    return data;
  }
}
