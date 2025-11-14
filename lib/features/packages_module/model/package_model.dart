class PackageModel {
  final String id;
  final String packageName;
  final String description;
  final double price;
  final double discount;
  final List<String> servicesIncluded;
  final String? vendorId;
  final String? coverImage;
  final List<String>? detailImages;
  bool isActive;
  final double? averageRating;
  final int? totalReviews;

  PackageModel({
    required this.id,
    required this.packageName,
    required this.description,
    required this.price,
    required this.discount,
    required this.servicesIncluded,
    this.vendorId,
    this.coverImage,
    this.detailImages,
    this.isActive = true,
    this.averageRating,
    this.totalReviews,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      packageName: json['packageName'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      servicesIncluded: json['servicesIncluded'] != null
          ? List<String>.from(json['servicesIncluded'])
          : [],
      vendorId: json['vendorId']?.toString(),
      coverImage: json['coverImage'],
      detailImages: json['detailImages'] != null
          ? List<String>.from(json['detailImages'])
          : null,
      isActive: json['isActive'] ?? true,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageName': packageName,
      'description': description,
      'price': price,
      'discount': discount,
      'servicesIncluded': servicesIncluded,
      'vendorId': vendorId,
      'coverImage': coverImage,
      'detailImages': detailImages,
      'isActive': isActive,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
    };
  }

  double get discountedPrice => price - (price * discount / 100);
}
