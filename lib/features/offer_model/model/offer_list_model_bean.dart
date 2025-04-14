class OfferListModelBean {
  String? status;
  String? message;
  int? statusCode;
  List<OfferListModelData>? data;

  OfferListModelBean({this.status, this.message, this.statusCode, this.data});

  OfferListModelBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    if (json['data'] != null) {
      data = <OfferListModelData>[];
      json['data'].forEach((v) {
        data!.add(new OfferListModelData.fromJson(v));
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

class OfferListModelData {
  String? sId;
  bool? isActive;
  bool? isDelete;
  String? createdBy;
  String? updatedBy;
  String? createdAt;
  String? title;
  String? description;
  String? image;
  int? discount;
  String? vendor;
  Service? service;
  Location? location;
  bool isCurrentlyActive = false;
  String? validFrom;
  String? validUntil;
  String? updatedAt;
  int? iV;

  OfferListModelData(
      {this.sId,
        this.isActive,
        this.isDelete,
        this.createdBy,
        this.updatedBy,
        this.createdAt,
        this.title,
        this.description,
        this.image,
        this.discount,
        this.vendor,
        this.service,
        this.location,
        isCurrentlyActive,
        this.validFrom,
        this.validUntil,
        this.updatedAt,
        this.iV});

  OfferListModelData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    isActive = json['isActive'];
    isDelete = json['isDelete'];
    createdBy = json['createdBy'];
    updatedBy = json['updatedBy'];
    createdAt = json['createdAt'];
    title = json['title'];
    description = json['description'];
    image = json['image'];
    discount = json['discount'];
    vendor = json['vendor'];
    service =
    json['service'] != null ? new Service.fromJson(json['service']) : null;
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    isCurrentlyActive = json['isCurrentlyActive'];
    validFrom = json['validFrom'];
    validUntil = json['validUntil'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['isActive'] = this.isActive;
    data['isDelete'] = this.isDelete;
    data['createdBy'] = this.createdBy;
    data['updatedBy'] = this.updatedBy;
    data['createdAt'] = this.createdAt;
    data['title'] = this.title;
    data['description'] = this.description;
    data['image'] = this.image;
    data['discount'] = this.discount;
    data['vendor'] = this.vendor;
    if (this.service != null) {
      data['service'] = this.service!.toJson();
    }
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['isCurrentlyActive'] = this.isCurrentlyActive;
    data['validFrom'] = this.validFrom;
    data['validUntil'] = this.validUntil;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Service {
  String? sId;
  String? serviceTitle;
  String? about;
  String? timeSlotCapacity;
  int? price;
  String? serviceDuration;
  String? categoryName;
  String? categoryId;
  List<String>? detailImages;
  String? coverImage;
  String? mobile;
  Location? location;
  String? createdBy;
  VendorId? vendorId;
  int? promotionPlanPrice;
  int? promotionSerialNumber;
  bool? isActive;
  bool? isDeleted;
  List<TimeSlots>? timeSlots;
  String? createdAt;
  String? updatedAt;
  int? iV;
  num? averageRating;
  int? totalReviews;
  String? id;

  Service(
      {this.sId,
        this.serviceTitle,
        this.about,
        this.timeSlotCapacity,
        this.price,
        this.serviceDuration,
        this.categoryName,
        this.categoryId,
        this.detailImages,
        this.coverImage,
        this.mobile,
        this.location,
        this.createdBy,
        this.vendorId,
        this.promotionPlanPrice,
        this.promotionSerialNumber,
        this.isActive,
        this.isDeleted,
        this.timeSlots,
        this.createdAt,
        this.updatedAt,
        this.iV,
        this.averageRating,
        this.totalReviews,
        this.id});

  Service.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    serviceTitle = json['serviceTitle'];
    about = json['about'];
    timeSlotCapacity = json['timeSlotCapacity'];
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
    if (json['timeSlots'] != null) {
      timeSlots = <TimeSlots>[];
      json['timeSlots'].forEach((v) {
        timeSlots!.add(new TimeSlots.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    averageRating = json['average_rating'];
    totalReviews = json['total_reviews'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['serviceTitle'] = this.serviceTitle;
    data['about'] = this.about;
    data['timeSlotCapacity'] = this.timeSlotCapacity;
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
    if (this.timeSlots != null) {
      data['timeSlots'] = this.timeSlots!.map((v) => v.toJson()).toList();
    }
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    data['average_rating'] = this.averageRating;
    data['total_reviews'] = this.totalReviews;
    data['id'] = this.id;
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

  VendorId(
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

  VendorId.fromJson(Map<String, dynamic> json) {
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

class TimeSlots {
  String? slot;
  int? capacity;
  int? booked;
  String? sId;
  String? id;

  TimeSlots({this.slot, this.capacity, this.booked, this.sId, this.id});

  TimeSlots.fromJson(Map<String, dynamic> json) {
    slot = json['slot'];
    capacity = json['capacity'];
    booked = json['booked'];
    sId = json['_id'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['slot'] = this.slot;
    data['capacity'] = this.capacity;
    data['booked'] = this.booked;
    data['_id'] = this.sId;
    data['id'] = this.id;
    return data;
  }
}
