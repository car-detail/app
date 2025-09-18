class NotificationDataBean {
  String? status;
  String? message;
  int? statusCode;
  NotificationData? data;

  NotificationDataBean({this.status, this.message, this.statusCode, this.data});

  NotificationDataBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    data = json['data'] != null ? NotificationData.fromJson(json['data']) : null;
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

class NotificationData {
  List<Notifications>? notifications;
  int? total;
  String? page;
  String? limit;
  int? totalPages;

  NotificationData(
      {this.notifications, this.total, this.page, this.limit, this.totalPages});

  NotificationData.fromJson(Map<String, dynamic> json) {
    if (json['notifications'] != null) {
      notifications = <Notifications>[];
      json['notifications'].forEach((v) {
        notifications!.add(Notifications.fromJson(v));
      });
    }
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (notifications != null) {
      data['notifications'] =
          notifications!.map((v) => v.toJson()).toList();
    }
    data['total'] = total;
    data['page'] = page;
    data['limit'] = limit;
    data['totalPages'] = totalPages;
    return data;
  }
}

class Notifications {
  String? sId;
  String? userId;
  String? title;
  String? body;
  Dataa? dataa;
  String? status;
  List<String>? fcmTokens;
  String? errorMessage;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Notifications(
      {this.sId,
        this.userId,
        this.title,
        this.body,
        this.dataa,
        this.status,
        this.fcmTokens,
        this.errorMessage,
        this.createdAt,
        this.updatedAt,
        this.iV});

  Notifications.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    title = json['title'];
    body = json['body'];
    dataa = json['data'] != null ? Dataa.fromJson(json['data']) : null;
    status = json['status'];
    fcmTokens = json['fcmTokens'].cast<String>();
    errorMessage = json['errorMessage'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['userId'] = userId;
    data['title'] = title;
    data['body'] = body;
    if (dataa != null) {
      data['data'] = dataa!.toJson();
    }
    data['status'] = status;
    data['fcmTokens'] = fcmTokens;
    data['errorMessage'] = errorMessage;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}

class Dataa {
  String? bookingId;
  String? type;

  Dataa({this.bookingId, this.type});

  Dataa.fromJson(Map<String, dynamic> json) {
    bookingId = json['bookingId'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['bookingId'] = bookingId;
    data['type'] = type;
    return data;
  }
}
