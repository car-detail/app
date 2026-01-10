import 'dart:convert';

import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonBean.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/features/home_module/model/services_model_data.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Common/CommonWidget.dart';
import '../../../ZoomImageList.dart';
import '../../booking_model/ui/booking_activity.dart';
import '../../rating_model/ui/rating_review_screen.dart';
import '../../categories_module/data_manager/categories_list_data_manager.dart';
import '../data_manager/specialists_data_manager.dart';
import '../model/services_details_model_data.dart';
import 'offer_list_widget.dart';

class SpecialistsActivity extends StatefulWidget {
  String servicesData;

  SpecialistsActivity(this.servicesData, {super.key});

  @override
  State<SpecialistsActivity> createState() => _SpecialistsActivityState();
}

class _SpecialistsActivityState extends State<SpecialistsActivity> {
  SpecialistsDataManager? dataManager;
  CategoriesListDataManager? bookmarkDataManager;
  SharedPreferences? sharedPreferences;
  ServicesDetailsData servicesDetailsData = ServicesDetailsData(detailImages: []);
  List<String> detailImages = [];
  bool isBookmarked = false;
  bool _isLoadingPackages = false;
  String? _packagesError;

  @override
  void initState() {
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = SpecialistsDataManager(sharedPreferences!);
    bookmarkDataManager = CategoriesListDataManager(sharedPreferences!);
    getServicesDetails(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Collapsible Header with Image
          _buildCollapsibleHeader(context),
          // Content
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Info Card
                  _buildServiceInfoCard(context),
                  const SizedBox(height: 16),
                  // Quick Info Cards
                  _buildQuickInfoCards(context),
                  const SizedBox(height: 16),
                  // Navigation Tabs
                  _buildNavigationTabs(context),
                  const SizedBox(height: 16),
                  // About Section
                  _buildAboutSection(context),
                  const SizedBox(height: 16),
                  // Vendor Info Card
                  _buildVendorInfoCard(context),
                  const SizedBox(height: 16),
                  // Services Section
                  _buildServicesSection(context),
                  const SizedBox(height: 16),
                  // Packages Section - always show (will show empty state if no packages)
                  _buildPackagesSection(context),
                  const SizedBox(height: 16),
                  // Gallery Section
                  if (detailImages.isNotEmpty) ...[
                    _buildGallerySection(context),
                    const SizedBox(height: 16),
                  ],
                  // Offers Section - always show (will show empty state if no offers)
                  _buildOffersSection(context),
                  const SizedBox(height: 16),
                  // Reviews Section
                  _buildReviewsSection(context),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      // Enhanced Book Now Button
      bottomNavigationBar: _buildBookNowButton(context),
    );
  }

