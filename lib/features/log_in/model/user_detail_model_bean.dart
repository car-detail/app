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
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
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
        this.iV});

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
    fcmToken = json['fcmToken'].cast<String>();
    deviceId = json['deviceId'];
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
    data['firstName'] = this.firstName;
    data['lastName'] = this.lastName;
    data['image'] = this.image;
    data['email'] = this.email;
    data['isEmailVerified'] = this.isEmailVerified;
    data['mobile'] = this.mobile;
    data['isNewUser'] = this.isNewUser;
    data['roleName'] = this.roleName;
    data['status'] = this.status;
    data['fcmToken'] = this.fcmToken;
    data['deviceId'] = this.deviceId;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}
