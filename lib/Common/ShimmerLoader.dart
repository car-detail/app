import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'Color.dart';

class ShimmerLoader {
  // Car-themed color scheme
  static const Color _carBaseColor = Color(0xFF2C3E50); // Dark blue-grey
  static const Color _carHighlightColor = Color(0xFF3498DB); // Bright blue
  static const Color _carAccentColor = Color(0xFFE74C3C); // Red accent
  static const Color _carNeutralColor = Color(0xFF95A5A6); // Light grey

  static Widget buildShimmer({
    double? width,
    double? height,
    double borderRadius = 6.0,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? _carBaseColor.withOpacity(0.03),
      highlightColor: highlightColor ?? _carHighlightColor.withOpacity(0.08),
      period: Duration(milliseconds: 1800),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget buildCardShimmer() {
    return Shimmer.fromColors(
      baseColor: _carBaseColor.withOpacity(0.02),
      highlightColor: _carHighlightColor.withOpacity(0.06),
      period: Duration(milliseconds: 2000),
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildListShimmer({int itemCount = 3}) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: buildCardShimmer(),
        ),
      ),
    );
  }

  static Widget buildImageShimmer({
    double width = 100,
    double height = 100,
    double borderRadius = 8.0,
  }) {
    return Shimmer.fromColors(
      baseColor: _carBaseColor.withOpacity(0.02),
      highlightColor: _carHighlightColor.withOpacity(0.06),
      period: Duration(milliseconds: 2000),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[200]!,
              Colors.grey[100]!,
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget buildTextShimmer({
    double? width,
    double height = 16.0,
    double borderRadius = 4.0,
  }) {
    return Shimmer.fromColors(
      baseColor: _carBaseColor.withOpacity(0.02),
      highlightColor: _carHighlightColor.withOpacity(0.06),
      period: Duration(milliseconds: 1800),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[200]!,
              Colors.grey[100]!,
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget buildButtonShimmer({
    double width = 120,
    double height = 40,
    double borderRadius = 20.0,
  }) {
    return Shimmer.fromColors(
      baseColor: _carBaseColor.withOpacity(0.02),
      highlightColor: _carHighlightColor.withOpacity(0.06),
      period: Duration(milliseconds: 1800),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[200]!,
              Colors.grey[100]!,
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget buildGridShimmer({
    int crossAxisCount = 2,
    int itemCount = 6,
    double aspectRatio = 1.0,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: aspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => buildCardShimmer(),
    );
  }

  static Widget buildServiceCardShimmer() {
    return Shimmer.fromColors(
      baseColor: _carBaseColor.withOpacity(0.02),
      highlightColor: _carHighlightColor.withOpacity(0.06),
      period: Duration(milliseconds: 2000),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey[200]!, Colors.grey[100]!],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.grey[200]!, Colors.grey[100]!],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.grey[200]!, Colors.grey[100]!],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey[200]!, Colors.grey[100]!],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 200,
              height: 12,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey[200]!, Colors.grey[100]!],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildOfferCardShimmer() {
    return Shimmer.fromColors(
      baseColor: _carBaseColor.withOpacity(0.02),
      highlightColor: _carHighlightColor.withOpacity(0.06),
      period: Duration(milliseconds: 2000),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey[200]!, Colors.grey[100]!],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.grey[200]!, Colors.grey[100]!],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.grey[200]!, Colors.grey[100]!],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.grey[200]!, Colors.grey[100]!],
                      ),
                      borderRadius: BorderRadius.circular(4),
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

  static Widget buildCarLoadingAnimation() {
    return Shimmer.fromColors(
      baseColor: _carBaseColor.withOpacity(0.02),
      highlightColor: _carHighlightColor.withOpacity(0.06),
      period: Duration(milliseconds: 2000),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              _carHighlightColor.withOpacity(0.1),
              _carBaseColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _carHighlightColor.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.directions_car,
          color: _carHighlightColor.withOpacity(0.3),
          size: 20,
        ),
      ),
    );
  }

  static Widget buildSleekShimmer({
    double? width,
    double? height,
    double borderRadius = 6.0,
  }) {
    return Shimmer.fromColors(
      baseColor: _carBaseColor.withOpacity(0.01),
      highlightColor: _carHighlightColor.withOpacity(0.03),
      period: Duration(milliseconds: 2200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
