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
        for (var v in (json['data'] as List)) {
          data!.add(PackageData.fromJson(v));
        }
      } else {
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
  
  // Service details (when populated from backend)
  List<Map<String, String>>? serviceDetails;
  
  // Custom services (service names added by vendor, not service IDs)
  List<String>? customServices;

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
    this.serviceDetails,
    this.customServices,
  });

  PackageData.fromJson(Map<String, dynamic> json) {
    try {
      sId = json['_id']?.toString();
      packageName = json['packageName']?.toString();
      packageDescription = json['description']?.toString() ?? json['packageDescription']?.toString(); // Backend uses 'description', but also check 'packageDescription'
      packagePrice = json['price']?.toString() ?? json['packagePrice']?.toString(); // Backend uses 'price' as number, but also check 'packagePrice'
      packageDuration = json['packageDuration']?.toString() ?? json['duration']?.toString(); // Check both field names
      
      // Store service details if populated
      serviceDetails = [];
      if (json['servicesIncluded'] != null) {
        if (json['servicesIncluded'] is List) {
          final servicesList = json['servicesIncluded'] as List<dynamic>;
          servicesIncluded = [];
          
          for (var e in servicesList) {
            if (e is Map<String, dynamic>) {
              // Populated service object - extract all possible ID fields
              final serviceId = e['_id']?.toString() ?? 
                              e['sId']?.toString() ?? 
                              e['id']?.toString() ?? 
                              '';
              servicesIncluded!.add(serviceId);
              
              // Extract service name - try multiple field names (serviceTitle is the primary field)
              final serviceName = e['serviceTitle']?.toString()?.trim() ?? 
                                 e['name']?.toString()?.trim() ?? 
                                 e['title']?.toString()?.trim() ?? 
                                 e['serviceName']?.toString()?.trim() ??
                                 '';
              
              // Debug: Print service object to see what fields are available
              print('Service Object: $e');
              print('Extracted serviceTitle: ${e['serviceTitle']}');
              print('Extracted name: $serviceName');
              
              // Only add if we have a valid service name (not empty)
              if (serviceName.isNotEmpty && serviceName != 'Service') {
                serviceDetails!.add({
                  'id': serviceId,
                  'name': serviceName,
                  'category': e['categoryName']?.toString() ?? e['category']?.toString() ?? '',
                });
              } else {
                // If no name found, still add with ID for debugging
                serviceDetails!.add({
                  'id': serviceId,
                  'name': 'Service $serviceId',
                  'category': e['categoryName']?.toString() ?? e['category']?.toString() ?? '',
                });
              }
            } else if (e is String) {
              // Just an ID string
              servicesIncluded!.add(e);
              serviceDetails!.add({
                'id': e,
                'name': 'Service $e',
                'category': '',
              });
            } else {
              // Try to convert to string
              final serviceId = e.toString();
              servicesIncluded!.add(serviceId);
              serviceDetails!.add({
                'id': serviceId,
                'name': 'Service $serviceId',
                'category': '',
              });
            }
          }
        } else {
          servicesIncluded = [json['servicesIncluded'].toString()];
          serviceDetails!.add({
            'id': json['servicesIncluded'].toString(),
            'name': 'Service',
            'category': '',
          });
        }
      }
      
      if (serviceDetails!.isEmpty) {
        serviceDetails = null;
      }
      
      // Parse custom services
      if (json['customServices'] != null) {
        if (json['customServices'] is List) {
          customServices = (json['customServices'] as List<dynamic>).map((e) => e.toString()).toList();
        } else {
          customServices = [json['customServices'].toString()];
        }
      }
      
      packageImage = json['coverImage']?.toString() ?? json['packageImage']?.toString(); // Backend uses 'coverImage', but also check 'packageImage'
      vendorId = json['vendorId']?.toString();
      if (vendorId == null && json['vendorId'] is Map) {
        vendorId = json['vendorId']['_id']?.toString();
      }
      isActive = json['isActive'] as bool?;
      createdAt = json['createdAt']?.toString();
      updatedAt = json['updatedAt']?.toString();
      
      // Read these fields if they exist in the JSON response
      // Handle both number and string types for prices
      if (json['smallVehiclePrice'] != null) {
        if (json['smallVehiclePrice'] is num) {
          smallVehiclePrice = json['smallVehiclePrice'].toString();
        } else {
          smallVehiclePrice = json['smallVehiclePrice'].toString();
        }
      } else {
      smallVehiclePrice = null;
      }
      
      if (json['largeVehiclePrice'] != null) {
        if (json['largeVehiclePrice'] is num) {
          largeVehiclePrice = json['largeVehiclePrice'].toString();
        } else {
          largeVehiclePrice = json['largeVehiclePrice'].toString();
        }
      } else {
      largeVehiclePrice = null;
      }
      
      packageTier = json['packageTier']?.toString();
      
      // Handle isBestSeller - can be bool, string, or number
      if (json['isBestSeller'] != null) {
        if (json['isBestSeller'] is bool) {
          isBestSeller = json['isBestSeller'] as bool;
        } else if (json['isBestSeller'] is String) {
          isBestSeller = json['isBestSeller'].toString().toLowerCase() == 'true';
        } else if (json['isBestSeller'] is num) {
          isBestSeller = (json['isBestSeller'] as num) != 0;
        } else {
          isBestSeller = false;
        }
      } else {
        isBestSeller = false;
      }
      
      
      // Debug logging
      
      // If smallVehiclePrice and largeVehiclePrice are not set, but price is set, 
      // we can use price as a fallback (though the form expects both)
      if (smallVehiclePrice == null && largeVehiclePrice == null && packagePrice != null && packagePrice!.isNotEmpty) {
        // Don't auto-populate, let user set them separately
      }
    } catch (e) {
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
      smallVehiclePrice = null;
      largeVehiclePrice = null;
      packageTier = null;
      isBestSeller = null;
      serviceDetails = null;
      customServices = null;
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
    data['serviceDetails'] = serviceDetails;
    data['customServices'] = customServices;
    return data;
  }
}
