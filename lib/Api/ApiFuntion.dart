import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Common/CommonWidget.dart';
import '../Common/Constant.dart';
import '../error_model.dart';
import '../features/log_in/ui/new_login_activity.dart';

class ApiFuntions {
  Future<http.Response> getdatauser(BuildContext context, String endpoint,
      {/*String token = ""*/ bool cycle = true}) async {
    
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString(Constant.accessToken)??"";
    
    debugPrint('Context: $context');
    debugPrint('Token: ${token.isNotEmpty ? "***" : "empty"}');
    debugPrint("API URL: ${Constant.baseurl}$endpoint");
    try {
      List<InternetAddress> result = [];
      if(!kIsWeb) {
        result = await InternetAddress.lookup('google.com');
      }
      if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) || kIsWeb) {
        final url = '${Constant.baseurl}$endpoint';
        debugPrint('🔵 GET Request: $url');
        debugPrint('🔑 Token: ${token.isNotEmpty ? "Provided" : "Missing"}');
        
        final response = await http
            .get(Uri.parse(url), headers: {
          "Authorization": "Bearer $token",
          "ngrok-skip-browser-warning": "true"
        });
        
        debugPrint('🟢 GET Response ($url)');
        debugPrint('📊 Status: ${response.statusCode}');
        debugPrint('📄 Body: ${response.body}');
        
        if (response.statusCode == 200) {
          // Check if response is JSON before parsing
          try {
            Map<String, dynamic> message = (jsonDecode(response.body));
            return response;
          } catch (e) {
            debugPrint("⚠️ JSON Parse Error: $e");
            // Return the response even if it's not JSON (like HTML error pages)
            return response;
          }
        }else if(response.statusCode == 401){
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          //var data = ErrorModel.fromJson(jsonDecode(response.body));
          /*if(data.message!.length>0)
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);*/
          debugPrint(response.body);
          if (context.mounted) {
            sharedPreferences.clear();
            CommonWidget.navigateToKillAllScreen(context, const NewLoginActivity());
          }
          return response;
        }
        else {
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          var data = ErrorModel.fromJson(jsonDecode(response.body));
          if (context.mounted && data.message!.isNotEmpty) {
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);
          }
          debugPrint(response.body);
          return response;
          //Common.showToast(mes);
        }
      } else {
        Map<String, dynamic> message = {
          'status_message': "Please Check Network Connection"
        };
        var mes = message['status_message'];
        debugPrint(mes);
        if (context.mounted) showSnackBar(context, "Please Check Network Connection");
        return mes;
      }
    } on SocketException catch (_) {
      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
      Map<String, dynamic> message = {
        'status_message': "Please Check Network Connection"
      };
      var mes = message['status_message'];
      debugPrint(mes);
      showSnackBar(context, "Please Check Network Connection");
      return mes;
    }
  }
  Future<http.Response> deletedatauser(BuildContext context, String endpoint,
      {/*String token = ""*/ bool cycle = true}) async {
    
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString(Constant.accessToken)??"";
    debugPrint('Context: $context');
    debugPrint('Token: ${token.isNotEmpty ? "***" : "empty"}');
    debugPrint("API URL: ${Constant.baseurl}$endpoint");
    try {
      List<InternetAddress> result = [];
      if(!kIsWeb) {
        result = await InternetAddress.lookup('google.com');
      }
      if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) || kIsWeb) {
        final url = '${Constant.baseurl}$endpoint';
        debugPrint('🔴 DELETE Request: $url');
        
        final response = await http
            .delete(Uri.parse(url), headers: {
          "Authorization": "Bearer $token",
          "ngrok-skip-browser-warning": "true"
        });
        
        debugPrint('🟢 DELETE Response ($url)');
        debugPrint('📊 Status: ${response.statusCode}');
        debugPrint('📄 Body: ${response.body}');
        if (response.statusCode == 200) {
          Map<String, dynamic> message = (jsonDecode(response.body));
          return response;
        }else if(response.statusCode == 401){
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          //var data = ErrorModel.fromJson(jsonDecode(response.body));
          /*if(data.message!.length>0)
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);*/
          debugPrint(response.body);
          if (context.mounted) {
            sharedPreferences.clear();
            CommonWidget.navigateToKillAllScreen(context, const NewLoginActivity());
          }
          return response;
        }
        else {
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          var data = ErrorModel.fromJson(jsonDecode(response.body));
          if (context.mounted && data.message!.isNotEmpty) {
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);
          }
          debugPrint(response.body);
          return response;
          //Common.showToast(mes);
        }
      } else {
        Map<String, dynamic> message = {
          'status_message': "Please Check Network Connection"
        };
        var mes = message['status_message'];
        debugPrint(mes);
        if (context.mounted) showSnackBar(context, "Please Check Network Connection");
        return mes;
      }
    } on SocketException catch (_) {
      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
      Map<String, dynamic> message = {
        'status_message': "Please Check Network Connection"
      };
      var mes = message['status_message'];
      debugPrint(mes);
      showSnackBar(context, "Please Check Network Connection");
      return mes;
    }
  }

  Future<http.Response> postdatauser(
      BuildContext context, String endpoint, dynamic data,
      {String token = "", bool skipAutoNavigation = false}) async {
    
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString(Constant.accessToken)??"";
    debugPrint('Context: $context');
    debugPrint("=========datainjsonEncode${jsonEncode(data)} ");
    try {

      List<InternetAddress> result = [];
      if(!kIsWeb) {
        result = await InternetAddress.lookup('google.com');
      }
      if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) || kIsWeb) {
        final fullUrl = '${Constant.baseurl}$endpoint';
        debugPrint('🟡 POST Request: $fullUrl');
        debugPrint('📦 Body: ${jsonEncode(data)}');
        
        final response = await http.post(
            Uri.parse(fullUrl),
            body: jsonEncode(data),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
              "ngrok-skip-browser-warning": "true"
            });
            
        debugPrint('🟢 POST Response ($fullUrl)');
        debugPrint('📊 Status Code: ${response.statusCode}');
        debugPrint('📄 Response Body: ${response.body}');
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
            CommonWidget.safePop(context);
          }
          return response;
        }else if(response.statusCode == 401){
          if (!skipAutoNavigation) {
            if (context.mounted && Navigator.canPop(context)) {
              CommonWidget.safePop(context);
            }
            debugPrint(response.body);
          if (context.mounted && !skipAutoNavigation) {
            sharedPreferences.clear();
            CommonWidget.navigateToKillAllScreen(context, const NewLoginActivity());
          }
          }
          return response;
        }

        else {
          if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
            CommonWidget.safePop(context);
          }
          // Handle both custom error format and NestJS default error format (404, etc.)
          try {
            Map<String, dynamic> errorData = jsonDecode(response.body);
            String errorMessage = "";
            
            // Handle NestJS default format: {"message":"...", "error":"...", "statusCode":404}
            if (errorData['message'] != null) {
              if (errorData['message'] is List) {
                // Custom format with array
                List<dynamic> messageList = errorData['message'] as List<dynamic>;
                errorMessage = messageList.isNotEmpty ? messageList[0].toString() : "An error occurred";
              } else {
                // NestJS default format with string
                errorMessage = errorData['message'].toString();
              }
            } else if (errorData['error'] != null) {
              errorMessage = errorData['error'].toString();
            } else {
              errorMessage = "An error occurred (Status: ${response.statusCode})";
            }
            
            if (context.mounted && errorMessage.isNotEmpty) {
              if (context.mounted) CommonWidget.errorShowSnackBarFor(context, errorMessage);
            }
          } catch (e) {
            // Fallback if JSON parsing fails
            CommonWidget.errorShowSnackBarFor(context, "Error: ${response.statusCode}");
          }
          debugPrint(response.body);
          return response;
        }
      } else {
        Map<String, dynamic> message = {
          'status_message': "Please Check Network Connection"
        };
        var mes = message['status_message'];
        debugPrint(mes);
        showSnackBar(context, "Please Check Network Connection");
        return mes;
      }
    } on SocketException catch (_) {
      Map<String, dynamic> message = {
        'status_message': "Please Check Network Connection"
      };
      var mes = message['status_message'];
      debugPrint(mes);
      showSnackBar(context, "Please Check Network Connection");
      return mes;
    }
  }
  Future<http.Response> putdatauser(
      BuildContext context, String endpoint, dynamic data,
      {String token = "", bool skipAutoNavigation = false}) async {
    
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString(Constant.accessToken)??"";
    debugPrint('Context: $context');
    debugPrint("=========datainjsonEncode${jsonEncode(data)} ");
    try {

      List<InternetAddress> result = [];
      if(!kIsWeb) {
        result = await InternetAddress.lookup('google.com');
      }
      if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) || kIsWeb) {
        final url = '${Constant.baseurl}$endpoint';
        debugPrint('🟠 PUT Request: $url');
        debugPrint('📦 Body: ${jsonEncode(data)}');
        
        final response = await http.put(
            Uri.parse(url),
            body: jsonEncode(data),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
              "ngrok-skip-browser-warning": "true"
            });
            
        debugPrint('🟢 PUT Response ($url)');
        debugPrint('📊 Status Code: ${response.statusCode}');
        debugPrint('📄 Response Body: ${response.body}');
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
          return response;
        }else if(response.statusCode == 401){
          if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          //var data = ErrorModel.fromJson(jsonDecode(response.body));
          /*if(data.message!.length>0)
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);*/
          debugPrint(response.body);
          if (context.mounted) {
            sharedPreferences.clear();
            CommonWidget.navigateToKillAllScreen(context, const NewLoginActivity());
          }
          return response;
        }else {
          if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
          var data = ErrorModel.fromJson(jsonDecode(response.body));
          if (context.mounted && data.message!.isNotEmpty) {
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);
          }
          debugPrint(response.body);
          return response;
          //Common.showToast(mes);
        }
      } else {
        Map<String, dynamic> message = {
          'status_message': "Please Check Network Connection"
        };
        var mes = message['status_message'];
        debugPrint(mes);
        if (context.mounted) showSnackBar(context, "Please Check Network Connection");
        return mes;
      }
    } on SocketException catch (_) {
      Map<String, dynamic> message = {
        'status_message': "Please Check Network Connection"
      };
      var mes = message['status_message'];
      debugPrint(mes);
      showSnackBar(context, "Please Check Network Connection");
      return mes;
    }
  }

  Future<http.Response> patchdatauser(
      BuildContext context, String endpoint, dynamic data,
      {String token = "", bool skipAutoNavigation = false}) async {
    
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString(Constant.accessToken)??"";
    debugPrint('Context: $context');
    debugPrint("=========datainjsonEncode${jsonEncode(data)} ");
    try {
      List<InternetAddress> result = [];
      if(!kIsWeb) {
        result = await InternetAddress.lookup('google.com');
      }
      if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) || kIsWeb) {
        final url = '${Constant.baseurl}$endpoint';
        debugPrint('🟣 PATCH Request: $url');
        debugPrint('📦 Body: ${jsonEncode(data)}');
        
        final response = await http.patch(
            Uri.parse(url),
            body: jsonEncode(data),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
              "ngrok-skip-browser-warning": "true"
            });
            
        debugPrint('🟢 PATCH Response ($url)');
        debugPrint('📊 Status Code: ${response.statusCode}');
        debugPrint('📄 Response Body: ${response.body}');
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
            CommonWidget.safePop(context);
          }
          return response;
        } else if(response.statusCode == 401){
          if (!skipAutoNavigation) {
            if (context.mounted && Navigator.canPop(context)) {
              CommonWidget.safePop(context);
            }
            debugPrint(response.body);
            if (context.mounted) {
              sharedPreferences.clear();
              CommonWidget.navigateToKillAllScreen(context, const NewLoginActivity());
            }
          }
          return response;
        } else {
          if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
            CommonWidget.safePop(context);
          }
          try {
            var data = ErrorModel.fromJson(jsonDecode(response.body));
            if (context.mounted && data.message!.isNotEmpty) {
              CommonWidget.errorShowSnackBarFor(context, data.message![0]);
            }
          } catch (_) {
            CommonWidget.errorShowSnackBarFor(context, "Error: ${response.statusCode}");
          }
          debugPrint(response.body);
          return response;
        }
      } else {
        Map<String, dynamic> message = {
          'status_message': "Please Check Network Connection"
        };
        var mes = message['status_message'];
        debugPrint(mes);
        if (context.mounted) showSnackBar(context, "Please Check Network Connection");
        return http.Response(jsonEncode(message), 400);
      }
    } on SocketException catch (_) {
      Map<String, dynamic> message = {
        'status_message': "Please Check Network Connection"
      };
      var mes = message['status_message'];
      debugPrint(mes);
      if (context.mounted) showSnackBar(context, "Please Check Network Connection");
      return http.Response(jsonEncode(message), 400);
    }
  }

  Future<File> _compressImageIfNeeded(File file, int maxImageSize) async {
    if (kIsWeb) {
      return file;
    }
    if (!await file.exists()) {
      return file;
    }
    final originalSize = await file.length();
    if (originalSize <= maxImageSize) {
      return file;
    }
    final tempDir = await getTemporaryDirectory();
    File compressedFile = file;
    int quality = 85;
    int minWidth = 2000;
    int minHeight = 2000;
    for (int i = 0; i < 6; i++) {
      final targetPath = '${tempDir.path}/offer_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final xFile = await FlutterImageCompress.compressAndGetFile(
        compressedFile.path,
        targetPath,
        format: CompressFormat.jpeg,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        keepExif: false,
      );
      if (xFile == null) {
        break;
      }
      compressedFile = File(xFile.path);
      final compressedSize = await compressedFile.length();
      if (compressedSize <= maxImageSize) {
        return compressedFile;
      }
      quality = quality > 30 ? quality - 15 : quality;
      minWidth = minWidth > 900 ? (minWidth * 0.8).round() : minWidth;
      minHeight = minHeight > 900 ? (minHeight * 0.8).round() : minHeight;
    }
    return compressedFile;
  }

  String _getFileNameFromPath(String filePath) {
    var fileName = filePath.split('/').last;
    if (fileName.isEmpty || fileName == filePath) {
      fileName = filePath.split('\\').last;
    }
    return fileName;
  }

  String _getFileExtension(String fileName) {
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex > 0 && lastDotIndex < fileName.length - 1) {
      return fileName.substring(lastDotIndex).toLowerCase();
    }
    return '';
  }

  Future<http.Response> sendMultipartRequest(BuildContext context, String url,
      List<File> files, Map<String, dynamic> data,
      {String filekey = "file", bool skipAutoNavigation = false}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString(Constant.accessToken)??"";
    
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constant.baseurl}$url'),
      );
      request.headers.addAll({
    "Authorization": "Bearer $token",
    "ngrok-skip-browser-warning": "true"
    });
      // File size limits (in bytes)
      const int maxImageSize = 900 * 1024; // 900 KB for images to stay under server's 1 MB Nginx limit
      const int maxFileSize = 100 * 1024 * 1024; // 100 MB absolute max

      // Allowed image extensions only
      final allowedImageExtensions = ['.jpg', '.jpeg', '.png'];
      final heicExtensions = ['.heic', '.heif']; // iPhone formats — auto-converted to JPEG

      // Add files to the request with validation
      for (var file in files) {
        Uint8List? fileBytes;
        File uploadFile = file;
        String fileName;
        String fileExtension = '';
        int fileSize = 0;

        if (kIsWeb) {
          try {
            fileBytes = await file.readAsBytes();
            fileSize = fileBytes.length;
            fileName = _getFileNameFromPath(file.path);
            if (fileName.isEmpty || fileName == file.path) {
              fileName = 'uploaded_file';
            }
            fileExtension = _getFileExtension(fileName);
            if (fileExtension.isEmpty && fileBytes.isNotEmpty) {
              if (fileBytes.length >= 2) {
                if (fileBytes[0] == 0xFF && fileBytes[1] == 0xD8) {
                  fileExtension = '.jpg';
                  fileName = fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') ? fileName : '$fileName.jpg';
                } else if (fileBytes.length >= 8 && fileBytes[0] == 0x89 && fileBytes[1] == 0x50 && fileBytes[2] == 0x4E && fileBytes[3] == 0x47) {
                  fileExtension = '.png';
                  fileName = fileName.endsWith('.png') ? fileName : '$fileName.png';
                }
              }
            }
            debugPrint('📁 Web File: $fileName, Extension: $fileExtension, Size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
          } catch (e) {
            if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
              CommonWidget.safePop(context);
            }
            if (context.mounted) {
              CommonWidget.errorShowSnackBarFor(context, 'Error reading file on web: ${e.toString()}');
            }
            throw Exception('Error reading file on web: $e');
          }
        } else {
          fileName = _getFileNameFromPath(file.path);
          fileExtension = _getFileExtension(fileName).toLowerCase();

          // ── HEIC / HEIF → JPEG auto-conversion ──────────────────────────
          if (heicExtensions.contains(fileExtension)) {
            debugPrint('🔄 HEIC detected — converting to JPEG automatically...');
            try {
              final tempDir = await getTemporaryDirectory();
              final targetPath = '${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final xFile = await FlutterImageCompress.compressAndGetFile(
                file.path,
                targetPath,
                format: CompressFormat.jpeg,
                quality: 90,
                keepExif: false,
              );
              if (xFile != null) {
                uploadFile = File(xFile.path);
                fileName = _getFileNameFromPath(uploadFile.path);
                fileExtension = '.jpg';
                debugPrint('✅ HEIC → JPEG conversion successful: $fileName');
              } else {
                debugPrint('⚠️ HEIC conversion returned null — using original file');
              }
            } catch (convErr) {
              debugPrint('⚠️ HEIC conversion failed ($convErr) — using original file');
            }
          }
          // ────────────────────────────────────────────────────────────────

          if (fileExtension.isEmpty) {
            if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
              CommonWidget.safePop(context);
            }
            if (context.mounted) {
              CommonWidget.errorShowSnackBarFor(context, 'File has no extension: $fileName');
            }
            throw Exception('File has no extension: $fileName');
          }
          debugPrint('📁 Mobile File: $fileName, Extension: $fileExtension, Full Path: ${uploadFile.path}');
          try {
            if (!await uploadFile.exists()) {
              if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
                CommonWidget.safePop(context);
              }
              if (context.mounted) {
                CommonWidget.errorShowSnackBarFor(context, 'File not found: $fileName');
              }
              throw Exception('File not found: $fileName');
            }
            fileSize = await uploadFile.length();
          } catch (e) {
            if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
              CommonWidget.safePop(context);
            }
            if (context.mounted) {
              CommonWidget.errorShowSnackBarFor(context, 'Error checking file: $e');
            }
            throw Exception('Error checking file: $e');
          }
        }

        debugPrint('📊 File size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');

        if (fileSize > maxFileSize) {
          if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
            CommonWidget.safePop(context);
          }
          if (context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, 'File size exceeds maximum limit (100 MB)');
          }
          throw Exception('File size exceeds maximum limit: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        }

        bool isImage = allowedImageExtensions.contains(fileExtension);

        if (!isImage) {
          if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
            CommonWidget.safePop(context);
          }
          if (context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, 'Only image files (JPG, PNG) are allowed. Please choose an image.');
          }
          throw Exception('Unsupported file format: $fileExtension');
        }

        // After HEIC conversion, re-evaluate isImage with updated extension
        isImage = allowedImageExtensions.contains(fileExtension);

        if (!kIsWeb && isImage && fileSize > maxImageSize) {
          uploadFile = await _compressImageIfNeeded(file, maxImageSize);
          fileSize = await uploadFile.length();
          fileName = _getFileNameFromPath(uploadFile.path);
          fileExtension = _getFileExtension(fileName);
          isImage = allowedImageExtensions.contains(fileExtension);
        }

        if (isImage && fileSize > maxImageSize) {
          if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
            CommonWidget.safePop(context);
          }
          if (context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, 'Image size exceeds maximum limit (1 MB). Please choose a smaller image.');
          }
          throw Exception('Image size exceeds maximum limit: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        }

        MediaType contentType;
        if (fileExtension == '.png') {
          contentType = MediaType('image', 'png');
        } else {
          contentType = MediaType('image', 'jpeg');
        }

        debugPrint('📄 Content Type: ${contentType.mimeType}');

        try {
          if (kIsWeb && fileBytes != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                filekey,
                fileBytes,
                filename: fileName,
                contentType: contentType,
              ),
            );
          } else {
            request.files.add(
              await http.MultipartFile.fromPath(
                filekey,
                uploadFile.path,
                filename: fileName,
                contentType: contentType,
              ),
            );
          }
        } catch (e) {
          if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
            CommonWidget.safePop(context);
          }
          CommonWidget.errorShowSnackBarFor(context, 'Error reading image file: ${e.toString()}');
          throw Exception('Error reading file: $e');
        }
      }
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      debugPrint('🟣 MULTIPART Request: ${Constant.baseurl}$url');
      debugPrint('Fields: ${request.fields}');
      debugPrint('Files: ${request.files.map((f) => f.filename).toList()}');

      http.StreamedResponse streamedResponse;
      http.Response response;
      try {
        streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } catch (sendError) {
        // Network error AFTER bytes were sent — server may have already stored
        // the file. Surface a specific message so the caller can inform the user.
        if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        const msg = 'Network error after upload — server may have received the file. Please verify before retrying.';
        if (context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, msg);
        }
        throw Exception(msg);
      }

      debugPrint('🟢 MULTIPART Response (${Constant.baseurl}$url)');
      debugPrint('📊 Status: ${response.statusCode}');
      debugPrint('📄 Body: ${response.body}');

      // Handle the response
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
        if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        debugPrint('Success: ${response.body}');
        return response; // Return the response body upon success
      }else if(response.statusCode == 401){
        // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
        if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
        //var data = ErrorModel.fromJson(jsonDecode(response.body));
        /*if(data.message!.length>0)
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);*/
        debugPrint(response.body);
        // Only auto-navigate if skipAutoNavigation is false
        if (!skipAutoNavigation) {
        if (context.mounted && !skipAutoNavigation) {
          sharedPreferences.clear();
          CommonWidget.navigateToKillAllScreen(context, const NewLoginActivity());
        }
        }
        return response;
      }

      else {
        // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
        if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        var data = ErrorModel.fromJson(jsonDecode(response.body));
        if (context.mounted && data.message!.isNotEmpty) {
          CommonWidget.errorShowSnackBarFor(context, data.message![0]);
        }
        debugPrint(response.body);
        return response;
      }
    } catch (e) {
      // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
      if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
      debugPrint('Error sending files to server: $e');
      String errorMessage = 'Failed to upload files';
      
      // Provide user-friendly error messages
      if (e.toString().contains('File not found')) {
        errorMessage = 'File not found. Please select a valid file.';
      } else if (e.toString().contains('File size exceeds')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else if (e.toString().contains('Unsupported file format')) {
        errorMessage = 'Unsupported file format. Please use images (JPG, PNG) or documents (PDF, DOC, XLS, PPT)';
      } else if (e.toString().contains('Error reading file')) {
        errorMessage = 'Error reading file. The file may be corrupted or inaccessible.';
      } else {
        errorMessage = 'Failed to upload files. Please check your internet connection and try again.';
      }
      
      if (context.mounted) CommonWidget.errorShowSnackBarFor(context, errorMessage);
      throw Exception(errorMessage);
    }
  }

  void showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
        backgroundColor: Colors.red[100],
        content: Container(
            child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.red, fontWeight: FontWeight.w500, fontSize: 16),
        )));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  logout(BuildContext context, SharedPreferences sharedPreferences) async {

  }
}
