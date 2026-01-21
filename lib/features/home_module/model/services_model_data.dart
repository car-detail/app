class ServicesModelData {
  String? status;
  String? message;
  int? statusCode;
  List<ServicesData>? data;

  ServicesModelData({this.status, this.message, this.statusCode, this.data});

  ServicesModelData.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    if (json['data'] != null) {
      data = <ServicesData>[];
      if (json['data'] is List) {
        for (var v in (json['data'] as List)) {
          data!.add(ServicesData.fromJson(v));
        }
      } else {
      }
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

class ServicesData {
  String? sId;
  String? serviceTitle;
  String? about;
  String? description;
  int? price;
  String? serviceDuration;
  String? categoryName;
  String? coverImage;
  String? mobile;
  Location? location;
  String? vendorImage;
  String? vendorName;
  String? vendorMobile;

  ServicesData(
      {this.sId,
        this.serviceTitle,
        this.about,
        this.description,
        this.price,
        this.serviceDuration,
        this.categoryName,
        this.coverImage,
        this.mobile,
        this.location,
        this.vendorImage,
        this.vendorName,
        this.vendorMobile});

  ServicesData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'] ?? json['sId'] ?? json['id'];
    serviceTitle = json['serviceTitle'];
    about = json['about'];
    description = json['description'];
    price = json['price'] is int ? json['price'] : (json['price'] is String ? int.tryParse(json['price']) : null);
    serviceDuration = json['serviceDuration'];
    categoryName = json['categoryName'];
    coverImage = json['coverImage'];
    mobile = json['mobile'];
    location = json['location'] != null
        ? Location.fromJson(json['location'])
        : null;
    vendorImage = json['vendorImage'];
    vendorName = json['vendorName'];
    vendorMobile = json['vendorMobile'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['serviceTitle'] = serviceTitle;
    data['about'] = about;
    data['price'] = price;
    data['serviceDuration'] = serviceDuration;
    data['categoryName'] = categoryName;
    data['coverImage'] = coverImage;
    data['mobile'] = mobile;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['vendorImage'] = vendorImage;
    data['vendorName'] = vendorName;
    data['vendorMobile'] = vendorMobile;
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
  double? lat;
  double? long;

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
