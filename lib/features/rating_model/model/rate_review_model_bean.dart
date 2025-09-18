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
    data = json['data'] != null ? RateReviewModelData.fromJson(json['data']) : null;
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
        reviews.add(Reviews.fromJson(v));
      });
    }
    totalCount = json['totalCount'];
    if (json['myReview'] != null) {
      myReview = <Reviews>[];
      json['myReview'].forEach((v) {
        myReview.add(Reviews.fromJson(v));
      });
    }
    alreadyCustomer = json['already_customer'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (reviews != null) {
      data['reviews'] = reviews.map((v) => v.toJson()).toList();
    }
    data['totalCount'] = totalCount;
    if (myReview != null) {
      data['myReview'] = myReview.map((v) => v.toJson()).toList();
    }
    data['already_customer'] = alreadyCustomer;
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
    json['userId'] != null ? UserId.fromJson(json['userId']) : null;
    reviewText = json['reviewText'];
    rating = json['rating'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['serviceId'] = serviceId;
    if (userId != null) {
      data['userId'] = userId!.toJson();
    }
    data['reviewText'] = reviewText;
    data['rating'] = rating;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['email'] = email;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['image'] = image;
    return data;
  }
}
