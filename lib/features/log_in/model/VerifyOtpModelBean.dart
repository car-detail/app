class VerifyOtpModelBean {
  String? status;
  String? message;
  int? statusCode;
  Data? data;

  VerifyOtpModelBean({this.status, this.message, this.statusCode, this.data});

  VerifyOtpModelBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    // Handle message as both string and array (backend returns array)
    if (json['message'] != null) {
      if (json['message'] is List) {
        // If message is an array, take the first element
        List<dynamic> messageList = json['message'] as List<dynamic>;
        message = messageList.isNotEmpty ? messageList[0].toString() : null;
      } else {
        // If message is a string, use it directly
        message = json['message'].toString();
      }
    } else {
      message = null;
    }
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['accessToken'] = accessToken;
    data['refreshToken'] = refreshToken;
    data['refreshTokenExpireTime'] = refreshTokenExpireTime;
    return data;
  }
}
