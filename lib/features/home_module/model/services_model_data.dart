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
      json['data'].forEach((v) {
        data!.add(new ServicesData.fromJson(v));
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

class ServicesData {
  String? sId;
  String? serviceTitle;
  String? about;
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
    sId = json['_id'];
    serviceTitle = json['serviceTitle'];
    about = json['about'];
    price = json['price'];
    serviceDuration = json['serviceDuration'];
    categoryName = json['categoryName'];
    coverImage = json['coverImage'];
    mobile = json['mobile'];
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    vendorImage = json['vendorImage'];
    vendorName = json['vendorName'];
    vendorMobile = json['vendorMobile'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['serviceTitle'] = this.serviceTitle;
    data['about'] = this.about;
    data['price'] = this.price;
    data['serviceDuration'] = this.serviceDuration;
    data['categoryName'] = this.categoryName;
    data['coverImage'] = this.coverImage;
    data['mobile'] = this.mobile;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['vendorImage'] = this.vendorImage;
    data['vendorName'] = this.vendorName;
    data['vendorMobile'] = this.vendorMobile;
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
