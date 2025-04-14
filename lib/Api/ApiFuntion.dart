import 'dart:convert';
import 'dart:io';

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
    print("${Constant.baseurl}${endpoint}");
    try {
      List<InternetAddress> result = [];
      if(!kIsWeb) {
        result = await InternetAddress.lookup('google.com');
      }
      if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) || kIsWeb) {
        if (cycle == true) showLoaderDialog(context);
        final response = await http
            .get(Uri.parse('${Constant.baseurl}${endpoint}'), headers: {
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
          if(data.message!.length>0)
          CommonWidget.errorShowSnackBarFor(context, data.message![0]);
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
    print("${Constant.baseurl}${endpoint}");
    try {
      List<InternetAddress> result = [];
      if(!kIsWeb) {
        result = await InternetAddress.lookup('google.com');
      }
      if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) || kIsWeb) {
        if (cycle == true) showLoaderDialog(context);
        final response = await http
            .delete(Uri.parse('${Constant.baseurl}${endpoint}'), headers: {
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
          if(data.message!.length>0)
          CommonWidget.errorShowSnackBarFor(context, data.message![0]);
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
            Uri.parse('${Constant.baseurl}${endpoint}'),
            body: jsonEncode(data),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            });
        print("${Constant.baseurl}${endpoint}");
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
          if(data.message!.length>0)
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);
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
            Uri.parse('${Constant.baseurl}${endpoint}'),
            body: jsonEncode(data),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            });
        print("${Constant.baseurl}${endpoint}");
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
          if(data.message!.length>0)
            CommonWidget.errorShowSnackBarFor(context, data.message![0]);
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
        Uri.parse('${Constant.baseurl}${url}'),
      );
      request.headers.addAll({
    "Content-Type": "application/json",
    "Authorization": "Bearer $token"
    });
      // Add files to the request
      for (var file in files) {
        var fileName = file.path.split('/').last;

        var contentType;
        if (fileName.endsWith('.pdf') || fileName.endsWith('.PDF')) {
          contentType = MediaType('application', 'pdf');
        } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
          contentType = MediaType('application', 'msword');
        } else if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
          contentType = MediaType('application', 'vnd.ms-excel');
        } else if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) {
          contentType = MediaType('application', 'vnd.ms-powerpoint');
        } else if (fileName.endsWith('.jpg') ||
            fileName.endsWith('.jpeg') ||
            fileName.endsWith('.png') ||
            fileName.endsWith('.JPG') ||
            fileName.endsWith('.JPEG') ||
            fileName.endsWith('.PNG')) {
          contentType = MediaType('image', 'jpeg');
        }

        if (contentType != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              filekey,
              file.path,
              filename: fileName,
              contentType: contentType,
            ),
          );
        } else {
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
      print('responseBody ${response}');

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
        if(data.message!.length>0)
          CommonWidget.errorShowSnackBarFor(context, data.message![0]);
        print(response.body);
        return response;
      }
    } catch (e) {
      Navigator.pop(context);
      print('Error sending files to server: $e');
      throw Exception('Failed to upload files');
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
            Uri.parse('${Constant.baseurl}${endpoint}'),
            body: jsonEncode(data),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            });
        print("${Constant.baseurl}${endpoint}");
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
            CommonWidget.errorShowSnackBarFor(context, "${mes} Error Code");
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
              margin: EdgeInsets.only(left: 7), child: Text("Loading...")),
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
          style: TextStyle(
              color: Colors.red, fontWeight: FontWeight.w500, fontSize: 16),
        )));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  logout(BuildContext context, SharedPreferences sharedPreferences) async {

  }
}
