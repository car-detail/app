class CompletedModelBean {
  String? status;
  String? message;
  int? statusCode;
  CompletedModelData? data;

  CompletedModelBean({this.status, this.message, this.statusCode, this.data});

  CompletedModelBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    data = json['data'] != null ? new CompletedModelData.fromJson(json['data']) : null;
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

class CompletedModelData {
  String? sId;
  int? price;
  String? createdBy;
  String? vendorId;
  String? serviceId;
  String? orderStatus;
  String? timeSlot;
  String? date;
  bool? notificationSent;
  bool? isActive;
  bool? isDeleted;
  String? createdAt;
  String? updatedAt;
  int? iV;

  CompletedModelData(
      {this.sId,
        this.price,
        this.createdBy,
        this.vendorId,
        this.serviceId,
        this.orderStatus,
        this.timeSlot,
        this.date,
        this.notificationSent,
        this.isActive,
        this.isDeleted,
        this.createdAt,
        this.updatedAt,
        this.iV});

  CompletedModelData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    price = json['price'];
    createdBy = json['createdBy'];
    vendorId = json['vendorId'];
    serviceId = json['serviceId'];
    orderStatus = json['orderStatus'];
    timeSlot = json['timeSlot'];
    date = json['date'];
    notificationSent = json['notificationSent'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['price'] = this.price;
    data['createdBy'] = this.createdBy;
    data['vendorId'] = this.vendorId;
    data['serviceId'] = this.serviceId;
    data['orderStatus'] = this.orderStatus;
    data['timeSlot'] = this.timeSlot;
    data['date'] = this.date;
    data['notificationSent'] = this.notificationSent;
    data['isActive'] = this.isActive;
    data['isDeleted'] = this.isDeleted;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}
