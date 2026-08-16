import 'dart:convert';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/Common/ModernDesignSystem.dart';
import 'package:car_app/features/offer_model/data_manager/offer_data_manager.dart';
import 'package:car_app/features/offer_model/ui/enhanced_offer_screen.dart';
import 'package:car_app/features/offer_model/model/offer_list_model_bean.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnhancedOfferListScreen extends StatefulWidget {
  const EnhancedOfferListScreen({super.key});

  @override
  State<EnhancedOfferListScreen> createState() => _EnhancedOfferListScreenState();
}

class _EnhancedOfferListScreenState extends State<EnhancedOfferListScreen> {
  List<OfferListModelData> offers = [];
  bool isLoading = true;
  String? vendorId;
  OfferDataManager? offerDataManager;
  SharedPreferences? sharedPreferences;
  
  // Filter options
  String selectedFilter = "all";
  final List<String> filterOptions = ["all", "active", "expired", "inactive"];

  @override
  void initState() {
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    offerDataManager = OfferDataManager(sharedPreferences!);
    vendorId = sharedPreferences!.getString(Constant.vendorId);
    await getOffers();
  }

  Future<void> getOffers() async {
    if (!mounted || !context.mounted) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      var response = await offerDataManager!.getOfferList(context);
      
      if (!mounted || !context.mounted) return;
      
      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }
      
