class UserDetailsModelBean {
  String? status;
  String? message;
  int? statusCode;
  Data? data;

  UserDetailsModelBean({this.status, this.message, this.statusCode, this.data});

  UserDetailsModelBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    data['statusCode'] = statusCode;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? sId;
  bool? isActive;
  bool? isDelete;
  String? createdBy;
  String? updatedBy;
  String? createdAt;
  String? firstName;
  String? lastName;
  String? image;
  String? email;
  bool? isEmailVerified;
  String? mobile;
  bool? isNewUser;
  String? roleName;
  String? status;
  List<String>? fcmToken;
  String? deviceId;
  String? updatedAt;
  int? iV;
  Location? location;

  Data(
      {this.sId,
        this.isActive,
        this.isDelete,
        this.createdBy,
        this.updatedBy,
        this.createdAt,
        this.firstName,
        this.lastName,
        this.image,
        this.email,
        this.isEmailVerified,
        this.mobile,
        this.isNewUser,
        this.roleName,
        this.status,
        this.fcmToken,
        this.deviceId,
        this.updatedAt,
        this.iV,
        this.location});

  Data.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    isActive = json['isActive'];
    isDelete = json['isDelete'];
    createdBy = json['createdBy'];
    updatedBy = json['updatedBy'];
    createdAt = json['createdAt'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    image = json['image'];
    email = json['email'];
    isEmailVerified = json['isEmailVerified'];
    mobile = json['mobile'];
    isNewUser = json['isNewUser'];
    roleName = json['roleName'];
    status = json['status'];
    fcmToken = json['fcmToken']?.cast<String>();
    deviceId = json['deviceId'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['isActive'] = isActive;
    data['isDelete'] = isDelete;
    data['createdBy'] = createdBy;
    data['updatedBy'] = updatedBy;
    data['createdAt'] = createdAt;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['image'] = image;
    data['email'] = email;
    data['isEmailVerified'] = isEmailVerified;
    data['mobile'] = mobile;
    data['isNewUser'] = isNewUser;
    data['roleName'] = roleName;
    data['status'] = status;
    data['fcmToken'] = fcmToken;
    data['deviceId'] = deviceId;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    return data;
  }
}

class Location {
  String? name;
  Coordinates? coordinates;

  Location({this.name, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    coordinates = json['coordinates'] != null ? Coordinates.fromJson(json['coordinates']) : null;
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
  dynamic lat;
  dynamic long;

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
