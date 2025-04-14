class BookingModelBean {
  String? status;
  String? message;
  int? statusCode;
  BookingModelData? data;

  BookingModelBean(
      {this.status, this.message, this.statusCode, this.data});

  BookingModelBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    data = json['data'] != null ? new BookingModelData.fromJson(json['data']) : null;
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

class BookingModelData {
  String? sId;
  String? serviceTitle;
  String? about;
  int? price;
  String? serviceDuration;
  String? categoryName;
  String? categoryId;
  List<String> detailImages = [];
  String? coverImage;
  String? mobile;
  Location? location;
  String? createdBy;
  VendorId? vendorId;
  int? promotionPlanPrice;
  int? promotionSerialNumber;
  bool? isActive;
  bool? isDeleted;
  String? createdAt;
  String? updatedAt;
  int? iV;

  BookingModelData(
      {this.sId,
        this.serviceTitle,
        this.about,
        this.price,
        this.serviceDuration,
        this.categoryName,
        this.categoryId,
        detailImages,
        this.coverImage,
        this.mobile,
        this.location,
        this.createdBy,
        this.vendorId,
        this.promotionPlanPrice,
        this.promotionSerialNumber,
        this.isActive,
        this.isDeleted,
        this.createdAt,
        this.updatedAt,
        this.iV});

  BookingModelData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    serviceTitle = json['serviceTitle'];
    about = json['about'];
    price = json['price'];
    serviceDuration = json['serviceDuration'];
    categoryName = json['categoryName'];
    categoryId = json['categoryId'];
    detailImages = json['detailImages'].cast<String>();
    coverImage = json['coverImage'];
    mobile = json['mobile'];
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    createdBy = json['createdBy'];
    vendorId = json['vendorId'] != null
        ? new VendorId.fromJson(json['vendorId'])
        : null;
    promotionPlanPrice = json['promotionPlanPrice'];
    promotionSerialNumber = json['promotionSerialNumber'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['serviceTitle'] = this.serviceTitle;
    data['about'] = this.about;
    data['price'] = this.price;
    data['serviceDuration'] = this.serviceDuration;
    data['categoryName'] = this.categoryName;
    data['categoryId'] = this.categoryId;
    data['detailImages'] = this.detailImages;
    data['coverImage'] = this.coverImage;
    data['mobile'] = this.mobile;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['createdBy'] = this.createdBy;
    if (this.vendorId != null) {
      data['vendorId'] = this.vendorId!.toJson();
    }
    data['promotionPlanPrice'] = this.promotionPlanPrice;
    data['promotionSerialNumber'] = this.promotionSerialNumber;
    data['isActive'] = this.isActive;
    data['isDeleted'] = this.isDeleted;
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
  double? lat;
  double? long;

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

class VendorId {
  String? sId;
  String? displayName;
  String? mobile;
  String? displayPicture;
  Location? location;
  String? openTime;
  String? closeTime;
  bool? isShopOpen;

  VendorId(
      {this.sId,
        this.displayName,
        this.mobile,
        this.displayPicture,
        this.location,
        this.openTime,
        this.closeTime,
        this.isShopOpen});

  VendorId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    displayName = json['displayName'];
    mobile = json['mobile'];
    displayPicture = json['displayPicture'];
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    openTime = json['openTime'];
    closeTime = json['closeTime'];
    isShopOpen = json['isShopOpen'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['displayName'] = this.displayName;
    data['mobile'] = this.mobile;
    data['displayPicture'] = this.displayPicture;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['openTime'] = this.openTime;
    data['closeTime'] = this.closeTime;
    data['isShopOpen'] = this.isShopOpen;
    return data;
  }
}
