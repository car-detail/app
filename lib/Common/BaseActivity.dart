import 'dart:io';

import 'package:file_picker/file_picker.dart';
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

  static Future<List<File>?> pickmultipleFile(
      {List<String> allowedExtensions = const [
        "pdf",
        "ppt",
        "xlsx",
        "doc",
        "png",
        "jpg",
        "jpeg",
        "aac",
        "m4a",
        "mp3",
        "wav"
      ],
      bool allowMultiple = true}) async {
    List<File> file = [];
    try {
      FilePickerResult? imagePicker = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: allowMultiple,
        allowedExtensions: allowedExtensions,
      );
      if (imagePicker != null) {
        file.addAll(imagePicker.paths.map((path) => File(path!)).toList());
      }
      return file;
    } catch (e) {
    }
    return null;
  }

  static Future<List<File>?> pickmedia(bool allowMultiple) async {
    List<File> file = [];
    try {
      FilePickerResult? imagePicker = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.media,
      );
      if (imagePicker != null) {
        file.addAll(imagePicker.paths.map((path) => File(path!)).toList());
      }
      return file;
    } catch (e) {
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
      // Request permissions
      /*var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }*/
      //if (status.isGranted) {
        FilePickerResult? imagePicker = await FilePicker.platform.pickFiles(
          allowMultiple: allowMultiple,
          type: FileType.image,
        );
        if (imagePicker != null) {
          files.addAll(imagePicker.paths.map((path) => File(path!)).toList());
        }
      /*} else {
      }*/
    } catch (e) {
    }
    return files;
  }

  static showFilePicker(
      BuildContext context, Function(List<File>? list) onTeacherSelected,
      {List<String> allowedExtensions = const [
        "pdf",
        "ppt",
        "xlsx",
        "doc",
        "aac",
        "m4a",
        "mp3",
        "wav"
      ],
      bool isFile = true,
      bool isPhoto = true,
      bool isOnlyPhoto = false,
      bool allowMultipleImage = true}) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            content: SizedBox(
              height: isOnlyPhoto ? 240 : 240,
              width: MediaQuery.of(context).size.width * 0.9,
              child: Stack(
                children: [
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(top: 8, right: 8),
                        decoration: BoxDecoration(
                          color: ColorClass.base_color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(left: 25, right: 25),
                          width: double.infinity,
                          child: Text(
                            isOnlyPhoto ? "Choose Photo" : "Choose Option For Attachment",
                            style: TextStyle(
                              color: ColorClass.base_color,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Divider(
                          height: 1,
                          color: ColorClass.light_gray_base,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        // If isOnlyPhoto is true, show only one centered Photo option with better UI
                        if (isOnlyPhoto)
                          Expanded(
                            child: Center(
                              child: _AnimatedPhotoButton(
                                onTap: () async {
                                  Navigator.pop(context);
                                  var listInage =
                                      await pickmedia(allowMultipleImage);
                                  onTeacherSelected(listInage);
                                },
                              ),
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (isFile)
                                GestureDetector(
                                  onTap: () async {
                                    Navigator.pop(context);
                                    var listInage = await pickmultipleFile(
                                        allowedExtensions: allowedExtensions);
                                    onTeacherSelected(listInage);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          CommonWidget.getImagePath("gallery-1.png"),
                                          height: 50,
                                          width: 50,
                                        ),
                                        const SizedBox(height: 8),
                                        CommonWidget.getTextWidgetPopSemi("File", size: 14)
                                      ],
                                    ),
                                  ),
                                ),
                              if (isPhoto && !isOnlyPhoto)
                                GestureDetector(
                                  onTap: () async {
                                    Navigator.pop(context);
                                    var listInage =
                                        await pickmedia(allowMultipleImage);
                                    onTeacherSelected(listInage);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                    decoration: BoxDecoration(
                                      color: ColorClass.base_color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: ColorClass.base_color,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
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
                                        const SizedBox(height: 8),
                                        Text(
                                          "Photo",
                                          style: TextStyle(
                                            color: ColorClass.base_color,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
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