  Widget _buildCollapsibleHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.sizeOf(context).height * 0.45,
      floating: false,
      pinned: true,
      backgroundColor: ColorClass.base_color,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Hero Image with Modern Styling
            GestureDetector(
              onTap: () {
                CommonWidget.navigateToScreen(
                    context,
                    ZoomableImageList(imageUrls: [
                      servicesDetailsData.coverImage ?? ""
                    ]));
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  child: Image.network(
                    servicesDetailsData.coverImage ?? "",
                    height: MediaQuery.sizeOf(context).height * 0.45,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: MediaQuery.sizeOf(context).height * 0.45,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [ColorClass.base_color, ColorClass.base_color.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.local_car_wash_rounded,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Service Info
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ColorClass.base_color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      servicesDetailsData.categoryName ?? "Car Service",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: "Pop500",
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    servicesDetailsData.serviceTitle ?? "Service",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: "Pop600",
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                  if (servicesDetailsData.location?.name != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            servicesDetailsData.location?.name ?? "",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: "Pop400",
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      leading: GestureDetector(
        onTap: () => CommonWidget.safePop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _toggleBookmark,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? Colors.orange : Colors.black87,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Service Details",
            style: TextStyle(
              fontSize: 18,
              fontFamily: "Pop600",
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber[600], size: 20),
              const SizedBox(width: 8),
              Text(
                "${servicesDetailsData.averageRating ?? 0.0} Rating",
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: "Pop500",
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                "${servicesDetailsData.totalReviews ?? 0} Reviews",
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: "Pop500",
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard("Verified", "Trusted Service", Icons.verified, Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard("Available", "Book Now", Icons.access_time, Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard("Nearby", "Quick Access", Icons.location_on, Colors.orange),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontFamily: "Pop600",
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontFamily: "Pop400",
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTabs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab("About", true),
          _buildTab("Gallery", false),
          _buildTab("Offers", false),
          _buildTab("Reviews", false),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? ColorClass.base_color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 14,
            fontFamily: "Pop500",
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: ColorClass.base_color, size: 20),
              const SizedBox(width: 8),
              Text(
                "About This Service",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            servicesDetailsData.about ?? "Professional car service with attention to detail.",
            style: TextStyle(
              fontSize: 14,
              fontFamily: "Pop400",
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Service Provider",
            style: TextStyle(
              fontSize: 16,
              fontFamily: "Pop600",
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: ColorClass.base_color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.business,
                  color: ColorClass.base_color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servicesDetailsData.vendorId?.displayName ?? "Vendor",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "Pop600",
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      servicesDetailsData.mobile ?? "Contact not available",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "Pop400",
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Implement call functionality
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorClass.base_color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.phone,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Services",
            style: TextStyle(
              fontSize: 16,
              fontFamily: "Pop600",
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Professional car service with attention to detail.",
            style: TextStyle(
              fontSize: 14,
              fontFamily: "Pop400",
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesSection(BuildContext context) {
    if (_isLoadingPackages && servicesDetailsData.packages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Service Packages",
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Pop600",
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      );
    }

    if (_packagesError != null && servicesDetailsData.packages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Service Packages",
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Pop600",
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "No packages available at the moment.",
              style: TextStyle(
                fontSize: 14,
                fontFamily: "Pop400",
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    if (servicesDetailsData.packages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Service Packages",
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Pop600",
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "No packages available at the moment.",
              style: TextStyle(
                fontSize: 14,
                fontFamily: "Pop400",
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.purple[600], size: 20),
              const SizedBox(width: 8),
              Text(
                "Service Packages",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${servicesDetailsData.packages.length} available",
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: "Pop500",
                    color: Colors.purple[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...servicesDetailsData.packages.map((package) => _buildVendorPackageCard(package)),
        ],
      ),
    );
  }

  Widget _buildVendorPackageCard(Map<String, dynamic> package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2, color: Colors.purple[600], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package['title'] ?? package['packageTitle'] ?? 'Service Package',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "Pop600",
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      package['description'] ?? package['packageDescription'] ?? 'Package description',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "Pop400",
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    package['price'] != null ? "\$${package['price']}" : "Price TBD",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: "Pop600",
                      color: Colors.purple[600],
                    ),
                  ),
                  Text(
                    package['duration'] ?? package['packageDuration'] ?? "Duration TBD",
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: "Pop400",
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (package['services'] != null && package['services'] is List && (package['services'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: (package['services'] as List).take(3).map((service) {
                String serviceName = '';
                if (service is Map) {
                  serviceName = service['serviceTitle'] ?? service['title'] ?? 'Service';
                } else {
                  serviceName = service.toString();
                }
                return _buildFeatureChip(serviceName, Colors.purple[600]!);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String feature, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        feature,
        style: TextStyle(
          fontSize: 12,
          fontFamily: "Pop400",
          color: color,
        ),
      ),
    );
  }

  Widget _buildGallerySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gallery",
            style: TextStyle(
              fontSize: 16,
              fontFamily: "Pop600",
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: detailImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      detailImages[index] ?? "",
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: Icon(Icons.image, color: Colors.grey[400]),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersSection(BuildContext context) {
    if (servicesDetailsData.offers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Special Offers",
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Pop600",
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "No offers available at the moment.",
              style: TextStyle(
                fontSize: 14,
                fontFamily: "Pop400",
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Text(
                "Special Offers",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${servicesDetailsData.offers.length} offers",
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: "Pop500",
                    color: Colors.orange[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...servicesDetailsData.offers.take(2).map((offer) => _buildOfferPreviewCard(offer)),
          if (servicesDetailsData.offers.length > 2) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                CommonWidget.navigateToScreen(
                  context,
                  OfferListWidget(servicesDetailsData.offers),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_offer, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "View All ${servicesDetailsData.offers.length} Offers",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "Pop500",
                        color: Colors.orange[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, color: Colors.orange[600], size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfferPreviewCard(Offers offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.local_offer, color: Colors.orange[600], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title ?? "Special Offer",
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: "Pop600",
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offer.description ?? "Limited time offer",
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: "Pop400",
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (offer.discount != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${offer.discount ?? 0}% OFF",
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: "Pop600",
                  color: Colors.red[600],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Reviews",
            style: TextStyle(
              fontSize: 16,
              fontFamily: "Pop600",
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "No reviews available at the moment.",
            style: TextStyle(
              fontSize: 14,
              fontFamily: "Pop400",
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookNowButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implement booking functionality
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorClass.base_color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                "Book This Service",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: "Pop600",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBookmark() async {
    setState(() {
      isBookmarked = !isBookmarked;
    });
    // TODO: Implement bookmark functionality
  }

  getServicesDetails(BuildContext context) async {
    var response = await dataManager!.getServiceDetails(context, widget.servicesData);
    var data = ServicesDetailsBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      String? vendorId;
      setState(() {
        servicesDetailsData = data.data!;
        detailImages.clear();
        detailImages.addAll(data.data!.detailImages);
        
        // Extract vendor ID for fetching packages
        if (data.data!.vendorId != null) {
          vendorId = data.data!.vendorId!.sId;
        }
      });
      
      // Fetch packages for this vendor
      if (vendorId != null && vendorId!.isNotEmpty) {
        _fetchVendorPackages(vendorId!);
      }
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  Future<void> _fetchVendorPackages(String vendorId) async {
    if (dataManager == null) return;
    
    setState(() {
      _isLoadingPackages = true;
      _packagesError = null;
    });

    try {
      final response = await dataManager!.getVendorPackages(context, vendorId);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == "success" && jsonData['data'] != null) {
          final packages = List<Map<String, dynamic>>.from(jsonData['data']);
          if (mounted) {
            setState(() {
              servicesDetailsData.packages.clear();
              servicesDetailsData.packages.addAll(packages);
              _isLoadingPackages = false;
              _packagesError = null;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              servicesDetailsData.packages.clear();
              _isLoadingPackages = false;
              _packagesError = jsonData['message']?.toString() ?? "Failed to load packages";
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            servicesDetailsData.packages.clear();
            _isLoadingPackages = false;
            _packagesError = "Server responded with ${response.statusCode}";
          });
        }
      }
    } catch (e) {
      print("❌ Error loading packages: $e");
      if (mounted) {
        setState(() {
          servicesDetailsData.packages.clear();
          _isLoadingPackages = false;
          _packagesError = e.toString();
        });
      }
    }
  }
}
