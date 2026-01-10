import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Color.dart';

/// First-time user tutorial overlay system
class FirstTimeTutorial {
  static const String _tutorialKey = 'has_seen_tutorial';

  /// Check if user has seen the tutorial
  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialKey) ?? false;
  }

  /// Mark tutorial as seen
  static Future<void> markTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
  }

  /// Show tutorial overlay for dashboard
  static Future<void> showDashboardTutorial(BuildContext context) async {
    final hasSeen = await hasSeenTutorial();
    if (hasSeen) return;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: false,
      builder: (context) => _TutorialDialog(
        title: "Welcome to Your Dashboard! 👋",
        steps: [
          TutorialStep(
            title: "Home Tab",
            description: "See your business overview, manage services, and view your shop status",
            icon: Icons.home_rounded,
          ),
          TutorialStep(
            title: "Bookings Tab",
            description: "View and manage all customer bookings. Tap to see details, complete, or cancel bookings",
            icon: Icons.calendar_today_rounded,
          ),
          TutorialStep(
            title: "Profile Tab",
            description: "Edit your business details, update your profile, and manage settings",
            icon: Icons.person_rounded,
          ),
        ],
        onComplete: () async {
          await markTutorialAsSeen();
          Navigator.pop(context);
        },
      ),
    );
  }
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _TutorialDialog extends StatefulWidget {
  final String title;
  final List<TutorialStep> steps;
  final VoidCallback onComplete;

  const _TutorialDialog({
    required this.title,
    required this.steps,
    required this.onComplete,
  });

  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / widget.steps.length,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${_currentStep + 1}/${widget.steps.length}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorClass.base_color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.icon,
                size: 48,
                color: ColorClass.base_color,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              step.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              step.description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Navigation buttons
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: ColorClass.base_color),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Previous"),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < widget.steps.length - 1) {
                        setState(() {
                          _currentStep++;
                        });
                      } else {
                        widget.onComplete();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorClass.base_color,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentStep < widget.steps.length - 1 ? "Next" : "Got it!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}








