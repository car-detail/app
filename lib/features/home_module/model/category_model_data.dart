class CategoryModelData {
  String? status;
  String? message;
  int? statusCode;
  List<CategoryData>? data;

  CategoryModelData({this.status, this.message, this.statusCode, this.data});

  CategoryModelData.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    if (json['data'] != null) {
      data = <CategoryData>[];
      json['data'].forEach((v) {
        data!.add(new CategoryData.fromJson(v));
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

class CategoryData {
  String? sId;
  String? categoryTitle;
  String? logoImage;
  String? categoryDescription;
  bool? isActive;
  bool? isDeleted;
  String? createdAt;
  String? updatedAt;
  int? iV;

  CategoryData(
      {this.sId,
        this.categoryTitle,
        this.logoImage,
        this.categoryDescription,
        this.isActive,
        this.isDeleted,
        this.createdAt,
        this.updatedAt,
        this.iV});

  CategoryData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    categoryTitle = json['categoryTitle'];
    logoImage = json['logoImage'];
    categoryDescription = json['categoryDescription'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['categoryTitle'] = this.categoryTitle;
    data['logoImage'] = this.logoImage;
    data['categoryDescription'] = this.categoryDescription;
    data['isActive'] = this.isActive;
    data['isDeleted'] = this.isDeleted;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}
