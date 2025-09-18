class VersionModelBean {
  AndroidData? android;
  AndroidData? ios;

  VersionModelBean({this.android, this.ios});

  VersionModelBean.fromJson(Map<String, dynamic> json) {
    android =
    json['android'] != null ? AndroidData.fromJson(json['android']) : null;
    ios = json['ios'] != null ? AndroidData.fromJson(json['ios']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (android != null) {
      data['android'] = android!.toJson();
    }
    if (ios != null) {
      data['ios'] = ios!.toJson();
    }
    return data;
  }
}

class AndroidData {
  String? tag;
  String? name;
  String? code;
  bool? allowForceUpdate;

  AndroidData({this.tag, this.name, this.code, this.allowForceUpdate});

  AndroidData.fromJson(Map<String, dynamic> json) {
    tag = json['tag'];
    name = json['name'];
    code = json['code'];
    allowForceUpdate = json['allow_force_update'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tag'] = tag;
    data['name'] = name;
    data['code'] = code;
    data['allow_force_update'] = allowForceUpdate;
    return data;
  }
}
