import 'dart:async';
import 'dart:convert';

import 'package:car_app/Common/Color.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Common/CommonWidget.dart';
import '../../../ZoomImageList.dart';
import '../../booking_model/ui/booking_activity.dart';
import '../../rating_model/ui/rating_review_screen.dart';
import '../../rating_model/data_manager/RatingReviewDataManager.dart';
import '../../rating_model/model/rate_review_model_bean.dart';
import '../../categories_module/data_manager/categories_list_data_manager.dart';
import '../../home_module/model/services_model_data.dart';
import '../data_manager/specialists_data_manager.dart';
import '../model/services_details_model_data.dart' hide Location, Coordinates;
import 'offer_list_widget.dart';
import 'all_packages_screen.dart';
import 'all_offers_screen.dart';
import '../utils/package_mapper.dart';

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
  ServicesDetailsData servicesDetailsData =
      ServicesDetailsData(detailImages: []);
  List<String> detailImages = [];
  bool isBookmarked = false;
  bool _isLoadingPackages = false;
  bool _isLoadingDetails = true;
  String? _packagesError;
  String? _lastFetchedVendorId;
  RatingReviewDataManager? _reviewDataManager;
  List<Reviews> _previewReviews = [];
  String selectedTab = "About";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    // Validate vendor ID before proceeding
    if (widget.servicesData.isEmpty || widget.servicesData.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            CommonWidget.errorShowSnackBarFor(context, "Invalid vendor ID. Cannot load details.");
            Navigator.pop(context);
          }
        });
      }
      return;
    }
    
    // Initialize data managers asynchronously without blocking
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = SpecialistsDataManager(sharedPreferences!);
    bookmarkDataManager = CategoriesListDataManager(sharedPreferences!);
    _reviewDataManager = RatingReviewDataManager(sharedPreferences!);
    
    // Check if widget is still mounted before using context
    if (!mounted) return;
    
    // Use a post-frame callback with a small delay to ensure UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a small delay to ensure navigation animation completes
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
    getServicesDetails(context);
        }
      });
    });
  }

  Future<void> _loadPreviewReviews() async {
    if (_reviewDataManager == null || servicesDetailsData.sId == null) return;
    try {
      final response = await _reviewDataManager!.getReviewRateList(context, servicesDetailsData.sId!);
      if (!mounted) return;
      final data = RateReviewModelBean.fromJson(jsonDecode(response.body));
      if (data.status == "success" && data.data != null) {
        setState(() {
          _previewReviews = data.data!.reviews.take(3).toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching initial data
    if (_isLoadingDetails && servicesDetailsData.serviceTitle == null) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
              ),
              const SizedBox(height: 16),
              Text(
                "Loading vendor details...",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: "Pop400",
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: RefreshIndicator(
        onRefresh: () async {
          if (mounted && context.mounted) {
            await getServicesDetails(context);
          }
        },
        child: CustomScrollView(
        slivers: [
          // Collapsible Header with Image
          _buildCollapsibleHeader(context),
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsStrip(context),
                const SizedBox(height: 16),
                _buildAboutSection(context),
                const SizedBox(height: 16),
                _buildVendorInfoCard(context),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildServicesSection(context),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildPackagesSection(context),
                ),
                const SizedBox(height: 16),
                if (detailImages.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildGallerySection(context),
                  ),
                  const SizedBox(height: 16),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildOffersSection(context),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildReviewsSection(context),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      ),
      // Book Now Button - Disabled in vendor app (vendors shouldn't book their own services)
      // bottomNavigationBar: _buildBookNowButton(context),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.4,
      child: Stack(
          children: [
          // Cover Image - Use service image, fallback to vendor image, then default
            GestureDetector(
              onTap: () {
              List<String> images = [];
                if (servicesDetailsData.coverImage != null && servicesDetailsData.coverImage!.isNotEmpty) {
                images.add(servicesDetailsData.coverImage!);
              } else if (servicesDetailsData.vendorId?.displayPicture != null && 
                    servicesDetailsData.vendorId!.displayPicture!.isNotEmpty) {
                images.add(servicesDetailsData.vendorId!.displayPicture!);
                }
              if (images.isNotEmpty) {
                CommonWidget.navigateToScreen(
                    context,
                  ZoomableImageList(imageUrls: images)
                );
              }
              },
              child: SizedBox(
                width: double.infinity,
              height: double.infinity,
              child: (servicesDetailsData.coverImage != null && servicesDetailsData.coverImage!.isNotEmpty)
                  ? Image.network(
                      servicesDetailsData.coverImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to vendor image
                        return _buildCoverImageWithVendorFallback();
                      },
                    )
                  : _buildCoverImageWithVendorFallback(),
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
            
          // Top Navigation
          Positioned(
            top: 45,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CommonWidget.buildBackButton(
                  context,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  iconColor: Colors.black87,
                ),
                GestureDetector(
                  onTap: _toggleBookmark,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border, 
                      color: isBookmarked ? ColorClass.base_color : Colors.black87, 
                      size: 20
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Service Title Overlay
            Positioned(
              bottom: 20,
            left: 16,
            right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ColorClass.base_color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      servicesDetailsData.categoryName ?? "Car Service",
                      style: const TextStyle(
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
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  ),
                  if (servicesDetailsData.location?.name != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            servicesDetailsData.location?.name ?? "",
                            style: const TextStyle(
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
    );
  }

  Widget _buildCoverImageWithVendorFallback() {
    // Priority 1: Try service cover image first
    String? coverImage = servicesDetailsData.coverImage;
    if (coverImage != null && coverImage.trim().isNotEmpty) {
      return Image.network(
        coverImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // If cover image fails to load, fallback to vendor image
          return _buildHeaderImageWithVendorFallback();
        },
      );
    }
    // Priority 2: If no cover image, use vendor image
    return _buildHeaderImageWithVendorFallback();
  }

  Widget _buildHeaderImageWithVendorFallback() {
    // Priority 2: Try vendor display picture
    String? vendorImage = servicesDetailsData.vendorId?.displayPicture;
    if (vendorImage != null && vendorImage.trim().isNotEmpty) {
      return Image.network(
        vendorImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultCoverImage();
        },
      );
    }
    // Priority 3: If no vendor image, show default
    return _buildDefaultCoverImage();
  }

  Widget _buildCollapsibleHeaderImageWithVendorFallback() {
    // Priority 1: Try service cover image first
    String? coverImage = servicesDetailsData.coverImage;
    if (coverImage != null && coverImage.trim().isNotEmpty) {
      return Image.network(
        coverImage,
        height: MediaQuery.of(context).size.height * 0.4,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // If cover image fails to load, fallback to vendor image
          return _buildHeaderImageWithVendorFallbackForHeader();
        },
      );
    }
    // Priority 2: If no cover image, use vendor image
    return _buildHeaderImageWithVendorFallbackForHeader();
  }

  Widget _buildHeaderImageWithVendorFallbackForHeader() {
    // Priority 2: Try vendor display picture
    String? vendorImage = servicesDetailsData.vendorId?.displayPicture;
    if (vendorImage != null && vendorImage.trim().isNotEmpty) {
      return Image.network(
        vendorImage,
        height: MediaQuery.of(context).size.height * 0.4,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultCollapsibleHeaderImage();
        },
      );
    }
    // Priority 3: If no vendor image, show default
    return _buildDefaultCollapsibleHeaderImage();
  }

  Widget _buildDefaultCollapsibleHeaderImage() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorClass.base_color, ColorClass.base_color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.local_car_wash,
          color: Colors.white,
          size: 80,
        ),
      ),
    );
  }

  Widget _buildDefaultCoverImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorClass.base_color.withOpacity(0.8),
            ColorClass.base_color.withOpacity(0.6),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_car_wash,
              size: 80,
        color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              "Car Service",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: "Pop600",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.sizeOf(context).height * 0.4,
      floating: false,
      pinned: true,
      backgroundColor: ColorClass.base_color,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Cover Image - Use service image, fallback to vendor image, then default
            GestureDetector(
              onTap: () {
                List<String> images = [];
                if (servicesDetailsData.coverImage != null && servicesDetailsData.coverImage!.isNotEmpty) {
                  images.add(servicesDetailsData.coverImage!);
                } else if (servicesDetailsData.vendorId?.displayPicture != null && 
                           servicesDetailsData.vendorId!.displayPicture!.isNotEmpty) {
                  images.add(servicesDetailsData.vendorId!.displayPicture!);
                }
                if (images.isNotEmpty) {
                  CommonWidget.navigateToScreen(
                    context,
                    ZoomableImageList(imageUrls: images)
                  );
                }
              },
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: _buildCollapsibleHeaderImageWithVendorFallback(),
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
                      style: const TextStyle(
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
                          offset: const Offset(0, 1),
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
                        const Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            servicesDetailsData.location?.name ?? "",
                            style: const TextStyle(
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

  Widget _buildStatsStrip(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          if (servicesDetailsData.averageRating != null && servicesDetailsData.averageRating != 0)
            _buildStatChip(Icons.star_rounded, "${servicesDetailsData.averageRating?.toStringAsFixed(1)}", "Rating", Colors.amber),
          if (servicesDetailsData.totalReviews != null && servicesDetailsData.totalReviews! > 0)
            _buildStatChip(Icons.people_rounded, "${servicesDetailsData.totalReviews}", "Reviews", Colors.blue),
          if (servicesDetailsData.price != null && servicesDetailsData.price! > 0)
            _buildStatChip(Icons.currency_rupee_rounded, "${servicesDetailsData.price}", "Price", ColorClass.base_color),
          if (servicesDetailsData.serviceDuration != null)
            _buildStatChip(Icons.access_time_rounded, servicesDetailsData.serviceDuration!, "Duration", Colors.purple),
        ]),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ]),
      ]),
    );
  }

  Widget _buildQuickInfoCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.verified_user_rounded,
            title: "Verified",
            subtitle: "Trusted",
        ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.access_time_filled_rounded,
            title: "Available",
            subtitle: "Book Now",
        ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.location_on_rounded,
            title: "Nearby",
            subtitle: "Quick",
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: ColorClass.base_color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: ColorClass.base_color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorClass.base_color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ColorClass.base_color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: "Pop600",
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontFamily: "Pop400",
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Expanded(child: _buildTabButton("About", Icons.info_rounded, selectedTab == "About")),
          if (servicesDetailsData.offers.isNotEmpty)
            Expanded(child: _buildTabButton("Offers", Icons.local_offer_rounded, selectedTab == "Offers")),
          Expanded(child: _buildTabButton("Reviews", Icons.star_rounded, selectedTab == "Reviews")),
        ]),
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = title;
        });
        if (title == "Offers") {
          CommonWidget.navigateToScreen(context, OfferListWidget(servicesDetailsData.offers ?? []));
        } else if (title == "Reviews") {
          CommonWidget.navigateToScreen(context, RatingReviewScreen(servicesDetailsData));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFF166534), Color(0xFF1CB273)])
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: isSelected ? Colors.white : Colors.grey[500], size: 16),
          const SizedBox(width: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(color: ColorClass.base_color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          const Text("About", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
        ]),
        const SizedBox(height: 10),
        Text(
          servicesDetailsData.about ?? "No description available for this service.",
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.55),
        ),
      ]),
    );
  }

  Widget _buildVendorInfoCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // green top strip
        Container(
          height: 6,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF166534), Color(0xFF1CB273), Color(0xFF26D17A)],
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: ColorClass.base_color.withOpacity(0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: servicesDetailsData.vendorId?.displayPicture != null &&
                        servicesDetailsData.vendorId!.displayPicture!.isNotEmpty
                    ? Image.network(
                        servicesDetailsData.vendorId!.displayPicture!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.store_rounded, color: ColorClass.base_color, size: 28),
                      )
                    : Icon(Icons.store_rounded, color: ColorClass.base_color, size: 28),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  servicesDetailsData.vendorId?.displayName ?? "Service Provider",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                const SizedBox(height: 3),
                Text("Professional Car Service", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ]),
            ),
            // phone button
            GestureDetector(
              onTap: () {
                try {
                  launchUrl(Uri(scheme: 'tel', path: servicesDetailsData.vendorId?.mobile));
                } catch (e) {}
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF1CB273), Color(0xFF26D17A)]),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: ColorClass.base_color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorClass.base_color.withOpacity(0.08), Colors.transparent],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(16)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: ColorClass.base_color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.build_circle_rounded, color: ColorClass.base_color, size: 16),
              ),
              const SizedBox(width: 8),
              const Expanded(child: Text("Available Services", style: TextStyle(fontSize: 15, fontFamily: "Pop600", color: Colors.black87, fontWeight: FontWeight.bold))),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(14, 4, 14, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          // Service Details Card with Image
          Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
                  color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Image
                if (servicesDetailsData.coverImage != null && servicesDetailsData.coverImage!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.network(
                        servicesDetailsData.coverImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            color: Colors.grey[100],
                            child: Icon(Icons.local_car_wash_rounded, color: Colors.grey[400], size: 48),
                          );
                        },
                      ),
                    ),
                  )
                else if (servicesDetailsData.vendorId?.displayPicture != null && 
                         servicesDetailsData.vendorId!.displayPicture!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.network(
                        servicesDetailsData.vendorId!.displayPicture!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            color: Colors.grey[100],
                            child: Icon(Icons.local_car_wash_rounded, color: Colors.grey[400], size: 48),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Icon(Icons.local_car_wash_rounded, color: Colors.grey[400], size: 48),
                  ),
                // Service Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                                  servicesDetailsData.serviceTitle ?? "Car Service",
            style: const TextStyle(
                                    fontSize: 18,
              fontFamily: "Pop600",
              color: Colors.black87,
                                    fontWeight: FontWeight.bold,
            ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: ColorClass.base_color,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    servicesDetailsData.categoryName ?? "Car Wash",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontFamily: "Pop600",
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (servicesDetailsData.price != null && servicesDetailsData.price! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "\$${servicesDetailsData.price}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Pop600",
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
          ),
          const SizedBox(height: 12),
                      // Service Duration
                      if (servicesDetailsData.serviceDuration != null) ...[
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, color: Colors.grey[600], size: 18),
                            const SizedBox(width: 8),
          Text(
                              "Duration: ${servicesDetailsData.serviceDuration}",
            style: TextStyle(
              fontSize: 14,
              fontFamily: "Pop400",
              color: Colors.grey[700],
            ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Time Slot Capacity
                      if (servicesDetailsData.timeSlotCapacity != null) ...[
                        Row(
                          children: [
                            Icon(Icons.people_rounded, color: Colors.grey[600], size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Capacity: ${servicesDetailsData.timeSlotCapacity} customers per slot",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: "Pop400",
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Service Description
                      if (servicesDetailsData.about != null && servicesDetailsData.about!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            servicesDetailsData.about!,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: "Pop400",
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Additional Services Info
          Row(
            children: [
              Expanded(
                child: _buildServiceInfoItem(
                  icon: Icons.star_rounded,
                  title: "Rating",
                  value: servicesDetailsData.averageRating != 0 
                      ? "${servicesDetailsData.averageRating?.toStringAsFixed(1) ?? '0.0'} ⭐"
                      : "No ratings yet",
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildServiceInfoItem(
                  icon: Icons.people_rounded,
                  title: "Reviews",
                  value: "${servicesDetailsData.totalReviews ?? 0} reviews",
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildServiceInfoItem(
                  icon: Icons.location_on_rounded,
                  title: "Location",
                  value: servicesDetailsData.location?.name ?? "Location not available",
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildServiceInfoItem(
                  icon: Icons.verified_user_rounded,
                  title: "Status",
                  value: servicesDetailsData.isActive == true ? "Active" : "Inactive",
                  color: servicesDetailsData.isActive == true ? Colors.green.shade700 : Colors.grey[700]!,
                ),
              ),
            ],
          ),
          ]),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
      return Container(
      padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
            ),
        ),
        child: Column(
          children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
            Text(
            title,
              style: TextStyle(
              fontSize: 11,
              fontFamily: "Pop500",
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
                fontFamily: "Pop600",
                color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper method to check if vendor has packages
  bool _hasVendorPackages() {
    // Check if the vendor has created any packages
    return servicesDetailsData.packages.isNotEmpty;
  }

  Widget _buildPackagesSection(BuildContext context) {
    if (_isLoadingPackages && servicesDetailsData.packages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: const Center(
              child: CircularProgressIndicator(),
        ),
      );
    }

    if (_packagesError != null && servicesDetailsData.packages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
            ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ColorClass.base_color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.inventory_2, color: ColorClass.base_color, size: 16),
                ),
                const SizedBox(width: 8),
            const Text(
              "Service Packages",
              style: TextStyle(
                    fontSize: 15,
                fontFamily: "Pop600",
                color: Colors.black87,
                    fontWeight: FontWeight.bold,
              ),
            ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _packagesError ?? "Unable to load packages",
              style: TextStyle(
                fontSize: 14,
                fontFamily: "Pop400",
                      color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Pull to refresh or try again later.",
              style: TextStyle(
                fontSize: 12,
                fontFamily: "Pop400",
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    bool hasPackages = _hasVendorPackages();

      return Container(
      padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
            ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ColorClass.base_color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.inventory_2_rounded, color: ColorClass.base_color, size: 16),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
              "Service Packages",
              style: TextStyle(
                    fontSize: 15,
                fontFamily: "Pop600",
                color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${servicesDetailsData.packages.length}",
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: "Pop600",
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            ),
            const SizedBox(height: 12),
          if (hasPackages) ...[
            ...servicesDetailsData.packages.map((package) => _buildVendorPackageCard(package)),
          ] else ...[
            // No packages available - show empty state
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.grey[400],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
            Text(
              "No packages available at the moment.",
              style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Pop500",
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          ],
        ),
      );
    }

  Widget _buildVendorPackageCard(Map<String, dynamic> package) {
    final bool isBestSeller = package['isBestSeller'] == true;
    final bool isActive = package['isActive'] == true;
    final String? smallPrice = package['smallVehiclePrice']?.toString();
    final String? largePrice = package['largeVehiclePrice']?.toString();
    final String? duration = package['packageDuration']?.toString() ?? package['duration']?.toString();
    final String? tier = package['packageTier']?.toString();
    final List<dynamic> customServices = package['customServices'] is List ? package['customServices'] : [];
    final List<dynamic> features = package['features'] is List ? package['features'] : [];
    final List<dynamic> rawServices = package['servicesIncluded'] is List ? package['servicesIncluded'] : [];
    // Count services: prefer customServices count, else servicesIncluded count
    final int servicesCount = customServices.isNotEmpty ? customServices.length : rawServices.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name + Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package['packageName']?.toString() ?? package['title']?.toString() ?? 'Package',
                        style: const TextStyle(fontSize: 17, fontFamily: "Pop600", color: Colors.black87, fontWeight: FontWeight.bold),
                      ),
                      if (package['description'] != null && package['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          package['description'].toString(),
                          style: TextStyle(fontSize: 12, fontFamily: "Pop400", color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isBestSeller) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: ColorClass.base_color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text("Best Seller", style: TextStyle(fontSize: 11, fontFamily: "Pop600", color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isActive ? ColorClass.base_color.withOpacity(0.08) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? ColorClass.base_color.withOpacity(0.4) : Colors.grey[300]!, width: 1),
                      ),
                      child: Text(
                        isActive ? "Active" : "Inactive",
                        style: TextStyle(fontSize: 11, fontFamily: "Pop600", color: isActive ? ColorClass.base_color : Colors.grey[600], fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Price Grid
            if (smallPrice != null || largePrice != null || (duration != null && duration.isNotEmpty) || servicesCount > 0) ...[
              Container(
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      if (smallPrice != null && smallPrice.isNotEmpty) ...[
                        Expanded(child: _buildPriceCell("\$$smallPrice", "Small")),
                        VerticalDivider(width: 1, thickness: 1, color: Colors.grey[300]),
                      ],
                      if (largePrice != null && largePrice.isNotEmpty) ...[
                        Expanded(child: _buildPriceCell("\$$largePrice", "Large")),
                        VerticalDivider(width: 1, thickness: 1, color: Colors.grey[300]),
                      ],
                      if (duration != null && duration.isNotEmpty) ...[
                        Expanded(child: _buildPriceCell(duration, "Duration")),
                        if (servicesCount > 0) VerticalDivider(width: 1, thickness: 1, color: Colors.grey[300]),
                      ],
                      if (servicesCount > 0)
                        Expanded(child: _buildPriceCell("$servicesCount", "Services")),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Service/Feature chips
            if (customServices.isNotEmpty || features.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...customServices.map((s) => _buildServiceChip(s.toString())),
                  ...features.map((f) => _buildServiceChip(f.toString())),
                ],
              ),
              const SizedBox(height: 10),
            ],
            // Tier badge
            if (tier != null && tier.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.diamond_outlined, size: 14, color: Colors.grey[700]),
                    const SizedBox(width: 5),
                    Text(tier, style: TextStyle(fontSize: 12, fontFamily: "Pop600", color: Colors.grey[700], fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCell(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontFamily: "Pop600", color: Colors.black87, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 11, fontFamily: "Pop400", color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildServiceChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontFamily: "Pop400", color: Colors.grey[800])),
    );
  }

  Widget _buildPackageCard({
    required String title,
    required String description,
    required String price,
    required String duration,
    required List<String> features,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: "Pop600",
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "Pop400",
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: "Pop600",
                      color: color,
                    ),
                  ),
                  Text(
                    duration,
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
            const SizedBox(height: 12),
          // Features List
            Wrap(
              spacing: 8,
              runSpacing: 4,
            children: features.map((feature) => _buildFeatureChip(feature)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String feature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.grey[600], size: 14),
          const SizedBox(width: 4),
          Text(
        feature,
        style: TextStyle(
              fontSize: 11,
          fontFamily: "Pop400",
              color: Colors.grey[700],
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
          ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ColorClass.base_color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.photo_library, color: ColorClass.base_color, size: 16),
              ),
              const SizedBox(width: 8),
          const Text(
            "Gallery",
            style: TextStyle(
                  fontSize: 15,
              fontFamily: "Pop600",
              color: Colors.black87,
                  fontWeight: FontWeight.bold,
            ),
          ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: detailImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    CommonWidget.navigateToScreen(
                      context,
                      ZoomableImageList(
                        imageUrls: detailImages,
                        currentIndex: index,
                      ),
                    );
                  },
                  child: Container(
                  margin: const EdgeInsets.only(right: 8),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                        detailImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image,
                            color: Colors.grey[400],
                            size: 32,
                        );
                      },
                      ),
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
      return Container(
      padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
            ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Section Header with light grey background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ColorClass.base_color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.local_offer_rounded, color: ColorClass.base_color, size: 16),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
              "Special Offers",
              style: TextStyle(
                      fontSize: 15,
                fontFamily: "Pop600",
                color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
          ),
          const SizedBox(height: 12),
          if ((servicesDetailsData.offers ?? []).isNotEmpty) ...[
            ...(servicesDetailsData.offers ?? []).where((offer) => offer != null).map((offer) => _buildOfferPreviewCard(offer)),
          ] else ...[
            // No offers available
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    color: Colors.grey[400],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No offers available at the moment.",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Pop500",
                      color: Colors.grey[600],
                ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfferPreviewCard(Offers offer) {
    // Add null safety check
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Offer Image
            if (offer.image != null && offer.image!.isNotEmpty)
          SizedBox(
                height: 120,
                width: double.infinity,
                child: Image.network(
                  offer.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      color: Colors.grey[100],
                      child: Icon(Icons.local_offer_rounded, color: Colors.grey[400], size: 36),
                    );
                  },
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[100],
                child: Icon(Icons.local_offer_rounded, color: Colors.grey[400], size: 36),
          ),
            // Offer Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title ?? "Special Offer",
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: "Pop600",
                    color: Colors.black87,
                            fontWeight: FontWeight.bold,
                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  offer.description ?? "Limited time offer",
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: "Pop400",
                    color: Colors.grey[600],
                            height: 1.3,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "${offer.discount ?? 0}% OFF",
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: "Pop600",
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(width: 3, height: 18, decoration: BoxDecoration(color: ColorClass.base_color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                const Text("Reviews", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                if (servicesDetailsData.totalReviews != null && servicesDetailsData.totalReviews! > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: ColorClass.base_color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text("${servicesDetailsData.totalReviews}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ColorClass.base_color)),
                  ),
                ],
              ]),
              if (servicesDetailsData.totalReviews != null && servicesDetailsData.totalReviews! > 0)
                GestureDetector(
                  onTap: () => CommonWidget.navigateToScreen(context, RatingReviewScreen(servicesDetailsData)),
                  child: Text("View all", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ColorClass.base_color)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_previewReviews.isNotEmpty) ...[
            ..._previewReviews.map((review) => _buildReviewCard(review)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => CommonWidget.navigateToScreen(context, RatingReviewScreen(servicesDetailsData)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: ColorClass.base_color.withOpacity(0.3), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.star_rounded, color: ColorClass.base_color, size: 16),
                  const SizedBox(width: 6),
                  Text("View All Reviews", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ColorClass.base_color)),
                ]),
              ),
            ),
          ] else if (servicesDetailsData.totalReviews != null && servicesDetailsData.totalReviews! > 0) ...[
            GestureDetector(
              onTap: () => CommonWidget.navigateToScreen(context, RatingReviewScreen(servicesDetailsData)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: ColorClass.base_color.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.star_rounded, color: ColorClass.base_color, size: 16),
                  const SizedBox(width: 6),
                  Text("View ${servicesDetailsData.totalReviews} Reviews", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ColorClass.base_color)),
                ]),
              ),
            ),
          ] else ...[
            // No reviews available - show empty state
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    color: Colors.grey[400],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No reviews available at the moment.",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Pop500",
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCard(Reviews review) {
    final stars = (review.rating ?? 0).toInt();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: ColorClass.base_color.withOpacity(0.12),
            child: Text(
              (review.userId?.email ?? "U").substring(0, 1).toUpperCase(),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ColorClass.base_color),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(review.userId?.email ?? "Customer",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            Row(children: List.generate(5, (i) => Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 13, color: Colors.amber,
            ))),
          ])),
        ]),
        if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(review.reviewText!, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),
        ],
      ]),
    );
  }

  Widget _buildBookNowButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Create a complete ServicesData object from the service details
            // This allows vendors to see how the booking page looks for their service
            // Use Location and Coordinates from services_model_data.dart
            ServicesData serviceData = ServicesData(
              sId: servicesDetailsData.sId ?? widget.servicesData,
              serviceTitle: servicesDetailsData.serviceTitle,
              about: servicesDetailsData.about,
              price: servicesDetailsData.price,
              serviceDuration: servicesDetailsData.serviceDuration,
              categoryName: servicesDetailsData.categoryName,
              coverImage: servicesDetailsData.coverImage,
              mobile: servicesDetailsData.mobile,
              location: servicesDetailsData.location != null
                  ? Location(
                      name: servicesDetailsData.location!.name,
                      coordinates: servicesDetailsData.location!.coordinates != null
                          ? Coordinates(
                              lat: servicesDetailsData.location!.coordinates!.lat?.toDouble(),
                              long: servicesDetailsData.location!.coordinates!.long?.toDouble(),
                            )
                          : null,
                    )
                  : null,
              vendorImage: servicesDetailsData.vendorId?.displayPicture,
              vendorName: servicesDetailsData.vendorId?.displayName,
              vendorMobile: servicesDetailsData.vendorId?.mobile,
            );
            CommonWidget.navigateToScreen(
              context,
              BookingActivity(serviceData),
            );
          },
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorClass.base_color,
                  ColorClass.base_color.withOpacity(0.9),
                  ColorClass.base_color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: ColorClass.base_color.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
              const Text(
                "Book This Service",
                style: TextStyle(
                  color: Colors.white,
                      fontSize: 20,
                  fontFamily: "Pop600",
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                ),
              ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  getServicesDetails(BuildContext context) async {
    try {
      // Set loading state
      if (mounted) {
    setState(() {
          _isLoadingDetails = true;
        });
      }
      
      
      // Add timeout to prevent hanging - reduced to 15 seconds
      var response = await dataManager!
          .getServiceDetails(context, widget.servicesData)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException("API call timed out", const Duration(seconds: 15));
            },
          );
      
      // Check if widget is still mounted before proceeding
      if (!mounted) {
        return;
      }
      
      
      // Check if response is valid
      if (response.statusCode != 200) {
        if (mounted) {
          String errorMessage = "Failed to load vendor details";
          if (response.statusCode == 400) {
            errorMessage = "Invalid vendor ID. Please try again.";
          } else if (response.statusCode == 404) {
            errorMessage = "Vendor not found. Please try again.";
          } else if (response.statusCode == 500) {
            errorMessage = "Server error. Please try again later.";
          } else {
            errorMessage = "Unable to load vendor details. Please try again.";
          }
          if (mounted) CommonWidget.errorShowSnackBarFor(context, errorMessage);
        }
        return;
      }
      
      var jsonData = jsonDecode(response.body);
      
      if (jsonData['status'] == "success" && jsonData['data'] != null) {
        var data = jsonData['data'];
        String? vendorIdForPackages;
        
        // Check if data is a list (vendor services) or single object (service details)
        if (data is List) {
          // This is a vendor services response (array of services)
          if (data.isNotEmpty) {
            // Use the first service for display, but store all services
            var firstService = data[0];
            
            if (mounted) {
      setState(() {
                servicesDetailsData = ServicesDetailsData.fromJson(firstService);
        detailImages.clear();
                detailImages.addAll(servicesDetailsData.detailImages!);
                              isBookmarked = false; // Vendor app doesn't have bookmark functionality
              });
            }

            vendorIdForPackages = firstService['vendorId'] is Map
                ? firstService['vendorId']['_id']?.toString()
                : firstService['vendorId']?.toString();
            
          } else {
            if (mounted) {
              if (mounted) CommonWidget.errorShowSnackBarFor(context, "No services found for this vendor");
            }
            return;
          }
        } else {
          // This is a single service details response
          if (mounted) {
            setState(() {
              servicesDetailsData = ServicesDetailsData.fromJson(data);
              detailImages.clear();
              detailImages.addAll(servicesDetailsData.detailImages!);
                    isBookmarked = false; // Vendor app doesn't have bookmark functionality
            });
          }

          vendorIdForPackages = data['vendorId'] is Map
              ? data['vendorId']['_id']?.toString()
              : data['vendorId']?.toString();
          
        }
        

        if (mounted) {
          _fetchVendorPackages(vendorIdForPackages);
      }
    } else {
        if (mounted) {
          if (mounted) CommonWidget.errorShowSnackBarFor(context, jsonData['message'] ?? "Failed to load service details");
          _fetchVendorPackages(null);
    }
  }

      // Clear loading state
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
        _loadPreviewReviews();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
        if (mounted && e is TimeoutException) {
          CommonWidget.errorShowSnackBarFor(context, "Request timed out. Please check your connection and try again.");
        } else if (mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error loading service details: ${e.toString()}");
        }
      }
    }
  }

  Future<void> _fetchVendorPackages(String? vendorId) async {
    if (vendorId == null || vendorId.isEmpty) {
      setState(() {
        servicesDetailsData.packages.clear();
        _packagesError = null;
        _lastFetchedVendorId = null;
        _isLoadingPackages = false;
      });
      return;
    }

    if (dataManager == null) return;
    if (_isLoadingPackages && vendorId == _lastFetchedVendorId) {
      return;
    }
    
    setState(() {
      _isLoadingPackages = true;
      _packagesError = null;
      _lastFetchedVendorId = vendorId;
    });

    try {
      final response = await dataManager!.getVendorPackages(context, vendorId);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == "success") {
          final packages = jsonData['data'] != null 
              ? List<Map<String, dynamic>>.from(jsonData['data'])
              : <Map<String, dynamic>>[];
          if (!mounted) return;
            setState(() {
            servicesDetailsData.packages
              ..clear()
              ..addAll(packages);
              _isLoadingPackages = false;
              _packagesError = null;
            });
        } else {
          if (!mounted) return;
            setState(() {
              servicesDetailsData.packages.clear();
              _isLoadingPackages = false;
              _packagesError = jsonData['message']?.toString() ?? "Failed to load packages";
            });
        }
      } else {
        if (!mounted) return;
          setState(() {
            servicesDetailsData.packages.clear();
            _isLoadingPackages = false;
            _packagesError = "Server responded with ${response.statusCode}";
          });
      }
    } catch (e) {
      if (!mounted) return;
        setState(() {
          servicesDetailsData.packages.clear();
          _isLoadingPackages = false;
          _packagesError = e.toString();
        });
      }
    }

  Future<void> _toggleBookmark() async {
    // Bookmark functionality not available in vendor app
    CommonWidget.errorShowSnackBarFor(context, "Bookmark feature not available in vendor app");
  }
}
