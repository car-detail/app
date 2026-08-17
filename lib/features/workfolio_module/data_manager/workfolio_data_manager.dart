import 'dart:io';

import 'package:car_app/Common/Constant.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';

class WorkfolioDataManager {
  SharedPreferences sharedPreferences;

  WorkfolioDataManager(this.sharedPreferences);

  ApiFuntions apiFuntions = ApiFuntions();

  Future<http.Response> getFeed(BuildContext context, {int page = 1, int limit = 20, String? vendorId, String? userId}) {
    String url = "${Constant.workfolioFeed}page=$page&limit=$limit";
    if (vendorId != null && vendorId.isNotEmpty) url += "&vendorId=$vendorId";
    if (userId != null && userId.isNotEmpty) url += "&userId=$userId";
    return apiFuntions.getdatauser(context, url);
  }

  Future<http.Response> uploadImage(BuildContext context, File file) {
    return apiFuntions.sendMultipartRequest(context, Constant.uploadFile, [file], <String, dynamic>{});
  }

  /// Creates a post. Vendor posts are auto-tagged with their own business
  /// (Constant.vendorId in prefs) unless a different vendorId is passed.
  Future<http.Response> createPost(BuildContext context, {required String imageUrl, String? caption, String? vendorId}) {
    final effectiveVendorId = vendorId ?? sharedPreferences.getString(Constant.vendorId);
    final body = <String, dynamic>{"image": imageUrl};
    if (caption != null && caption.isNotEmpty) body["caption"] = caption;
    if (effectiveVendorId != null && effectiveVendorId.isNotEmpty) body["vendor"] = effectiveVendorId;
    return apiFuntions.postdatauser(context, Constant.workfolioCreate, body);
  }

  Future<http.Response> toggleLike(BuildContext context, String postId) {
    return apiFuntions.postdatauser(context, "${Constant.workfolioLike}$postId", <String, dynamic>{});
  }

  Future<http.Response> deletePost(BuildContext context, String postId) {
    return apiFuntions.deletedatauser(context, "${Constant.workfolioDelete}$postId");
  }
}
