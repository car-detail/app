class EditVendorBean {
  String? status;
  String? message;
  int? statusCode;
  List<EditVendorData>? data;

  EditVendorBean({this.status, this.message, this.statusCode, this.data});

  EditVendorBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    if (json['data'] != null) {
      data = <EditVendorData>[];
      json['data'].forEach((v) {
        data!.add(new EditVendorData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['statusCode'] = this.statusCode;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class EditVendorData {
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

  EditVendorData(
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

  EditVendorData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
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
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
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
