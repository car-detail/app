class ServicesListBean {
  String? status;
  String? message;
  int? statusCode;
  List<ServicesListData>? data;

  ServicesListBean({this.status, this.message, this.statusCode, this.data});

  ServicesListBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    if (json['data'] != null) {
      data = <ServicesListData>[];
      json['data'].forEach((v) {
        data!.add(ServicesListData.fromJson(v));
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

class ServicesListData {
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
  List<Offers> offers = [];
  String? id;

  ServicesListData(
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
        offers,
        this.id});

  ServicesListData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    serviceTitle = json['serviceTitle'];
    about = json['about'];
    // Handle fields safely with type checking
    timeSlotCapacity = json['timeSlotCapacity']?.toString();
    price = json['price'] is num ? (json['price'] as num).toInt() : (json['price'] is String ? int.tryParse(json['price']) : 0);
    serviceDuration = json['serviceDuration']?.toString();
    categoryName = json['categoryName']?.toString();
    categoryId = json['categoryId']?.toString();
    // Handle detailImages safely - it might be null, empty, or a list
    if (json['detailImages'] != null) {
      if (json['detailImages'] is List) {
        detailImages = List<String>.from(json['detailImages']);
      } else {
        detailImages = [];
      }
    } else {
      detailImages = [];
    }
    
    // Handle coverImage safely
    if (json['coverImage'] != null && json['coverImage'] is String) {
      coverImage = json['coverImage'];
    } else if (json['serviceImage'] != null && json['serviceImage'] is String) {
      coverImage = json['serviceImage'];
    } else {
      coverImage = "";
    }
    mobile = json['mobile']?.toString();
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
    if (json['offers'] != null) {
      offers = <Offers>[];
      json['offers'].forEach((v) {
        offers.add(Offers.fromJson(v));
      });
    }
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
    data['offers'] = offers.map((v) => v.toJson()).toList();
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
        ? Location.fromJson(json['location'])
        : null;
    openTime = json['openTime'];
    closeTime = json['closeTime'];
    isShopOpen = json['isShopOpen'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['displayName'] = displayName;
    data['mobile'] = mobile;
    data['displayPicture'] = displayPicture;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['openTime'] = openTime;
    data['closeTime'] = closeTime;
    data['isShopOpen'] = isShopOpen;
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

class Offers {
  String? sId;
  String? title;
  String? description;
  String? image;
  num? discount;
  String? service;
  String? validUntil;

  Offers(
      {this.sId,
        this.title,
        this.description,
        this.image,
        this.discount,
        this.service,
        this.validUntil});

  Offers.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    title = json['title'];
    description = json['description'];
    image = json['image'];
    discount = json['discount'];
    service = json['service'];
    validUntil = json['validUntil'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['title'] = title;
    data['description'] = description;
    data['image'] = image;
    data['discount'] = discount;
    data['service'] = service;
    data['validUntil'] = validUntil;
    return data;
  }
}
