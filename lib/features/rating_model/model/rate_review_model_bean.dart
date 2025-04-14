class RateReviewModelBean {
  String? status;
  String? message;
  int? statusCode;
  RateReviewModelData? data;

  RateReviewModelBean({this.status, this.message, this.statusCode, this.data});

  RateReviewModelBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    data = json['data'] != null ? new RateReviewModelData.fromJson(json['data']) : null;
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

class RateReviewModelData {
  List<Reviews> reviews = [];
  int? totalCount;
  List<Reviews> myReview = [];
  bool? alreadyCustomer;

  RateReviewModelData({reviews, this.totalCount, myReview, this.alreadyCustomer});

  RateReviewModelData.fromJson(Map<String, dynamic> json) {
    if (json['reviews'] != null) {
      reviews = <Reviews>[];
      json['reviews'].forEach((v) {
        reviews!.add(new Reviews.fromJson(v));
      });
    }
    totalCount = json['totalCount'];
    if (json['myReview'] != null) {
      myReview = <Reviews>[];
      json['myReview'].forEach((v) {
        myReview!.add(new Reviews.fromJson(v));
      });
    }
    alreadyCustomer = json['already_customer'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.reviews != null) {
      data['reviews'] = this.reviews!.map((v) => v.toJson()).toList();
    }
    data['totalCount'] = this.totalCount;
    if (this.myReview != null) {
      data['myReview'] = this.myReview!.map((v) => v.toJson()).toList();
    }
    data['already_customer'] = this.alreadyCustomer;
    return data;
  }
}

class Reviews {
  String? sId;
  String? serviceId;
  UserId? userId;
  String? reviewText;
  num? rating;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Reviews(
      {this.sId,
        this.serviceId,
        this.userId,
        this.reviewText,
        this.rating,
        this.createdAt,
        this.updatedAt,
        this.iV});

  Reviews.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    serviceId = json['serviceId'];
    userId =
    json['userId'] != null ? new UserId.fromJson(json['userId']) : null;
    reviewText = json['reviewText'];
    rating = json['rating'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['serviceId'] = this.serviceId;
    if (this.userId != null) {
      data['userId'] = this.userId!.toJson();
    }
    data['reviewText'] = this.reviewText;
    data['rating'] = this.rating;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class UserId {
  String? sId;
  String? email;
  String? firstName;
  String? lastName;
  String? image;

  UserId({this.sId, this.email, this.firstName, this.lastName, this.image});

  UserId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    email = json['email'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    image = json['image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['email'] = this.email;
    data['firstName'] = this.firstName;
    data['lastName'] = this.lastName;
    data['image'] = this.image;
    return data;
  }
}
