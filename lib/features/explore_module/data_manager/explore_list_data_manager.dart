import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class ExploreListDataManager {

  SharedPreferences sharedPreferences;
  ExploreListDataManager(this.sharedPreferences);
  ApiFuntions apiFuntions = ApiFuntions();

  getAllServices(BuildContext context) {
    return apiFuntions.getdatauser(context, "${Constant.getAllService}pageNumber=1&count=20&sortBy=createdAt");
  }


}