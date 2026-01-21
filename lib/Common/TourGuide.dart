import 'package:flutter/material.dart';
import 'Color.dart';

/// Mark tour as seen callback
typedef MarkTourAsSeenCallback = Future<void> Function();

/// Tour Guide system for highlighting UI elements
class TourGuide {
  /// Check if user has seen the tour (from database)
  static bool hasSeenTour(bool? tourShown) {
    return tourShown ?? false;
  }

  /// Reset all tours (for testing) - No longer needed as we use database
  @Deprecated('Tour status is now managed in database')
  static Future<void> resetAllTours() async {
    // No-op: Tour status is now in database
  }

  /// Show tour guide overlay
  static Future<void> showTour({
    required BuildContext context,
    required String tourId,
    required List<TourStep> steps,
    required bool tourShown,
    required MarkTourAsSeenCallback onMarkAsSeen,
    VoidCallback? onComplete,
  }) async {
    // Check if already seen (from database)
    if (hasSeenTour(tourShown)) {
      onComplete?.call();
      return;
    }

    // Use overlay instead of Navigator.push to avoid blocking
    final overlay = Overlay.of(context);
    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => TourGuideOverlay(
        tourId: tourId,
        steps: steps,
        onComplete: () async {
          // Mark tour as seen in database when completed or skipped
          await onMarkAsSeen();
          overlayEntry.remove();
          onComplete?.call();
        },
      ),
    );
    
    overlay.insert(overlayEntry);
  }
}

class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData icon;
  final Color? iconColor;
  final Alignment alignment;

  TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor,
    this.alignment = Alignment.bottomCenter,
  });
}

class TourGuideOverlay extends StatefulWidget {
  final String tourId;
  final List<TourStep> steps;
  final VoidCallback onComplete;

  const TourGuideOverlay({
    super.key,
    required this.tourId,
    required this.steps,
    required this.onComplete,
  });

  @override
  State<TourGuideOverlay> createState() => _TourGuideOverlayState();
}

class _TourGuideOverlayState extends State<TourGuideOverlay> {
  int _currentStep = 0;
  int _retryCount = 0;
  static const int _maxRetries = 30; // Maximum 3 seconds of retries
  Offset? _targetPosition;
  Size? _targetSize;
  TourStep? _currentStepData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _updateCurrentStep();
      });
    });
  }

  void _updateCurrentStep() {
    if (_currentStep >= widget.steps.length) {
      widget.onComplete();
      return;
    }

    final step = widget.steps[_currentStep];
    final renderBox = step.targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null || !renderBox.attached) {
      _retryCount++;
      if (_retryCount > _maxRetries) {
        // If we can't find the element after max retries, skip the tour
        widget.onComplete();
        return;
      }
      // Retry after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _updateCurrentStep();
      });
      return;
    }

    // Reset retry count when we find an element
    _retryCount = 0;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    setState(() {
      _targetPosition = offset;
      _targetSize = size;
      _currentStepData = step;
    });
  }

  void _onNext() {
    setState(() {
      _currentStep++;
      _targetPosition = null;
      _targetSize = null;
      _currentStepData = null;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _updateCurrentStep();
    });
  }

  void _onPrevious() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _targetPosition = null;
        _targetSize = null;
        _currentStepData = null;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _updateCurrentStep();
      });
    }
  }

  void _onSkip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (_targetPosition == null || _targetSize == null || _currentStepData == null) {
      // Show nothing while waiting for target to be found
      return const SizedBox.shrink();
    }

    return _TourOverlay(
      step: _currentStepData!,
      position: _targetPosition!,
      size: _targetSize!,
      currentStep: _currentStep,
      totalSteps: widget.steps.length,
      onNext: _onNext,
      onPrevious: _onPrevious,
      onSkip: _onSkip,
    );
  }
}

class _TourOverlay extends StatelessWidget {
  final TourStep step;
  final Offset position;
  final Size size;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;

  const _TourOverlay({
    required this.step,
    required this.position,
    required this.size,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final iconColor = step.iconColor ?? ColorClass.base_color;

    // Estimate tooltip height (progress bar + icon + title + description + buttons + padding)
    const estimatedTooltipHeight = 320.0;
    // Increased spacing to prevent overlap - more space for bottom navigation
    const tooltipSpacingAbove = 60.0; // Extra spacing when tooltip is above target
    const tooltipSpacingBelow = 30.0; // Spacing when tooltip is below target
    
    // Determine if tooltip should be shown above or below the target
    // For bottom navigation and bottom-aligned elements, show above
    // For top elements, show below
    bool showAbove = step.alignment == Alignment.bottomCenter || 
                     (position.dy > screenSize.height * 0.6); // If target is in bottom 40% of screen
    
    // Calculate tooltip position to avoid overlapping the target
    double tooltipTop;
    if (showAbove) {
      // Position tooltip above the target with increased spacing
      tooltipTop = position.dy - estimatedTooltipHeight - tooltipSpacingAbove;
      // Ensure it doesn't go off the top of the screen
      if (tooltipTop < 20) {
        // If not enough space above, position below instead
        tooltipTop = position.dy + size.height + tooltipSpacingBelow;
        showAbove = false;
      }
    } else {
      // Position tooltip below the target with spacing
      tooltipTop = position.dy + size.height + tooltipSpacingBelow;
      // Ensure it doesn't go off the bottom of the screen
      if (tooltipTop + estimatedTooltipHeight > screenSize.height - 20) {
        // If not enough space below, position above instead
        tooltipTop = position.dy - estimatedTooltipHeight - tooltipSpacingAbove;
        showAbove = true;
        // Final check - if still off screen, clamp it
        if (tooltipTop < 20) {
          tooltipTop = 20;
        }
      }
    }

    return Stack(
      children: [
        // Dark overlay with hole
        GestureDetector(
          onTap: onNext,
          child: CustomPaint(
            painter: HolePainter(
              holeRect: Rect.fromLTWH(
                position.dx,
                position.dy,
                size.width,
                size.height,
              ),
            ),
            child: Container(
              color: Colors.transparent,
              width: screenSize.width,
              height: screenSize.height,
            ),
          ),
        ),
        // Tooltip - positioned to avoid covering the target element
        Positioned(
          left: 20,
          right: 20,
          top: tooltipTop.clamp(20.0, screenSize.height - estimatedTooltipHeight - 20),
          bottom: null,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (currentStep + 1) / totalSteps,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${currentStep + 1}/$totalSteps",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      step.icon,
                      size: 40,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    step.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Navigation buttons
                  Row(
                    children: [
                      TextButton(
                        onPressed: onSkip,
                        child: const Text(
                          "Skip",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const Spacer(),
                      if (currentStep > 0)
                        OutlinedButton(
                          onPressed: onPrevious,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            side: BorderSide(color: iconColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Previous"),
                        ),
                      if (currentStep > 0) const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iconColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          currentStep < totalSteps - 1 ? "Next" : "Got it!",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HolePainter extends CustomPainter {
  final Rect holeRect;

  HolePainter({required this.holeRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..blendMode = BlendMode.srcOver;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Increase padding for better visibility, especially for larger sections like quick actions
    const padding = 12.0; // Increased from 8 to 12 for better visibility
    final holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            holeRect.left - padding,
            holeRect.top - padding,
            holeRect.width + (padding * 2),
            holeRect.height + (padding * 2),
          ),
          const Radius.circular(16), // Increased border radius for smoother look
        ),
      );

    final combinedPath = Path.combine(
      PathOperation.difference,
      path,
      holePath,
    );

    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
