class ErrorModel {
  String? status;
  List<String>? message;
  int? statusCode;

  ErrorModel({this.status, this.message, this.statusCode});

  ErrorModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'].cast<String>();
    statusCode = json['statusCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['statusCode'] = this.statusCode;
    return data;
  }
}
