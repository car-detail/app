import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'Color.dart';
import 'CommonWidget.dart';

class BaseActivity {
  static bool checkEmptyField(
      {required TextEditingController editingController,
      required String message,
      required BuildContext context}) {
    if (editingController.text.toString() == "") {
      CommonWidget.errorShowSnackBarFor(context, message);
      return true;
    } else {
      return false;
    }
  }

  static Future<List<XFile>?> pickmultipleImageAndroid13() async {
    final ImagePicker imagePicker = ImagePicker();
    /*final pickedImage =
        await _imagePicker.pickImage(source: ImageSource.gallery);

*/
    try {
      final pickedImage =
          await imagePicker.pickMultiImage(maxHeight: 1000, maxWidth: 1000);
      return pickedImage;
        } catch (e) {
    }
    return null;
  }

  static Future<List<File>?> pickmedia(bool allowMultiple) async {
    List<File> files = [];
    try {
      final ImagePicker picker = ImagePicker();
      if (allowMultiple) {
        final List<XFile> pickedImages = await picker.pickMultiImage();
        if (pickedImages.isNotEmpty) {
          files.addAll(pickedImages.map((xFile) => File(xFile.path)).toList());
        }
      } else {
        final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
        if (pickedImage != null) {
          files.add(File(pickedImage.path));
        }
      }
      return files.isNotEmpty ? files : null;
    } catch (e) {
      debugPrint("Error in pickmedia: $e");
    }
    return null;
  }

  /*static Future<List<File>?> pickImage(bool allowMultiple) async {
    List<File> file = [];
    try {
      FilePickerResult? _imagePicker = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.image,
      );
      if (_imagePicker != null) {
        file.addAll(_imagePicker.paths.map((path) => File(path!)).toList());
      }
      return file;
    } catch (e) {
    }
  }*/
  static Future<List<File>?> pickImage(bool allowMultiple) async {
    List<File> files = [];
    try {
      final ImagePicker picker = ImagePicker();
      if (allowMultiple) {
        final List<XFile> pickedImages = await picker.pickMultiImage();
        if (pickedImages.isNotEmpty) {
          files.addAll(pickedImages.map((xFile) => File(xFile.path)).toList());
        }
      } else {
        final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
        if (pickedImage != null) {
          files.add(File(pickedImage.path));
        }
      }
    } catch (e) {
      debugPrint("Error in pickImage: $e");
    }
    return files.isNotEmpty ? files : null;
  }

  /// Opens the image picker directly — no dialog, no file option.
  /// [allowMultipleImage] controls whether multiple images can be selected.
  static Future<void> showFilePicker(
      BuildContext context,
      Function(List<File>? list) onTeacherSelected,
      {
      @Deprecated('No longer used — file upload removed') List<String> allowedExtensions = const [],
      @Deprecated('No longer used — always image only') bool isFile = false,
      @Deprecated('No longer used — always image only') bool isPhoto = true,
      @Deprecated('No longer used — always image only') bool isOnlyPhoto = true,
      bool allowMultipleImage = true,
      }) async {
    final list = await pickmedia(allowMultipleImage);
    onTeacherSelected(list);
  }
}

// Animated Photo Button Widget
class _AnimatedPhotoButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedPhotoButton({required this.onTap});

  @override
  State<_AnimatedPhotoButton> createState() => _AnimatedPhotoButtonState();
}

class _AnimatedPhotoButtonState extends State<_AnimatedPhotoButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _tapController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _tapScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for continuous effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Tap animation for feedback
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _tapScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _tapController,
        curve: Curves.easeInOut,
      ),
    );

    // Start continuous pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _tapController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _tapController.reverse().then((_) {
      widget.onTap();
    });
  }

  void _handleTapCancel() {
    _tapController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _tapController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _tapScaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              decoration: BoxDecoration(
                color: ColorClass.base_color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorClass.base_color,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorClass.base_color.withOpacity(0.2 * (1 - (_pulseAnimation.value - 1.0) / 0.08)),
                    blurRadius: 12 * (_pulseAnimation.value - 1.0) / 0.08,
                    spreadRadius: 1.5 * (_pulseAnimation.value - 1.0) / 0.08,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ColorClass.base_color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Choose Photo",
                    style: TextStyle(
                      color: ColorClass.base_color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
