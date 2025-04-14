import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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
    final ImagePicker _imagePicker = ImagePicker();
    /*final pickedImage =
        await _imagePicker.pickImage(source: ImageSource.gallery);

*/
    try {
      final pickedImage =
          await _imagePicker.pickMultiImage(maxHeight: 1000, maxWidth: 1000);
      if (pickedImage != null) {
        print("file.name ${pickedImage[0].name}");
        print("file.path ${pickedImage[0].path}");
        return pickedImage;
      } else {
        return pickedImage;
      }
    } catch (e) {
      print(e);
    }
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
      FilePickerResult? _imagePicker = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: allowMultiple,
        allowedExtensions: allowedExtensions,
      );
      if (_imagePicker != null) {
        file.addAll(_imagePicker.paths.map((path) => File(path!)).toList());
      }
      return file;
    } catch (e) {
      print(e);
    }
  }

  static Future<List<File>?> pickmedia(bool allowMultiple) async {
    List<File> file = [];
    try {
      FilePickerResult? _imagePicker = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.media,
      );
      if (_imagePicker != null) {
        file.addAll(_imagePicker.paths.map((path) => File(path!)).toList());
      }
      return file;
    } catch (e) {
      print(e);
    }
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
      print(e);
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
        FilePickerResult? _imagePicker = await FilePicker.platform.pickFiles(
          allowMultiple: allowMultiple,
          type: FileType.image,
        );
        if (_imagePicker != null) {
          files.addAll(_imagePicker.paths.map((path) => File(path!)).toList());
        }
      /*} else {
        print("Permission not granted");
      }*/
    } catch (e) {
      print("Error picking files: $e");
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
            content: Container(
              height: 156,
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
                        padding: EdgeInsets.only(top: 10, right: 10),
                        child: Image(
                          image: AssetImage("assets/images/delete.png"),
                          height: 25,
                          width: 25,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 25, right: 25),
                          width: double.infinity,
                          child: CommonWidget.getTextWidgetPopSemi(
                              "Choose Option For Attachment",
                              color: ColorClass.base_color),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Divider(
                          height: 1,
                          color: ColorClass.light_gray_base,
                        ),
                        SizedBox(
                          height: 15,
                        ),
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
                                child: Column(children: [
                                  Image.asset(
                                    CommonWidget.getImagePath("gallery-1.png"),
                                    height: 50,
                                    width: 50,
                                  ),
                                  CommonWidget.getTextWidgetPopSemi("File",
                                      size: 14)
                                ]),
                              ),
                            if (isPhoto)
                              GestureDetector(
                                onTap: () async {
                                  Navigator.pop(context);
                                  var listInage =
                                      await pickmedia(allowMultipleImage);
                                  onTeacherSelected(listInage);
                                },
                                child: Column(children: [
                                  Image.asset(
                                    CommonWidget.getImagePath("gallery.png"),
                                    height: 50,
                                    width: 50,
                                  ),
                                  CommonWidget.getTextWidgetPopSemi("Photo",
                                      size: 14)
                                ]),
                              ),
                            if (isOnlyPhoto)
                              GestureDetector(
                                onTap: () async {
                                  Navigator.pop(context);
                                  var listInage =
                                      await pickmedia(allowMultipleImage);
                                  onTeacherSelected(listInage);
                                },
                                child: Column(children: [
                                  Image.asset(
                                    CommonWidget.getImagePath("gallery.png"),
                                    height: 50,
                                    width: 50,
                                  ),
                                  CommonWidget.getTextWidgetPopSemi("Photo",
                                      size: 14)
                                ]),
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
