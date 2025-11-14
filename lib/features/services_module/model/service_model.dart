class ServiceModel {
  final String id;
  final String serviceTitle;
  final String description;
  final double price;
  final String duration;
  final String categoryName;
  final String? categoryId;
  final String? coverImage;
  final List<String>? detailImages;
  bool isActive;
  final String? vendorId;
  final List<TimeSlot>? timeSlots;
  final double? averageRating;
  final int? totalReviews;

  ServiceModel({
    required this.id,
    required this.serviceTitle,
    required this.description,
    required this.price,
    required this.duration,
    required this.categoryName,
    this.categoryId,
    this.coverImage,
    this.detailImages,
    this.isActive = true,
    this.vendorId,
    this.timeSlots,
    this.averageRating,
    this.totalReviews,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      serviceTitle: json['serviceTitle'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      duration: json['serviceDuration'] ?? json['duration'] ?? '',
      categoryName: json['categoryName'] ?? '',
      categoryId: json['categoryId']?.toString(),
      coverImage: json['coverImage'],
      detailImages: json['detailImages'] != null 
          ? List<String>.from(json['detailImages']) 
          : null,
      isActive: json['isActive'] ?? true,
      vendorId: json['vendorId']?.toString(),
      timeSlots: json['timeSlots'] != null
          ? (json['timeSlots'] as List)
              .map((slot) => TimeSlot.fromJson(slot))
              .toList()
          : null,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceTitle': serviceTitle,
      'description': description,
      'price': price,
      'serviceDuration': duration,
      'categoryName': categoryName,
      'categoryId': categoryId,
      'coverImage': coverImage,
      'detailImages': detailImages,
      'isActive': isActive,
      'vendorId': vendorId,
      'timeSlots': timeSlots?.map((slot) => slot.toJson()).toList(),
      'average_rating': averageRating,
      'total_reviews': totalReviews,
    };
  }
}

class TimeSlot {
  final String slot;
  final int capacity;
  final int booked;
  final String? startTime;
  final String? endTime;

  TimeSlot({
    required this.slot,
    required this.capacity,
    this.booked = 0,
    this.startTime,
    this.endTime,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      slot: json['slot'] ?? '',
      capacity: json['capacity'] ?? 0,
      booked: json['booked'] ?? 0,
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slot': slot,
      'capacity': capacity,
      'booked': booked,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
