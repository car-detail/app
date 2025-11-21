import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Common/Color.dart';
import '../Common/CommonBean.dart';
import '../Common/CommonWidget.dart';
import '../Common/Constant.dart';
import '../error_model.dart';
import '../features/log_in/ui/LoginActivity.dart';

class ApiFuntions {
  Future<http.Response> getdatauser(BuildContext context, String endpoint,
      {/*String token = ""*/ bool cycle = true}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString(Constant.accessToken)??"";
    print(context);
    print(token);
    print("${Constant.baseurl}$endpoint");
    try {
      List<InternetAddress> result = [];
      if(!kIsWeb) {
        result = await InternetAddress.lookup('google.com');
      }
      if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) || kIsWeb) {
        if (cycle == true) showLoaderDialog(context);
        final response = await http
            .get(Uri.parse('${Constant.baseurl}$endpoint'), headers: {
          "Authorization": "Bearer $token",
          "ngrok-skip-browser-warning": "true"
        });
        print(response.statusCode);
        print(response.body);
        if (response.statusCode == 200) {
          if (cycle == true) Navigator.pop(context);
          // Check if response is JSON before parsing
          try {
            Map<String, dynamic> message = (jsonDecode(response.body));
            return response;
          } catch (e) {
            print("Error parsing JSON: $e");
            print("Response body: ${response.body}");
            // Return the response even if it's not JSON (like HTML error pages)
            return response;
          }
        }else if(response.statusCode == 401){
          if (cycle == true) Navigator.pop(context);
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          //var data = ErrorModel.fromJson(jsonDecode(response.body));
          /*if(data.message!.length>0)
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);*/
          print(response.body);
          sharedPreferences.clear();
          CommonWidget.navigateToScreen(context, LoginActivity("Login"));
          return response;
        }
        else {
          if (cycle == true) Navigator.pop(context);
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          var data = ErrorModel.fromJson(jsonDecode(response.body));
          if(data.message!.isNotEmpty) {
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);
          }
          print(response.body);
          return response;
          //Common.showToast(mes);
        }
      } else {
        Map<String, dynamic> message = {
          'status_message': "Please Check Network Connection"
        };
        var mes = message['status_message'];
        print(mes);
        showSnackBar(context, "Please Check Network Connection");
        return mes;
      }
    } on SocketException catch (_) {
      Navigator.pop(context);
      Map<String, dynamic> message = {
        'status_message': "Please Check Network Connection"
      };
      var mes = message['status_message'];
      print(mes);
      showSnackBar(context, "Please Check Network Connection");
      return mes;
    }
  }
  Future<http.Response> deletedatauser(BuildContext context, String endpoint,
      {/*String token = ""*/ bool cycle = true}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString(Constant.accessToken)??"";
    print(context);
    print(token);
    print("${Constant.baseurl}$endpoint");
    try {
      List<InternetAddress> result = [];
      if(!kIsWeb) {
        result = await InternetAddress.lookup('google.com');
      }
      if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) || kIsWeb) {
        if (cycle == true) showLoaderDialog(context);
        final response = await http
            .delete(Uri.parse('${Constant.baseurl}$endpoint'), headers: {
          "Authorization": "Bearer $token"
        });
        print(response.statusCode);
        print(response.body);
        if (response.statusCode == 200) {
          if (cycle == true) Navigator.pop(context);
          Map<String, dynamic> message = (jsonDecode(response.body));
          return response;
        }else if(response.statusCode == 401){
          if (cycle == true) Navigator.pop(context);
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          //var data = ErrorModel.fromJson(jsonDecode(response.body));
          /*if(data.message!.length>0)
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);*/
          print(response.body);
          sharedPreferences.clear();
          CommonWidget.navigateToScreen(context, LoginActivity("Login"));
          return response;
        }
        else {
          if (cycle == true) Navigator.pop(context);
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          var data = ErrorModel.fromJson(jsonDecode(response.body));
          if(data.message!.isNotEmpty) {
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);
          }
          print(response.body);
          return response;
          //Common.showToast(mes);
        }
      } else {
        Map<String, dynamic> message = {
          'status_message': "Please Check Network Connection"
        };
        var mes = message['status_message'];
        print(mes);
        showSnackBar(context, "Please Check Network Connection");
        return mes;
      }
    } on SocketException catch (_) {
      Navigator.pop(context);
      Map<String, dynamic> message = {
        'status_message': "Please Check Network Connection"
      };
      var mes = message['status_message'];
      print(mes);
      showSnackBar(context, "Please Check Network Connection");
      return mes;
    }
  }

  Future<http.Response> postdatauser(
      BuildContext context, String endpoint, dynamic data,
      {String token = ""}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString(Constant.accessToken)??"";
    print(context);
    print("=========datainjsonEncode${jsonEncode(data)} ");
    try {

      List<InternetAddress> result = [];
      if(!kIsWeb) {
        result = await InternetAddress.lookup('google.com');
      }
      if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) || kIsWeb) {
        showLoaderDialog(context);
        final response = await http.post(
            Uri.parse('${Constant.baseurl}$endpoint'),
            body: jsonEncode(data),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
              "ngrok-skip-browser-warning": "true"
            });
        print("${Constant.baseurl}$endpoint");
        print(response.statusCode);
        print(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.pop(context);
          return response;
        }else if(response.statusCode == 401){
          Navigator.pop(context);
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          //var data = ErrorModel.fromJson(jsonDecode(response.body));
          /*if(data.message!.length>0)
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);*/
          print(response.body);
          sharedPreferences.clear();
          CommonWidget.navigateToScreen(context, LoginActivity("Login"));
          return response;
        }

        else {
          Navigator.pop(context);
          var data = ErrorModel.fromJson(jsonDecode(response.body));
          if(data.message!.isNotEmpty) {
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);
          }
          print(response.body);
          return response;
        }
      } else {
        Map<String, dynamic> message = {
          'status_message': "Please Check Network Connection"
        };
        var mes = message['status_message'];
        print(mes);
        showSnackBar(context, "Please Check Network Connection");
        return mes;
      }
    } on SocketException catch (_) {
      Map<String, dynamic> message = {
        'status_message': "Please Check Network Connection"
      };
      var mes = message['status_message'];
      print(mes);
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
    print(context);
    print("=========datainjsonEncode${jsonEncode(data)} ");
    try {

      List<InternetAddress> result = [];
      if(!kIsWeb) {
        result = await InternetAddress.lookup('google.com');
      }
      if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) || kIsWeb) {
        showLoaderDialog(context);
        final response = await http.put(
            Uri.parse('${Constant.baseurl}$endpoint'),
            body: jsonEncode(data),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
              "ngrok-skip-browser-warning": "true"
            });
        print("${Constant.baseurl}$endpoint");
        print(response.statusCode);
        print(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.pop(context);
          return response;
        }else if(response.statusCode == 401){
          Navigator.pop(context);
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          //var data = ErrorModel.fromJson(jsonDecode(response.body));
          /*if(data.message!.length>0)
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);*/
          print(response.body);
          sharedPreferences.clear();
          CommonWidget.navigateToScreen(context, LoginActivity("Login"));
          return response;
        }else {
          Navigator.pop(context);
          var data = ErrorModel.fromJson(jsonDecode(response.body));
          if(data.message!.isNotEmpty) {
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);
          }
          print(response.body);
          return response;
          //Common.showToast(mes);
        }
      } else {
        Map<String, dynamic> message = {
          'status_message': "Please Check Network Connection"
        };
        var mes = message['status_message'];
        print(mes);
        showSnackBar(context, "Please Check Network Connection");
        return mes;
      }
    } on SocketException catch (_) {
      Map<String, dynamic> message = {
        'status_message': "Please Check Network Connection"
      };
      var mes = message['status_message'];
      print(mes);
      showSnackBar(context, "Please Check Network Connection");
      return mes;
    }
  }

  Future<http.Response> sendMultipartRequest(BuildContext context, String url,
      List<File> files, Map<String, dynamic> data,
      {String filekey = "file"}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString(Constant.accessToken)??"";
    FocusManager.instance.primaryFocus?.unfocus();
    showLoaderDialog(context);
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
              print('⚠️ Could not extract file name from path, using fallback: $e');
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
            
            print('📁 Web File: $fileName, Extension: $fileExtension, Size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
          } catch (e) {
            Navigator.pop(context);
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
            Navigator.pop(context);
            CommonWidget.errorShowSnackBarFor(context, 'File has no extension: $fileName');
            throw Exception('File has no extension: $fileName');
          }
          
          print('📁 Mobile File: $fileName, Extension: $fileExtension, Full Path: ${file.path}');
          
          // Check if file exists and get size
          try {
            if (!await file.exists()) {
              Navigator.pop(context);
              CommonWidget.errorShowSnackBarFor(context, 'File not found: $fileName');
              throw Exception('File not found: $fileName');
            }
          } catch (e) {
            Navigator.pop(context);
            CommonWidget.errorShowSnackBarFor(context, 'Error checking file: $e');
            throw Exception('Error checking file: $e');
          }

          try {
            fileSize = await file.length();
          } catch (e) {
            Navigator.pop(context);
            CommonWidget.errorShowSnackBarFor(context, 'Error reading file size: $e');
            throw Exception('Error reading file size: $e');
          }
        }
        
        print('📊 File size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        
        // Validate file size
        if (fileSize > maxFileSize) {
          Navigator.pop(context);
          CommonWidget.errorShowSnackBarFor(context, 'File size exceeds maximum limit (100 MB)');
          throw Exception('File size exceeds maximum limit: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        }

        // Validate file format
        bool isImage = allowedImageExtensions.contains(fileExtension);
        bool isDocument = allowedDocumentExtensions.contains(fileExtension);
        
        print('🔍 Is Image: $isImage, Is Document: $isDocument');
        print('🔍 Allowed Image Extensions: $allowedImageExtensions');
        print('🔍 Allowed Document Extensions: $allowedDocumentExtensions');
        
        if (!isImage && !isDocument) {
          Navigator.pop(context);
          CommonWidget.errorShowSnackBarFor(context, 'Unsupported file format: $fileExtension. Please use images (JPG, PNG) or documents (PDF, DOC, XLS, PPT)');
          throw Exception('Unsupported file format: $fileExtension');
        }

        // Validate size based on file type
        if (isImage && fileSize > maxImageSize) {
          Navigator.pop(context);
          CommonWidget.errorShowSnackBarFor(context, 'Image size exceeds maximum limit (5 MB). Please compress the image.');
          throw Exception('Image size exceeds maximum limit: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        }

        if (isDocument && fileSize > maxDocumentSize) {
          Navigator.pop(context);
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

        print('📄 Content Type: ${contentType?.mimeType ?? "NULL"}');

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
            Navigator.pop(context);
            CommonWidget.errorShowSnackBarFor(context, 'Error reading file: ${e.toString()}');
            throw Exception('Error reading file: $e');
          }
        } else {
          Navigator.pop(context);
          CommonWidget.errorShowSnackBarFor(context, 'Unsupported file format: $fileName');
          throw Exception('Unsupported file format: $fileName');
        }
      }
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      print('Request Body:');
      print('URL: $url');
      print('Headers: ${request.headers}');
      print('Files:');
      for (var file in request.files) {
        print('  - ${file.filename}');
      }
      print('Fields:');
      request.fields.forEach((key, value) {
        print('  $key: $value');
      });

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print('responseBody ${streamedResponse.request}');
      print('responseBody ${response.body}');
      print('responseBody $response');

      // Handle the response
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        print('Success: ${response.body}');
        return response; // Return the response body upon success
      }else if(response.statusCode == 401){
        Navigator.pop(context);
        /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
        //var data = ErrorModel.fromJson(jsonDecode(response.body));
        /*if(data.message!.length>0)
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);*/
        print(response.body);
        sharedPreferences.clear();
        CommonWidget.navigateToScreen(context, LoginActivity("Login"));
        return response;
      }

      else {
        Navigator.pop(context);
        var data = ErrorModel.fromJson(jsonDecode(response.body));
        if(data.message!.isNotEmpty) {
          CommonWidget.errorShowSnackBarFor(context, data.message![0]);
        }
        print(response.body);
        return response;
      }
    } catch (e) {
      Navigator.pop(context);
      print('Error sending files to server: $e');
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
    print(context);
    print("=========datainjsonEncode${jsonEncode(data)} ");
    try {
      List<InternetAddress> result = [];
      if (!kIsWeb) {
        result = await InternetAddress.lookup('google.com');
      }
      if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) || kIsWeb) {
        showLoaderDialog(context);
        final response = await http.patch(
            Uri.parse('${Constant.baseurl}$endpoint'),
            body: jsonEncode(data),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            });
        print("${Constant.baseurl}$endpoint");
        print(response.statusCode);
        print(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.pop(context);
          return response;
          /*Map<String, dynamic> message = (jsonDecode(response.body));
          if (message['status'] == true) {
            print(response);
            return response;
          } else {
            var error = message['message'];
            print(response.body);
            print(error);
            showSnackBar(context,error);
            return error;
          }*/
        } else if(response.statusCode == 401){
          Navigator.pop(context);
          /*CommonWidget.errorShowSnackBarFor(
              context, "${response.statusCode.toString()} Error Code");*/
          //var data = ErrorModel.fromJson(jsonDecode(response.body));
          /*if(data.message!.length>0)
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);*/
          print(response.body);
          sharedPreferences.clear();
          CommonWidget.navigateToScreen(context, LoginActivity("Login"));
          return response;
        } else {
          Navigator.pop(context);
          Map<String, dynamic> message = (jsonDecode(response.body));

          if (message['message'].length > 0) {
            var mes = message['message'][0];
            CommonWidget.errorShowSnackBarFor(context, "$mes Error Code");
          }
          var mes = message['message'];
          print(response.body);
          print(mes);
          showSnackBar(context, mes);
          return response;
          //Common.showToast(mes);
        }
      } else {
        Map<String, dynamic> message = {
          'status_message': "Please Check Network Connection"
        };
        var mes = message['status_message'];
        print(mes);
        showSnackBar(context, "Please Check Network Connection");
        return mes;
      }
    } on SocketException catch (_) {
      Map<String, dynamic> message = {
        'status_message': "Please Check Network Connection"
      };
      var mes = message['status_message'];
      print(mes);
      showSnackBar(context, "Please Check Network Connection");
      return mes;
    }
  }

  static showLoaderDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(
            color: ColorClass.base_color,
          ),
          Container(
              margin: const EdgeInsets.only(left: 7), child: const Text("Loading...")),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
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
