import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Common/CommonWidget.dart';
import '../Common/Constant.dart';
import '../error_model.dart';
import '../features/log_in/ui/modern_login_activity.dart';

class ApiFuntions {
  Future<http.Response> getdatauser(BuildContext context, String endpoint,
      {/*String token = ""*/ bool cycle = true}) async {
    FocusManager.instance.primaryFocus?.unfocus();
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
        debugPrint('🔑 Token: ${token.isNotEmpty ? "Provided (Configured)" : "Missing"}');
        
        final response = await http
            .get(Uri.parse(url), headers: {
          "Authorization": "Bearer $token",
          "ngrok-skip-browser-warning": "true"
        });
        
        debugPrint('🟢 GET Response: $url');
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
          sharedPreferences.clear();
          CommonWidget.navigateToKillAllScreen(context, const ModernLoginActivity());
          return response;
        }
        else {
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          var data = ErrorModel.fromJson(jsonDecode(response.body));
          if(data.message!.isNotEmpty) {
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
        showSnackBar(context, "Please Check Network Connection");
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
    FocusManager.instance.primaryFocus?.unfocus();
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
        final response = await http
            .delete(Uri.parse('${Constant.baseurl}$endpoint'), headers: {
          "Authorization": "Bearer $token"
        });
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint(response.body);
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
          sharedPreferences.clear();
          CommonWidget.navigateToKillAllScreen(context, const ModernLoginActivity());
          return response;
        }
        else {
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          var data = ErrorModel.fromJson(jsonDecode(response.body));
          if(data.message!.isNotEmpty) {
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
        showSnackBar(context, "Please Check Network Connection");
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
    FocusManager.instance.primaryFocus?.unfocus();
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
        debugPrint("🔗 Full API URL: $fullUrl");
        debugPrint("📦 Base URL: ${Constant.baseurl}");
        debugPrint("📋 Endpoint: $endpoint");
        final response = await http.post(
            Uri.parse(fullUrl),
            body: jsonEncode(data),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
              "ngrok-skip-browser-warning": "true"
            });
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
          sharedPreferences.clear();
          CommonWidget.navigateToKillAllScreen(context, const ModernLoginActivity());
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
            
            if (errorMessage.isNotEmpty) {
              CommonWidget.errorShowSnackBarFor(context, errorMessage);
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
      {String token = ""}) async {
    FocusManager.instance.primaryFocus?.unfocus();
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
        final response = await http.put(
            Uri.parse('${Constant.baseurl}$endpoint'),
            body: jsonEncode(data),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
              "ngrok-skip-browser-warning": "true"
            });
        debugPrint("${Constant.baseurl}$endpoint");
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
          return response;
        }else if(response.statusCode == 401){
          if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          //var data = ErrorModel.fromJson(jsonDecode(response.body));
          /*if(data.message!.length>0)
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);*/
          debugPrint(response.body);
          sharedPreferences.clear();
          CommonWidget.navigateToKillAllScreen(context, const ModernLoginActivity());
          return response;
        }else {
          if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
          var data = ErrorModel.fromJson(jsonDecode(response.body));
          if(data.message!.isNotEmpty) {
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

  Future<http.Response> sendMultipartRequest(BuildContext context, String url,
      List<File> files, Map<String, dynamic> data,
      {String filekey = "file", bool skipAutoNavigation = false}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString(Constant.accessToken)??"";
    FocusManager.instance.primaryFocus?.unfocus();
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
      const int maxImageSize = 5 * 1024 * 1024; // 5 MB for images
      const int maxDocumentSize = 10 * 1024 * 1024; // 10 MB for documents
      const int maxFileSize = 100 * 1024 * 1024; // 100 MB absolute max

      // Allowed file extensions (all lowercase since we convert to lowercase)
      final allowedImageExtensions = ['.jpg', '.jpeg', '.png'];
      final allowedDocumentExtensions = ['.pdf', '.doc', '.docx', '.xlsx', '.xls', '.ppt', '.pptx'];

      // Add files to the request with validation
      for (var file in files) {
        Uint8List? fileBytes;
        String fileName;
        String fileExtension = '';
        int fileSize = 0;
        
        // On web, read file as bytes since file.path might be invalid
        if (kIsWeb) {
          try {
            fileBytes = await file.readAsBytes();
            fileSize = fileBytes.length;
            
            // Try to extract file name from path, but use fallback if path is invalid
            try {
              var pathParts = file.path.split('/');
              if (pathParts.isNotEmpty && pathParts.last.isNotEmpty && pathParts.last != file.path) {
                fileName = pathParts.last;
              } else {
                pathParts = file.path.split('\\');
                if (pathParts.isNotEmpty && pathParts.last.isNotEmpty && pathParts.last != file.path) {
                  fileName = pathParts.last;
                } else {
                  // Fallback: use a default name based on content type detection
                  fileName = 'uploaded_file';
                }
              }
            } catch (e) {
              debugPrint('⚠️ Could not extract file name from path, using fallback: $e');
              fileName = 'uploaded_file';
            }
            
            // Try to detect extension from file name
            final lastDotIndex = fileName.lastIndexOf('.');
            if (lastDotIndex > 0 && lastDotIndex < fileName.length - 1) {
              fileExtension = fileName.substring(lastDotIndex).toLowerCase();
            }
            
            // If no extension found, try to detect from file bytes (magic numbers)
            if (fileExtension.isEmpty && fileBytes.isNotEmpty) {
              // Check for image signatures
              if (fileBytes.length >= 2) {
                if (fileBytes[0] == 0xFF && fileBytes[1] == 0xD8) {
                  fileExtension = '.jpg';
                  fileName = fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') ? fileName : '$fileName.jpg';
                } else if (fileBytes.length >= 8 && 
                           fileBytes[0] == 0x89 && fileBytes[1] == 0x50 && fileBytes[2] == 0x4E && fileBytes[3] == 0x47) {
                  fileExtension = '.png';
                  fileName = fileName.endsWith('.png') ? fileName : '$fileName.png';
                }
              }
            }
            
            debugPrint('📁 Web File: $fileName, Extension: $fileExtension, Size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
          } catch (e) {
            // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
        if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        CommonWidget.errorShowSnackBarFor(context, 'Error reading file on web: ${e.toString()}');
            throw Exception('Error reading file on web: $e');
          }
        } else {
          // Mobile: use file path
          // Handle both forward and backward slashes for cross-platform compatibility
          fileName = file.path.split('/').last;
          if (fileName.isEmpty || fileName == file.path) {
            fileName = file.path.split('\\').last;
          }
          
          // Extract file extension safely
          final lastDotIndex = fileName.lastIndexOf('.');
          if (lastDotIndex > 0 && lastDotIndex < fileName.length - 1) {
            fileExtension = fileName.substring(lastDotIndex).toLowerCase();
          } else {
        // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
        if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        CommonWidget.errorShowSnackBarFor(context, 'File has no extension: $fileName');
            throw Exception('File has no extension: $fileName');
          }
          
          debugPrint('📁 Mobile File: $fileName, Extension: $fileExtension, Full Path: ${file.path}');
          
          // Check if file exists and get size
          try {
            if (!await file.exists()) {
        // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
        if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        CommonWidget.errorShowSnackBarFor(context, 'File not found: $fileName');
              throw Exception('File not found: $fileName');
            }
          } catch (e) {
        // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
        if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        CommonWidget.errorShowSnackBarFor(context, 'Error checking file: $e');
            throw Exception('Error checking file: $e');
          }

          try {
            fileSize = await file.length();
          } catch (e) {
        // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
        if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        CommonWidget.errorShowSnackBarFor(context, 'Error reading file size: $e');
            throw Exception('Error reading file size: $e');
          }
        }
        
        debugPrint('📊 File size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        
        // Validate file size
        if (fileSize > maxFileSize) {
        // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
        if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        CommonWidget.errorShowSnackBarFor(context, 'File size exceeds maximum limit (100 MB)');
          throw Exception('File size exceeds maximum limit: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        }

        // Validate file format
        bool isImage = allowedImageExtensions.contains(fileExtension);
        bool isDocument = allowedDocumentExtensions.contains(fileExtension);
        
        debugPrint('🔍 Is Image: $isImage, Is Document: $isDocument');
        debugPrint('🔍 Allowed Image Extensions: $allowedImageExtensions');
        debugPrint('🔍 Allowed Document Extensions: $allowedDocumentExtensions');
        
        if (!isImage && !isDocument) {
        // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
        if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        CommonWidget.errorShowSnackBarFor(context, 'Unsupported file format: $fileExtension. Please use images (JPG, PNG) or documents (PDF, DOC, XLS, PPT)');
          throw Exception('Unsupported file format: $fileExtension');
        }

        // Validate size based on file type
        if (isImage && fileSize > maxImageSize) {
        // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
        if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        CommonWidget.errorShowSnackBarFor(context, 'Image size exceeds maximum limit (5 MB). Please compress the image.');
          throw Exception('Image size exceeds maximum limit: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        }

        if (isDocument && fileSize > maxDocumentSize) {
        // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
        if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        CommonWidget.errorShowSnackBarFor(context, 'Document size exceeds maximum limit (10 MB)');
          throw Exception('Document size exceeds maximum limit: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        }

        MediaType? contentType;
        if (fileExtension == '.pdf') {
          contentType = MediaType('application', 'pdf');
        } else if (fileExtension == '.doc' || fileExtension == '.docx') {
          contentType = MediaType('application', 'msword');
        } else if (fileExtension == '.xlsx' || fileExtension == '.xls') {
          contentType = MediaType('application', 'vnd.ms-excel');
        } else if (fileExtension == '.ppt' || fileExtension == '.pptx') {
          contentType = MediaType('application', 'vnd.ms-powerpoint');
        } else if (isImage) {
          // Set content type for images
          if (fileExtension == '.png') {
            contentType = MediaType('image', 'png');
          } else if (fileExtension == '.jpg' || fileExtension == '.jpeg') {
            contentType = MediaType('image', 'jpeg');
          }
        }

        debugPrint('📄 Content Type: ${contentType?.mimeType ?? "NULL"}');

        if (contentType != null) {
          try {
            if (kIsWeb && fileBytes != null) {
              // On web, use bytes directly
              request.files.add(
                http.MultipartFile.fromBytes(
                  filekey,
                  fileBytes,
                  filename: fileName,
                  contentType: contentType,
                ),
              );
            } else {
              // On mobile, use file path
              request.files.add(
                await http.MultipartFile.fromPath(
                  filekey,
                  file.path,
                  filename: fileName,
                  contentType: contentType,
                ),
              );
            }
          } catch (e) {
            // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
            if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
              CommonWidget.safePop(context);
            }
            CommonWidget.errorShowSnackBarFor(context, 'Error reading file: ${e.toString()}');
            throw Exception('Error reading file: $e');
          }
        } else {
          // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
          if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
            CommonWidget.safePop(context);
          }
          CommonWidget.errorShowSnackBarFor(context, 'Unsupported file format: $fileName');
          throw Exception('Unsupported file format: $fileName');
        }
      }
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      debugPrint('Request Body:');
      debugPrint('URL: $url');
      debugPrint('Headers: ${request.headers}');
      debugPrint('Files:');
      for (var file in request.files) {
        debugPrint('  - ${file.filename}');
      }
      debugPrint('Fields:');
      request.fields.forEach((key, value) {
        debugPrint('  $key: $value');
      });

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      debugPrint('Response Request: ${streamedResponse.request}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('Response: $response');

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
          sharedPreferences.clear();
          CommonWidget.navigateToKillAllScreen(context, const ModernLoginActivity());
        }
        return response;
      }

      else {
        // Only pop dialog if skipAutoNavigation is false (caller handles it if true)
        if (!skipAutoNavigation && context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        var data = ErrorModel.fromJson(jsonDecode(response.body));
        if(data.message!.isNotEmpty) {
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
      
      CommonWidget.errorShowSnackBarFor(context, errorMessage);
      throw Exception(errorMessage);
    }
  }
  Future<http.Response> patchdatauser(
      BuildContext context, String endpoint, dynamic data,
      {String token = ""}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString(Constant.accessToken) ?? "";
    debugPrint('Context: $context');
    debugPrint("=========datainjsonEncode${jsonEncode(data)} ");
    try {
      List<InternetAddress> result = [];
      if (!kIsWeb) {
        result = await InternetAddress.lookup('google.com');
      }
      if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) || kIsWeb) {
        final response = await http.patch(
            Uri.parse('${Constant.baseurl}$endpoint'),
            body: jsonEncode(data),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            });
        debugPrint("${Constant.baseurl}$endpoint");
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
          return response;
          /*Map<String, dynamic> message = (jsonDecode(response.body));
          if (message['status'] == true) {
            debugPrint(response);
            return response;
          } else {
            var error = message['message'];
            debugPrint(response.body);
            debugPrint(error);
            showSnackBar(context,error);
            return error;
          }*/
        } else if(response.statusCode == 401){
          if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          //var data = ErrorModel.fromJson(jsonDecode(response.body));
          /*if(data.message!.length>0)
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);*/
          debugPrint(response.body);
          sharedPreferences.clear();
          CommonWidget.navigateToKillAllScreen(context, const ModernLoginActivity());
          return response;
        } else {
          if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
          Map<String, dynamic> message = (jsonDecode(response.body));

          // Handle message as both string and array (backend returns array)
          String errorMessage = "";
          if (message['message'] != null) {
            if (message['message'] is List && (message['message'] as List).isNotEmpty) {
              errorMessage = (message['message'] as List)[0].toString();
            } else if (message['message'] is List && (message['message'] as List).isEmpty) {
              errorMessage = "An error occurred";
            } else {
              errorMessage = message['message'].toString();
            }
          }
          
          if (errorMessage.isNotEmpty) {
            CommonWidget.errorShowSnackBarFor(context, "$errorMessage Error Code");
          }
          debugPrint(response.body);
          debugPrint(errorMessage);
          showSnackBar(context, errorMessage);
          return response;
          //Common.showToast(mes);
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
