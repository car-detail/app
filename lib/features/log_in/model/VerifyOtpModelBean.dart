class VerifyOtpModelBean {
  String? status;
  String? message;
  int? statusCode;
  Data? data;

  VerifyOtpModelBean({this.status, this.message, this.statusCode, this.data});

  VerifyOtpModelBean.fromJson(Map<String, dynamic> json) {
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
  String? accessToken;
  String? refreshToken;
  int? refreshTokenExpireTime;

  Data({this.accessToken, this.refreshToken, this.refreshTokenExpireTime});

  Data.fromJson(Map<String, dynamic> json) {
    accessToken = json['accessToken'];
    refreshToken = json['refreshToken'];
    refreshTokenExpireTime = json['refreshTokenExpireTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['accessToken'] = this.accessToken;
    data['refreshToken'] = this.refreshToken;
    data['refreshTokenExpireTime'] = this.refreshTokenExpireTime;
    return data;
  }
}
