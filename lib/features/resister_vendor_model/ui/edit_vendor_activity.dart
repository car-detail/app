import 'dart:convert';
import 'dart:io';

import 'package:car_app/Common/CommonPopUp.dart';
import 'package:car_app/features/resister_vendor_model/model/edit_vendor_bean.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/BaseActivity.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../../../Models/image_module_data.dart';
import '../datamanager/add_shop_data_manager.dart';
import '../model/capture_vendor_bean.dart';
class EditVendorActivity extends StatefulWidget {
  const EditVendorActivity({super.key});

  @override
  State<EditVendorActivity> createState() => _EditVendorActivityState();
}

class _EditVendorActivityState extends State<EditVendorActivity> {
  var shopNameController = TextEditingController();
  var mobileController = TextEditingController();
  var emailController = TextEditingController();
  var openController = TextEditingController();
  var closeController = TextEditingController();
  var profileController = TextEditingController();
  List<File> selectedFiles = [];
  String imageURl = "";
  String networkImage = "";

  ApiFuntions apiFuntions = ApiFuntions();
  AddShopDataManager? dataManager;
  late SharedPreferences? sharedPreferences;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = AddShopDataManager(sharedPreferences!);
    getEditVendorDetails();
  }

  captureVendor(BuildContext context) async {
    var response = await dataManager!.editCaptureVendor(
        shopNameController.text,
        emailController.text,
        mobileController.text,
        imageURl,
        openController.text,
        closeController.text,
        context);
    var data = CaptureVendorBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      sharedPreferences!
          .setString(Constant.vendorId, data.data?.newBusinessData?.sId ?? "");
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      Navigator.pop(context, true);
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  postImage(BuildContext context) async {
    List<File> image = [selectedFiles[0]];
    var response = await dataManager!.postImage(image, context);
    var data = ImageModuleData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      imageURl = data.data?.url ?? "";
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/login_image.png'),
              fit: BoxFit.cover)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 45, left: 15),
              child: InkWell(
                onTap: (){
                  Navigator.pop(context, true);
                },
                child: Image.asset(
                  CommonWidget.getImagePath("backspace.png"),
                  height: 40,
                  width: 40,
                ),
              ),
            ),
            Expanded(child: Container(
              margin: Platform.isIOS
                  ? EdgeInsets.only(top: 245,)
                  : EdgeInsets.only(
                  top: 165,),
              child: Column(
                children: [
                  //Image(image: AssetImage('assets/images/login_image.png')),
                  Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: 20, right: 20, bottom: 30),
                        child: SingleChildScrollView(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CommonWidget.getTextWidgetTitle("Add Shop Details",
                                    color: ColorClass.base_color, textsize: 20),
                                CommonWidget.getTextWidgetSubTitle(
                                    "Please add the shop details for user better experience.",
                                    color: ColorClass.middel_gray_base,
                                    textsize: 14),
                                SizedBox(height: 10,),
                                Container(
                                  alignment: Alignment.center,
                                  child: Stack(
                                    children: [
                                      if (selectedFiles.length == 0 && networkImage == "")
                                        ClipOval(
                                          child: Image.asset(
                                            CommonWidget.getImagePath(
                                                "chat_profile.png"),
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                      if (selectedFiles.length > 0)
                                        ClipOval(
                                          child: CommonWidget.determineImageAsset(
                                              selectedFiles[0].path ?? ""),
                                        ),
                                      if(selectedFiles.length == 0 && networkImage != "")
                                        ClipOval(
                                          child: CommonWidget.determineImageInternetNew(
                                              networkImage),
                                        ),
                                      Positioned(
                                        bottom: 5,
                                        right: 0,
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: GestureDetector(
                                              child: Image.asset(
                                                  CommonWidget.getImagePath(
                                                      "add_image_icon.png")),
                                              // Icon color and size
                                              onTap: () async {
                                                var data =
                                                await BaseActivity.pickmedia(false);
                                                if (data != null) {
                                                  setState(() {
                                                    if (data != null) {
                                                      selectedFiles.clear();
                                                      for (int i = 0;
                                                      i < data.length;
                                                      i++) {
                                                        setState(() {
                                                          selectedFiles.add(data[i]);
                                                        });
                                                      }
                                                    }
                                                  });
                                                }
                                                print(selectedFiles.length);
                                                postImage(context);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CommonWidget.getTextFieldWithgrayboder(
                                    "Enter Shop Name", shopNameController),
                                CommonWidget.getTextFieldWithgrayboder(
                                    "Enter Email Address", emailController, keyboardType: TextInputType.emailAddress),
                                CommonWidget.getTextFieldWithgrayboder(
                                    "Enter Mobile Number", mobileController, keyboardType: TextInputType.number),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CommonWidget
                                          .getTextFieldWithgrayboderandclickable(
                                          "Open Time", openController, () {
                                        CommonPopUp.showTimeDialog(context, (time) {
                                          openController.text =
                                              time.format(context).toString();
                                        });
                                      }, "clock"),
                                    ),
                                    SizedBox(width: 10,),
                                    Expanded(
                                      child: CommonWidget
                                          .getTextFieldWithgrayboderandclickable(
                                          "Open Time", closeController, () {
                                        CommonPopUp.showTimeDialog(context, (time) {
                                          closeController.text =
                                              time.format(context).toString();
                                        });
                                      }, "clock"),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                GestureDetector(
                                    onTap: () {
                                      //FocusManager.instance.primaryFocus?.unfocus();
                                      if (BaseActivity.checkEmptyField(
                                          editingController: shopNameController,
                                          message: "Please Enter Shop Name.",
                                          context: context)) {
                                        return;
                                      } else if (BaseActivity.checkEmptyField(
                                          editingController: emailController,
                                          message: "Please Enter Email Address.",
                                          context: context)) {
                                        return;
                                      } else if (BaseActivity.checkEmptyField(
                                          editingController: mobileController,
                                          message: "Please Enter Mobile.",
                                          context: context)) {
                                        return;
                                      }else if (BaseActivity.checkEmptyField(
                                          editingController: openController,
                                          message: "Please Select Shop Open Time.",
                                          context: context)) {
                                        return;
                                      }else if (BaseActivity.checkEmptyField(
                                          editingController: openController,
                                          message: "Please Select Shop Close Time.",
                                          context: context)) {
                                        return;
                                      } else if (imageURl == "") {
                                        CommonWidget.successShowSnackBarFor(
                                            context, "Please Select Profile Image");
                                        return;
                                      } else {
                                        captureVendor(context);
                                      }
                                    },
                                    child: Container(
                                      child: CommonWidget.getGradinetButton("Submit",
                                          startcolor: 0xff1CA669,
                                          endcolor: 0xff1CA669,
                                          height: 40),
                                    )),
                              ]),
                        ),
                      ))
                ],
              ),
            ),)
          ],
        )
        
        
        
      ),
    );
  }

  getEditVendorDetails()async{
    var response = await dataManager!.getVendorDetails(context);
    var data = EditVendorBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      shopNameController.text = data.data![0].displayName??"";
      emailController.text = data.data![0].officialEmail??"";
      mobileController.text = data.data![0].mobile??"";
      openController.text = CommonWidget.convertToLocalTimeWithAMPM(data.data![0].openTime??"");
      closeController.text = CommonWidget.convertToLocalTimeWithAMPM(data.data![0].closeTime??"");
      setState(() {
        networkImage = data.data![0].displayPicture??"";
        imageURl = data.data![0].displayPicture??"";
      });
      //CommonWidget.navigateToScreen(context, OTPScreenActivity());
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

}
