import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class ProfileListDataManager {
  SharedPreferences sharedPreferences;

  ProfileListDataManager(this.sharedPreferences);

  ApiFuntions apiFuntions = ApiFuntions();

  getUserDetails(BuildContext context) {
    return apiFuntions.getdatauser(context, Constant.getUserDetails);
  }

  deleteAccount(BuildContext context) {
    return apiFuntions.deletedatauser(context,
        "${Constant.deleteUserApiUrl}${sharedPreferences.getString(Constant.id)}");
  }
}
