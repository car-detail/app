import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/design_system/components/car_loader.dart';

class AllOffersScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final List<Map<String, dynamic>> offers;

  const AllOffersScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.offers,
  });

  @override
  _AllOffersScreenState createState() => _AllOffersScreenState();
}

class _AllOffersScreenState extends State<AllOffersScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: ColorClass.base_color,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Offers - ${widget.vendorName}",
          style: const TextStyle(
            color: Colors.black87,
            fontFamily: "Pop600",
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: isLoading
          ? _buildLoadingState()
          : widget.offers.isEmpty
              ? _buildEmptyState()
              : _buildOffersList(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: CarLoader(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            "No Offers Available",
            style: TextStyle(
              fontSize: 24,
              fontFamily: "Pop600",
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Offers will appear here when available",
            style: TextStyle(
              fontSize: 16,
              fontFamily: "Pop400",
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.offers.length,
      itemBuilder: (context, index) {
        final offer = widget.offers[index];
        return _buildOfferCard(offer);
      },
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offer Image
            Stack(
              children: [
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: offer['image'] != null && offer['image'].isNotEmpty
                      ? Image.network(
                          offer['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
                ),
                // Gradient Overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Valid Till Badge - Top Right
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[700]),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(offer['validUntil']),
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: "Pop600",
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Discount Badge - Top Left
                if (offer['discount'] != null && offer['discount'] > 0)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "${offer['discount'] ?? 0}% OFF",
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: "Pop600",
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                // Title and Description - Bottom Overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (offer['title'] != null && offer['title'].toString().isNotEmpty)
                          Text(
                            offer['title'] ?? 'Special Offer',
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: "Pop600",
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
                        if (offer['description'] != null && offer['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            offer['description'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: "Pop400",
                              color: Colors.white.withOpacity(0.9),
                              height: 1.4,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Additional Info Section
            if (offer['originalPrice'] != null && offer['discountedPrice'] != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      "\$${offer['originalPrice']}",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "Pop400",
                        color: Colors.grey[500],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "\$${offer['discountedPrice']}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: "Pop600",
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[200]!,
            Colors.grey[300]!,
          ],
        ),
      ),
      child: Icon(
        Icons.local_offer_rounded,
        size: 64,
        color: Colors.grey[400],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    final dateStr = date.toString().trim();
    if (dateStr.isEmpty) return 'N/A';
    
    try {
      // Try standard DateTime.parse first
      final DateTime dateTime = DateTime.parse(dateStr);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (e) {
      // Try alternative formats
      try {
        // Try ISO 8601 format (if it contains 'T')
        if (dateStr.contains('T')) {
          final DateTime dateTime = DateTime.parse(dateStr.split('T')[0]);
          return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
        }
        // Try timestamp format
        if (RegExp(r'^\d+$').hasMatch(dateStr)) {
          final int timestamp = int.tryParse(dateStr) ?? 0;
          if (timestamp > 0) {
            final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
          }
        }
      } catch (e2) {
      }
      return 'Invalid Date';
    }
  }

  void _claimOffer(Map<String, dynamic> offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.local_offer_rounded, color: ColorClass.base_color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                offer['title'] ?? "Special Offer",
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: "Pop600",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (offer['discount'] != null && offer['discount'] > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.percent_rounded, color: Colors.grey[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Get ${offer['discount'] ?? 0}% discount on this service",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "Pop500",
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            if (offer['description'] != null && offer['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                offer['description'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: "Pop400",
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
            if (offer['validUntil'] != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    "Valid until: ${_formatDate(offer['validUntil'])}",
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: "Pop400",
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: "Pop500",
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              CommonWidget.successShowSnackBarFor(context, "Offer claimed successfully!");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorClass.base_color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Claim Now",
              style: TextStyle(
                fontFamily: "Pop600",
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
