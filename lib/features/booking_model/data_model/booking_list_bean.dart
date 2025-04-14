class BookingListBean {
  String? status;
  String? message;
  int? statusCode;
  Data? data;

  BookingListBean({this.status, this.message, this.statusCode, this.data});

  BookingListBean.fromJson(Map<String, dynamic> json) {
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
  List<Records>? records;
  int? totalCount;

  Data({this.records, this.totalCount});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['records'] != null) {
      records = <Records>[];
      json['records'].forEach((v) {
        records!.add(new Records.fromJson(v));
      });
    }
    totalCount = json['totalCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.records != null) {
      data['records'] = this.records!.map((v) => v.toJson()).toList();
    }
    data['totalCount'] = this.totalCount;
    return data;
  }
}

class Records {
  String? sId;
  int? price;
  String? orderStatus;
  String? timeSlot;
  String? date;
  String? createdByFirstName;
  String? createdByLastName;
  String? createdByImage;
  String? createdByMobile;
  String? createdByEmail;
  String? cancelledBy;
  String? commentByUser;
  String? commentByVendor;

  Records(
      {this.sId,
        this.price,
        this.orderStatus,
        this.timeSlot,
        this.date,
        this.createdByFirstName,
        this.createdByLastName,
        this.createdByImage,
        this.createdByMobile,
        this.createdByEmail,
        this.cancelledBy,
        this.commentByUser,
        this.commentByVendor});

  Records.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    price = json['price'];
    orderStatus = json['orderStatus'];
    timeSlot = json['timeSlot'];
    date = json['date'];
    createdByFirstName = json['createdByFirstName'];
    createdByLastName = json['createdByLastName'];
    createdByImage = json['createdByImage'];
    createdByMobile = json['createdByMobile'];
    createdByEmail = json['createdByEmail'];
    cancelledBy = json['cancelled_by'];
    commentByUser = json['commentByUser'];
    commentByVendor = json['commentByVendor'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['price'] = this.price;
    data['orderStatus'] = this.orderStatus;
    data['timeSlot'] = this.timeSlot;
    data['date'] = this.date;
    data['createdByFirstName'] = this.createdByFirstName;
    data['createdByLastName'] = this.createdByLastName;
    data['createdByImage'] = this.createdByImage;
    data['createdByMobile'] = this.createdByMobile;
    data['createdByEmail'] = this.createdByEmail;
    data['cancelled_by'] = this.cancelledBy;
    data['commentByUser'] = this.commentByUser;
    data['commentByVendor'] = this.commentByVendor;
    return data;
  }
}
