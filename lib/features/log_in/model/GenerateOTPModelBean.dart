class GenerateOTPModelBean {
  String? status;
  String? message;
  int? statusCode;
  Data? data;

  GenerateOTPModelBean({this.status, this.message, this.statusCode, this.data});

  GenerateOTPModelBean.fromJson(Map<String, dynamic> json) {
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
  String? status;
  String? details;

  Data({this.status, this.details});

  Data.fromJson(Map<String, dynamic> json) {
    status = json['Status'];
    details = json['Details'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Status'] = this.status;
    data['Details'] = this.details;
    return data;
  }
}