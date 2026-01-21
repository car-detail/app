import 'package:flutter/material.dart';
import 'Color.dart';

/// Helper widget for layman-friendly UX components
class UXHelperWidget {
  /// Build a help icon button that shows tooltip on tap
  static Widget buildHelpIcon({
    required String helpText,
    String? title,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        // Will be shown via showHelpDialog
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: (color ?? ColorClass.base_color).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.help_outline,
          size: 14,
          color: color ?? ColorClass.base_color,
        ),
      ),
    );
  }

  /// Show help dialog with clear explanation
  static void showHelpDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? example,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: ColorClass.base_color, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
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
            Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            if (example != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Example:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      example,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Got it!",
              style: TextStyle(
                color: ColorClass.base_color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build input field with help icon and better UX
  static Widget buildHelpfulInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String helpText,
    String? example,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
    BuildContext? context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  if (isRequired)
                    const Text(
                      " *",
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                ],
              ),
            ),
            if (context != null)
              GestureDetector(
                onTap: () {
                  showHelpDialog(
                    context,
                    title: label,
                    message: helpText,
                    example: example,
                  );
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: ColorClass.base_color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.help_outline,
                    size: 14,
                    color: ColorClass.base_color,
                  ),
                ),
              ),
          ],
        ),
        if (helpText.isNotEmpty && context == null) ...[
          const SizedBox(height: 4),
          Text(
            helpText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: ColorClass.base_color),
            hintText: hintText ?? "Enter $label",
            helperText: example != null ? "Example: $example" : null,
            helperMaxLines: 3,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ColorClass.base_color, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Build friendly error message
  static void showFriendlyError(BuildContext context, String message) {
    final mediaQuery = MediaQuery.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: mediaQuery.size.height - mediaQuery.padding.top - 100,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: "OK",
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Build success message
  static void showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 100,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Build info banner for guidance
  static Widget buildInfoBanner({
    required String message,
    IconData icon = Icons.info_outline,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: (backgroundColor ?? Colors.blue[50])!,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (iconColor ?? Colors.blue[300]!),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? Colors.blue[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build step indicator with clear labels
  static Widget buildStepIndicator({
    required int currentStep,
    required int totalSteps,
    required List<String> stepLabels,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index < totalSteps - 1 ? 8 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: index <= currentStep
                            ? ColorClass.base_color
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    if (index < stepLabels.length) ...[
                      const SizedBox(height: 8),
                      Text(
                        stepLabels[index],
                        style: TextStyle(
                          fontSize: 10,
                          color: index <= currentStep
                              ? ColorClass.base_color
                              : Colors.grey[500],
                          fontWeight: index == currentStep
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            "Step ${currentStep + 1} of $totalSteps",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build example card showing what to enter
  static Widget buildExampleCard({
    required String title,
    required String example,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            example,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}








