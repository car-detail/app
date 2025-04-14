import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Common/BaseActivity.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonBean.dart';
import '../../../Common/CommonPopUp.dart';
import '../../../Common/CommonWidget.dart';
import '../data_manager/forgot_password_manager.dart';

class ForgotPasswordActivity extends StatefulWidget {
  const ForgotPasswordActivity({super.key});

  @override
  State<ForgotPasswordActivity> createState() => _ForgotPasswordActivityState();
}

class _ForgotPasswordActivityState extends State<ForgotPasswordActivity> {
  var schoolController = TextEditingController();
  var userController = TextEditingController();
  SharedPreferences? sharedPreferences;
  ForgotPasswordDataManager? forgotPasswordDataManager;

  @override
  void initState() {
    start();
    super.initState();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    forgotPasswordDataManager =
        ForgotPasswordDataManager(sharedPreferences!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffECF2FB),
      body: Column(
        children: [
          CommonWidget.gettopbarwithmenuicon(context, "Forgot Password",
              isHome: false),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: 15, left: 20, right: 20),
              width: double.infinity,
              child: Image.asset('assets/images/forgot-img.png', height: 200,width: 200,),
            ),
          ),
          Expanded(
              child: Container(
                padding: EdgeInsets.fromLTRB(15, 30, 15, 15),
                decoration: BoxDecoration(
                    borderRadius:
                    BorderRadius.only(topLeft: Radius.circular(60)),
                    color: Colors.white),
            child: SingleChildScrollView (
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    child: CommonWidget.getTextWidgetPopReg(
                        "Enter your schoolcode and user name",
                        textsize: 12,
                        textAlign: TextAlign.center),
                  ),
                  Container(
                    width: double.infinity,
                    child: CommonWidget.getTextWidgetPopReg(
                        "As we are sending OTP to your registered mobile no.",
                        textsize: 12,
                        textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  CommonWidget.getMendatroyTextRich(
                    "School Code",
                  ),
                  CommonWidget.getTextFieldWithgrayboder(
                      "Enter School Code", schoolController),
                  CommonWidget.getMendatroyTextRich("User Name"),
                  CommonWidget.getTextFieldWithgrayboder(
                      "Enter User Name", userController),
                  SizedBox(height: 15,),
                  GestureDetector(
                    onTap: (){
                      if (BaseActivity.checkEmptyField(
                          editingController: schoolController,
                          message: "Please enter school code.",
                          context: context))
                        return;
                      else if (BaseActivity.checkEmptyField(
                          editingController: userController,
                          message: "Please enter username.",
                          context: context))
                        return;
              
                      ForgotPasswordAPP();
                    },
                      child: CommonWidget.getGradinetButton("Reset Password"),
                  ),
                ],
              ),
            ),
          ))
        ],
      ),
    );
  }

  ForgotPasswordAPP() async {
    var responce = await forgotPasswordDataManager!.ForgotPasswordAPP(context, schoolController.text, userController.text);
    var data = CommonBean.fromJson(jsonDecode(responce.body));
    if (data.status == "OK") {
      CommonPopUp.showalertDialog(
          context,
          "Alert!",
          data.message ?? "",
          isnevbuttom: false,
          "Ok",
          "",
          "", () {
        Navigator.pop(context);
      }, () => Navigator.pop(context), 180,
          positivetitlecolorButton: ColorClass.green,
          navtextColorButton: ColorClass.red);
    } else {
     // CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      CommonPopUp.showalertDialog(
          context,
          "Alert!",
          data.message ?? "",
          isnevbuttom: false,
          "Ok",
          "",
          "", () {
        Navigator.pop(context);
      }, () => Navigator.pop(context), 200,
          positivetitlecolorButton: ColorClass.green,
          navtextColorButton: ColorClass.red);
    }
  }

}
