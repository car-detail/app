import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class ForgotPasswordDataManager{
  SharedPreferences sharedPreferences;
  ForgotPasswordDataManager(this.sharedPreferences);
  ApiFuntions apiFuntions = ApiFuntions();

  ForgotPasswordAPP(BuildContext context, String Schoolcode, String username){
    return apiFuntions.postdatauser(context, "FOrgot", {
      "SchoolCode": Schoolcode,
      "UserName": username,
    });
  }

}