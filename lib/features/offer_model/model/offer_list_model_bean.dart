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
        data!.add(OfferListModelData.fromJson(v));
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
  num? discount;
  String? vendor;
  Service? service;
  Location? location;
  bool isCurrentlyActive = false;
  String? validFrom;
  String? validUntil;
  String? updatedAt;
  int? iV;
  int? viewCount;
  int? claimCount;

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
        this.isCurrentlyActive,
        this.validFrom,
        this.validUntil,
        this.updatedAt,
        this.viewCount,
        this.claimCount,
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
    json['service'] != null ? Service.fromJson(json['service']) : null;
    location = json['location'] != null
        ? Location.fromJson(json['location'])
        : null;
    isCurrentlyActive = json['isCurrentlyActive'] ?? json['isActive'] ?? true;
    validFrom = json['validFrom'];
    validUntil = json['validUntil'];
    updatedAt = json['updatedAt'];
    viewCount = json['viewCount'] ?? 0;
    claimCount = json['claimCount'] ?? 0;
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['isActive'] = isActive;
    data['isDelete'] = isDelete;
    data['createdBy'] = createdBy;
    data['updatedBy'] = updatedBy;
    data['createdAt'] = createdAt;
    data['title'] = title;
    data['description'] = description;
    data['image'] = image;
    data['discount'] = discount;
    data['vendor'] = vendor;
    if (service != null) {
      data['service'] = service!.toJson();
    }
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['isCurrentlyActive'] = isCurrentlyActive;
    data['validFrom'] = validFrom;
    data['validUntil'] = validUntil;
    data['updatedAt'] = updatedAt;
    data['viewCount'] = viewCount;
    data['claimCount'] = claimCount;
    data['__v'] = iV;
    return data;
  }
}

class Service {
  String? sId;
  String? serviceTitle;
  String? about;
  String? timeSlotCapacity;
  num? price;
  String? serviceDuration;
  String? categoryName;
  String? categoryId;
  List<String>? detailImages;
  String? coverImage;
  String? mobile;
  Location? location;
  String? createdBy;
  VendorId? vendorId;
  num? promotionSerialNumber;
  num? promotionPlanPrice;
  bool? isActive;
  bool? isDeleted;
  List<TimeSlots>? timeSlots;
  String? createdAt;
  String? updatedAt;
  int? iV;
  num? averageRating;
  num? totalReviews;
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
        ? Location.fromJson(json['location'])
        : null;
    createdBy = json['createdBy'];
    vendorId = json['vendorId'] != null
        ? VendorId.fromJson(json['vendorId'])
        : null;
    promotionPlanPrice = json['promotionPlanPrice'];
    promotionSerialNumber = json['promotionSerialNumber'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    if (json['timeSlots'] != null) {
      timeSlots = <TimeSlots>[];
      json['timeSlots'].forEach((v) {
        timeSlots!.add(TimeSlots.fromJson(v));
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['serviceTitle'] = serviceTitle;
    data['about'] = about;
    data['timeSlotCapacity'] = timeSlotCapacity;
    data['price'] = price;
    data['serviceDuration'] = serviceDuration;
    data['categoryName'] = categoryName;
    data['categoryId'] = categoryId;
    data['detailImages'] = detailImages;
    data['coverImage'] = coverImage;
    data['mobile'] = mobile;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['createdBy'] = createdBy;
    if (vendorId != null) {
      data['vendorId'] = vendorId!.toJson();
    }
    data['promotionPlanPrice'] = promotionPlanPrice;
    data['promotionSerialNumber'] = promotionSerialNumber;
    data['isActive'] = isActive;
    data['isDeleted'] = isDeleted;
    if (timeSlots != null) {
      data['timeSlots'] = timeSlots!.map((v) => v.toJson()).toList();
    }
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    data['average_rating'] = averageRating;
    data['total_reviews'] = totalReviews;
    data['id'] = id;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['slot'] = slot;
    data['capacity'] = capacity;
    data['booked'] = booked;
    data['_id'] = sId;
    data['id'] = id;
    return data;
  }
}
