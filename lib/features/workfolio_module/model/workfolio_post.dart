class WorkfolioPost {
  final String id;
  final String image;
  final String caption;
  final String authorId;
  final String authorName;
  final String authorImage;
  final String authorRole;
  final String? vendorId;
  final String? vendorName;
  final String? vendorImage;
  final int likeCount;
  final List<String> likedBy;
  final String? createdAt;

  WorkfolioPost({
    required this.id,
    required this.image,
    required this.caption,
    required this.authorId,
    required this.authorName,
    required this.authorImage,
    required this.authorRole,
    this.vendorId,
    this.vendorName,
    this.vendorImage,
    required this.likeCount,
    required this.likedBy,
    this.createdAt,
  });

  factory WorkfolioPost.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final vendor = json['vendor'];

    String authorName = "Cahrz Vendor";
    String authorImage = "";
    String authorRole = "";
    String authorId = "";
    if (user is Map) {
      authorId = user['_id']?.toString() ?? "";
      final first = user['firstName']?.toString() ?? "";
      final last = user['lastName']?.toString() ?? "";
      final combined = "$first $last".trim();
      authorName = combined.isNotEmpty ? combined : authorName;
      authorImage = user['image']?.toString() ?? "";
      authorRole = user['roleName']?.toString() ?? "";
    } else if (user != null) {
      authorId = user.toString();
    }

    String? vendorId;
    String? vendorName;
    String? vendorImage;
    if (vendor is Map) {
      vendorId = vendor['_id']?.toString();
      vendorName = vendor['displayName']?.toString();
      vendorImage = vendor['displayPicture']?.toString();
    } else if (vendor != null) {
      vendorId = vendor.toString();
    }

    return WorkfolioPost(
      id: json['_id']?.toString() ?? "",
      image: json['image']?.toString() ?? "",
      caption: json['caption']?.toString() ?? "",
      authorId: authorId,
      authorName: authorName,
      authorImage: authorImage,
      authorRole: authorRole,
      vendorId: vendorId,
      vendorName: vendorName,
      vendorImage: vendorImage,
      likeCount: (json['likeCount'] is int) ? json['likeCount'] : int.tryParse(json['likeCount']?.toString() ?? "0") ?? 0,
      likedBy: (json['likedBy'] is List)
          ? (json['likedBy'] as List).map((e) => e is Map ? (e['_id']?.toString() ?? "") : e.toString()).toList()
          : [],
      createdAt: json['createdAt']?.toString(),
    );
  }
}
