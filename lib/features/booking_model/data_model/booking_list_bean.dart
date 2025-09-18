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
  List<Records>? records;
  int? totalCount;

  Data({this.records, this.totalCount});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['records'] != null) {
      records = <Records>[];
      json['records'].forEach((v) {
        records!.add(Records.fromJson(v));
      });
    }
    totalCount = json['totalCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (records != null) {
      data['records'] = records!.map((v) => v.toJson()).toList();
    }
    data['totalCount'] = totalCount;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['price'] = price;
    data['orderStatus'] = orderStatus;
    data['timeSlot'] = timeSlot;
    data['date'] = date;
    data['createdByFirstName'] = createdByFirstName;
    data['createdByLastName'] = createdByLastName;
    data['createdByImage'] = createdByImage;
    data['createdByMobile'] = createdByMobile;
    data['createdByEmail'] = createdByEmail;
    data['cancelled_by'] = cancelledBy;
    data['commentByUser'] = commentByUser;
    data['commentByVendor'] = commentByVendor;
    return data;
  }
}