      // Check response status code
      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to load offers. Please check your connection and try again.");
        }
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }
      
      try {
        var data = OfferListModelBean.fromJson(jsonDecode(response.body));
        
        if (data.status == "success") {
          if (mounted) {
            setState(() {
              offers.clear();
              offers.addAll(data.data!);
            });
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to load offers");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error parsing offers data. Please try again.");
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error loading offers. Please check your connection and try again.");
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<OfferListModelData> get filteredOffers {
    if (selectedFilter == "all") return offers;
    
    return offers.where((offer) {
      switch (selectedFilter) {
        case "active":
          return offer.isCurrentlyActive == true;
        case "expired":
          return offer.validUntil != null && 
                 DateTime.parse(offer.validUntil!).isBefore(DateTime.now());
        case "inactive":
          return offer.isCurrentlyActive == false;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: Column(
        children: [
          // Modern Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20, right: 20, bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: ModernDesignSystem.brandGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1CB273).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CommonWidget.buildBackButton(
                      context,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      iconColor: Colors.white,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "My Offers",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${offers.length} total • ${offers.where((o) => o.isCurrentlyActive == true).length} active",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.local_offer_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Modern Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterOptions.map((filter) {
                      final isSelected = selectedFilter == filter;
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFilter = filter;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.white 
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected 
                                    ? ColorClass.base_color.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: Text(
                              filter.toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? ColorClass.base_color : Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Offers List
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF1CB273)),
                        SizedBox(height: 16),
                        Text("Loading offers...", style: TextStyle(color: Color(0xFF1CB273), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : filteredOffers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: getOffers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredOffers.length,
                          itemBuilder: (context, index) {
                            final offer = filteredOffers[index];
                            return _buildOfferCard(offer);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: ColorClass.base_color.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EnhancedOfferScreen(),
              ),
            );
            if (result == true) {
              await getOffers();
            }
          },
          backgroundColor: ColorClass.base_color,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          label: const Text(
            "Create Offer",
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildOfferCard(OfferListModelData offer) {
    final isExpired = offer.validUntil != null && 
                     offer.validUntil!.isNotEmpty &&
                     DateTime.parse(offer.validUntil!).isBefore(DateTime.now());
    final isActive = offer.isCurrentlyActive == true && !isExpired;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact Header with Image Background
          Container(
            height: 140,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: offer.image != null && offer.image!.isNotEmpty
                      ? Image.network(
                          offer.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: ModernDesignSystem.accentFor(2).withOpacity(0.3),
                              child: const Icon(
                                Icons.local_offer_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: ModernDesignSystem.accentFor(2),
                          child: const Icon(
                            Icons.local_offer_rounded,
                            color: Colors.white,
                            size: 48,
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
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                ),
                // Content Overlay
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Service Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              offer.service?.serviceTitle ?? "Service",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isExpired 
                                  ? Colors.red[700]!.withOpacity(0.9)
                                  : isActive 
                                      ? Colors.green[700]!.withOpacity(0.9)
                                      : Colors.grey[700]!.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isExpired 
                                  ? "EXPIRED"
                                  : isActive 
                                      ? "ACTIVE" 
                                      : "INACTIVE",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Bottom: Title
                      Text(
                        offer.title ?? "Untitled Offer",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Compact Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Discount and Validity in Row
                Row(
                  children: [
                    // Discount Badge
                    if (offer.discount != null && offer.discount! > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_offer_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              "${offer.discount}% OFF",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Validity Info
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isExpired 
                              ? Colors.red[50] 
                              : offer.validUntil == null || offer.validUntil!.isEmpty
                                  ? Colors.green[50]
                                  : ColorClass.base_light_color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              offer.validUntil == null || offer.validUntil!.isEmpty
                                  ? Icons.all_inclusive_rounded
                                  : Icons.calendar_today_rounded,
                              size: 12,
                              color: isExpired 
                                  ? Colors.red[700]
                                  : offer.validUntil == null || offer.validUntil!.isEmpty
                                      ? Colors.green[700]
                                      : ColorClass.base_color,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                offer.validUntil == null || offer.validUntil!.isEmpty
                                    ? "Never expires"
                                    : "Until ${CommonWidget.getDateFormat(offer.validUntil!)}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isExpired 
                                      ? Colors.red[700]
                                      : offer.validUntil == null || offer.validUntil!.isEmpty
                                          ? Colors.green[700]
                                          : ColorClass.base_color,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Description (if available)
                if (offer.description != null && offer.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    offer.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                // Statistics Row: Views and Claims
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "${offer.viewCount ?? 0} views",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: "Pop500"),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.bookmark_added_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "${offer.claimCount ?? 0} claims",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: "Pop500"),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildModernActionButton(
                        Icons.edit_rounded,
                        "Edit",
                        () async {
                          if (mounted && context.mounted) {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EnhancedOfferScreen(offerToEdit: offer),
                              ),
                            );
                            if (result == true) {
                              await getOffers();
                            }
                          }
                        },
                        isPrimary: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModernActionButton(
                        Icons.delete_rounded,
                        "Delete",
                        () {
                          if (mounted && context.mounted) {
                            _showDeleteDialog(offer.sId.toString());
                          }
                        },
                        isDestructive: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModernActionButton(
                        isExpired
                            ? Icons.replay_rounded
                            : (offer.isCurrentlyActive == true ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        isExpired
                            ? "Re-run"
                            : (offer.isCurrentlyActive == true ? "Pause" : "Activate"),
                        () {
                          if (isExpired) {
                            _reRunOffer(context, offer);
                          } else {
                            if (mounted && context.mounted) {
                              _toggleOfferStatus(offer.sId.toString());
                            }
                          }
                        },
                        isSecondary: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 70,
      width: 70,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Icon(
        Icons.local_offer_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildModernActionButton(
    IconData icon, 
    String label, 
    VoidCallback onTap, {
    bool isPrimary = false,
    bool isSecondary = false,
    bool isDestructive = false,
  }) {
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    Color borderColor;
    
    if (isDestructive) {
      backgroundColor = Colors.red[50]!;
      textColor = Colors.red[700]!;
      iconColor = Colors.red[600]!;
      borderColor = Colors.red[200]!;
    } else if (isPrimary) {
      backgroundColor = ColorClass.base_color;
      textColor = Colors.white;
      iconColor = Colors.white;
      borderColor = ColorClass.base_color;
    } else if (isSecondary) {
      backgroundColor = Colors.grey[100]!;
      textColor = Colors.grey[700]!;
      iconColor = Colors.grey[600]!;
      borderColor = Colors.grey[300]!;
    } else {
      backgroundColor = ColorClass.base_light_color;
      textColor = ColorClass.base_color;
      iconColor = ColorClass.base_color;
      borderColor = ColorClass.base_color.withOpacity(0.3);
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Add haptic feedback for better UX
          // HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: isPrimary 
            ? Colors.white.withOpacity(0.2)
            : isDestructive
                ? Colors.red.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
        highlightColor: isPrimary 
            ? Colors.white.withOpacity(0.1)
            : isDestructive
                ? Colors.red.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 44,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                size: 16, 
                color: iconColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    
    switch (selectedFilter) {
      case "active":
        message = "No Active Offers";
        subtitle = "Create your first active offer to attract customers";
        break;
      case "expired":
        message = "No Expired Offers";
        subtitle = "All your offers are still valid";
        break;
      case "inactive":
        message = "No Inactive Offers";
        subtitle = "All your offers are currently active";
        break;
      default:
        message = "No Offers Yet";
        subtitle = "Create attractive offers to boost your bookings and attract more customers";
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorClass.base_color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_offer,
                size: 64,
                color: ColorClass.base_color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(String offerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            "Delete Offer",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to delete this offer? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteOffer(offerId);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteOffer(String offerId) async {
    try {
      var response = await offerDataManager!.deleteOffer(context, offerId);
      if (!mounted) return;

      var data = jsonDecode(response.body);
      if (data['status'] == "success") {
        CommonWidget.successShowSnackBarFor(context, "Offer deleted successfully!");
        await getOffers();
      } else {
        CommonWidget.errorShowSnackBarFor(context, data['message'] ?? "Failed to delete offer");
      }
    } catch (e) {
      if (mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error deleting offer: $e");
      }
    }
  }

  Future<void> _toggleOfferStatus(String offerId) async {
    try {
      var response = await offerDataManager!.postOfferUpdate(context, offerId);
      if (!mounted) return;

      var data = jsonDecode(response.body);
      if (data['status'] == "success") {
        CommonWidget.successShowSnackBarFor(context, "Offer status updated!");
        await getOffers();
      } else {
        CommonWidget.errorShowSnackBarFor(context, data['message'] ?? "Failed to update offer");
      }
    } catch (e) {
      CommonWidget.errorShowSnackBarFor(context, "Error updating offer: $e");
    }
  }

  Future<void> _reRunOffer(BuildContext context, OfferListModelData offer) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorClass.base_color,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      final formattedDate = "${picked.year.toString().padLeft(4, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.day.toString().padLeft(2, '0')} 23:59:59.000";
      
      try {
        var response = await offerDataManager!.duplicateOffer(
          context,
          offer.sId.toString(),
          formattedDate,
        );
        if (response.statusCode == 201) {
          var resBody = jsonDecode(response.body);
          if (resBody['status'] == 'success') {
            if (mounted) {
              CommonWidget.successShowSnackBarFor(context, "Offer duplicated and re-run successfully!");
              await getOffers();
            }
          }
        }
      } catch (e) {
        if (mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Failed to re-run offer: $e");
        }
      }
    }
  }
}

