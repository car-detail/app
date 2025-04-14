class CaptureVendorBean {
  String? status;
  String? message;
  int? statusCode;
  CaptureVendorData? data;

  CaptureVendorBean({this.status, this.message, this.statusCode, this.data});

  CaptureVendorBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    data = json['data'] != null ? new CaptureVendorData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['statusCode'] = this.statusCode;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class CaptureVendorData {
  NewBusinessData? newBusinessData;
  String? businessUniqueId;

  CaptureVendorData({this.newBusinessData, this.businessUniqueId});

  CaptureVendorData.fromJson(Map<String, dynamic> json) {
    newBusinessData = json['newBusinessData'] != null
        ? new NewBusinessData.fromJson(json['newBusinessData'])
        : null;
    businessUniqueId = json['businessUniqueId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.newBusinessData != null) {
      data['newBusinessData'] = this.newBusinessData!.toJson();
    }
    data['businessUniqueId'] = this.businessUniqueId;
    return data;
  }
}

class NewBusinessData {
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
  String? sId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  NewBusinessData(
      {this.displayName,
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
        this.sId,
        this.createdAt,
        this.updatedAt,
        this.iV});

  NewBusinessData.fromJson(Map<String, dynamic> json) {
    displayName = json['displayName'];
    officialEmail = json['officialEmail'];
    mobile = json['mobile'];
    displayPicture = json['displayPicture'];
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    openTime = json['openTime'];
    closeTime = json['closeTime'];
    timeZone = json['timeZone'];
    createdBy = json['createdBy'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    isShopOpen = json['isShopOpen'];
    isVerified = json['isVerified'];
    sId = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['displayName'] = this.displayName;
    data['officialEmail'] = this.officialEmail;
    data['mobile'] = this.mobile;
    data['displayPicture'] = this.displayPicture;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['openTime'] = this.openTime;
    data['closeTime'] = this.closeTime;
    data['timeZone'] = this.timeZone;
    data['createdBy'] = this.createdBy;
    data['isActive'] = this.isActive;
    data['isDeleted'] = this.isDeleted;
    data['isShopOpen'] = this.isShopOpen;
    data['isVerified'] = this.isVerified;
    data['_id'] = this.sId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
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
        ? new Coordinates.fromJson(json['coordinates'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    if (this.coordinates != null) {
      data['coordinates'] = this.coordinates!.toJson();
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['long'] = this.long;
    return data;
  }
}
