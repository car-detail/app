class AddServicesBean {
  String? status;
  String? message;
  int? statusCode;
  AddServicesData? data;

  AddServicesBean({this.status, this.message, this.statusCode, this.data});

  AddServicesBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    data = json['data'] != null ? new AddServicesData.fromJson(json['data']) : null;
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

class AddServicesData {
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
  String? vendorId;
  int? promotionPlanPrice;
  int? promotionSerialNumber;
  bool? isActive;
  bool? isDeleted;
  List<TimeSlots>? timeSlots;
  String? sId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  AddServicesData(
      {this.serviceTitle,
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
        this.sId,
        this.createdAt,
        this.updatedAt,
        this.iV});

  AddServicesData.fromJson(Map<String, dynamic> json) {
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
    vendorId = json['vendorId'];
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
    sId = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
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
    data['vendorId'] = this.vendorId;
    data['promotionPlanPrice'] = this.promotionPlanPrice;
    data['promotionSerialNumber'] = this.promotionSerialNumber;
    data['isActive'] = this.isActive;
    data['isDeleted'] = this.isDeleted;
    if (this.timeSlots != null) {
      data['timeSlots'] = this.timeSlots!.map((v) => v.toJson()).toList();
    }
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

class TimeSlots {
  String? slot;
  int? capacity;
  int? booked;
  String? sId;

  TimeSlots({this.slot, this.capacity, this.booked, this.sId});

  TimeSlots.fromJson(Map<String, dynamic> json) {
    slot = json['slot'];
    capacity = json['capacity'];
    booked = json['booked'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['slot'] = this.slot;
    data['capacity'] = this.capacity;
    data['booked'] = this.booked;
    data['_id'] = this.sId;
    return data;
  }
}
