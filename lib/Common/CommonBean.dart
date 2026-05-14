class CommonBean {
  String? status;
  String? message;

  CommonBean({this.status, this.message});

  CommonBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['message'] is List) {
      message = (json['message'] as List).join(", ");
    } else {
      message = json['message']?.toString();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    return data;
  }
}