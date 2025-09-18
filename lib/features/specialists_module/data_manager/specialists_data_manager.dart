import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class SpecialistsDataManager{
  SharedPreferences sharedPreferences;
  SpecialistsDataManager(this.sharedPreferences);
  ApiFuntions apiFuntions = ApiFuntions();

  getServiceDetails(BuildContext context, String id) {
    return apiFuntions.getdatauser(context, "${Constant.serviceDetails}$id");
  }
}