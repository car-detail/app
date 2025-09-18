class PackageModelData {
  String? status;
  String? message;
  List<PackageData>? data;

  PackageModelData({this.status, this.message, this.data});

  PackageModelData.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <PackageData>[];
      if (json['data'] is List) {
        (json['data'] as List).forEach((v) {
          data!.add(PackageData.fromJson(v));
        });
      } else {
        print("❌ PackageModelData: 'data' field is not a List, it's: ${json['data'].runtimeType}");
        print("❌ PackageModelData: 'data' value: ${json['data']}");
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PackageData {
  String? sId;
  String? packageName;
  String? packageDescription;
  String? packagePrice;
  String? packageDuration;
  List<String>? servicesIncluded;
  String? packageImage;
  String? vendorId;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  
  // Vehicle size pricing
  String? smallVehiclePrice;
  String? largeVehiclePrice;
  String? packageTier; // OUTSIDE, BASIC, ULTRA, THE BEST
  bool? isBestSeller;

  PackageData({
    this.sId,
    this.packageName,
    this.packageDescription,
    this.packagePrice,
    this.packageDuration,
    this.servicesIncluded,
    this.packageImage,
    this.vendorId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.smallVehiclePrice,
    this.largeVehiclePrice,
    this.packageTier,
    this.isBestSeller,
  });

  PackageData.fromJson(Map<String, dynamic> json) {
    try {
      sId = json['_id']?.toString();
      packageName = json['packageName']?.toString();
      packageDescription = json['description']?.toString(); // Backend uses 'description'
      packagePrice = json['price']?.toString(); // Backend uses 'price' as number
      packageDuration = json['packageDuration']?.toString(); // This field doesn't exist in backend
      
      if (json['servicesIncluded'] != null) {
        if (json['servicesIncluded'] is List) {
          servicesIncluded = (json['servicesIncluded'] as List<dynamic>).map((e) => e.toString()).toList();
        } else {
          servicesIncluded = [json['servicesIncluded'].toString()];
        }
      }
      
      packageImage = json['coverImage']?.toString(); // Backend uses 'coverImage'
      vendorId = json['vendorId']?.toString();
      isActive = json['isActive'] as bool?;
      createdAt = json['createdAt']?.toString();
      updatedAt = json['updatedAt']?.toString();
      
      // These fields don't exist in backend Package entity
      smallVehiclePrice = null;
      largeVehiclePrice = null;
      packageTier = null;
      isBestSeller = null;
    } catch (e) {
      print("❌ Error parsing PackageData: $e");
      print("❌ JSON data: $json");
      // Set default values
      sId = null;
      packageName = null;
      packageDescription = null;
      packagePrice = null;
      packageDuration = null;
      servicesIncluded = null;
      packageImage = null;
      vendorId = null;
      isActive = null;
      createdAt = null;
      updatedAt = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['packageName'] = packageName;
    data['packageDescription'] = packageDescription;
    data['packagePrice'] = packagePrice;
    data['packageDuration'] = packageDuration;
    data['servicesIncluded'] = servicesIncluded;
    data['packageImage'] = packageImage;
    data['vendorId'] = vendorId;
    data['isActive'] = isActive;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['smallVehiclePrice'] = smallVehiclePrice;
    data['largeVehiclePrice'] = largeVehiclePrice;
    data['packageTier'] = packageTier;
    data['isBestSeller'] = isBestSeller;
    return data;
  }
}
