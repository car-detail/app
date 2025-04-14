import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class ProfileListDataManager{
  SharedPreferences sharedPreferences;

  ProfileListDataManager(this.sharedPreferences);
  ApiFuntions apiFuntions = ApiFuntions();

  getUserDetails(BuildContext context) {
    return apiFuntions.getdatauser(context, Constant.getUserDetails);
  }

}