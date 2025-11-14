import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:car_app/Common/CommonPopUp.dart';
import 'package:car_app/features/resister_vendor_model/model/edit_vendor_bean.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_places_autocomplete_widgets/widgets/address_autocomplete_textfield.dart';
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
  var addressController = TextEditingController();
  double long = 0.0;
  double late = 0.0;
  List<File> selectedFiles = [];
  String imageURl = "";
  String networkImage = "";
  final List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  List<bool> isChecked = List.generate(7, (_) => false);

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
    List<String> weekdaysSeleted = [];
    for(int i= 0; i<isChecked.length ;i++){
      if(isChecked[i] == true){
        weekdaysSeleted.add(weekdays[i]);
      }
    }
    var response = await dataManager!.editCaptureVendor(
        shopNameController.text,
        emailController.text,
        mobileController.text,
        imageURl,
        openController.text,
        closeController.text,
        weekdaysSeleted,
        long,
        late,
        addressController.text,
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
              margin: const EdgeInsets.only(top: 45, left: 15),
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
              margin: kIsWeb
                  ? const EdgeInsets.only(top: 245,)
                  : const EdgeInsets.only(
                  top: 245,),
              child: Column(
                children: [
                  //Image(image: AssetImage('assets/images/login_image.png')),
                  Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
                        child: SingleChildScrollView(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CommonWidget.getTextWidgetTitle("Edit Shop Details",
                                    color: ColorClass.base_color, textsize: 20),
                                CommonWidget.getTextWidgetSubTitle(
                                    "Please add the shop details for user better experience.",
                                    color: ColorClass.middel_gray_base,
                                    textsize: 14),
                                const SizedBox(height: 10,),
                                Container(
                                  alignment: Alignment.center,
                                  child: Stack(
                                    children: [
                                      if (selectedFiles.isEmpty && networkImage == "")
                                        ClipOval(
                                          child: Image.asset(
                                            CommonWidget.getImagePath(
                                                "chat_profile.png"),
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                      if (selectedFiles.isNotEmpty)
                                        ClipOval(
                                          child: CommonWidget.determineImageAsset(
                                              selectedFiles[0].path ?? ""),
                                        ),
                                      if(selectedFiles.isEmpty && networkImage != "")
                                        ClipOval(
                                          child: CommonWidget.determineImageInternetNew(
                                              networkImage),
                                        ),
                                      Positioned(
                                        bottom: 5,
                                        right: 0,
                                        child: SizedBox(
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
                                                    selectedFiles.clear();
                                                    for (int i = 0;
                                                    i < data.length;
                                                    i++) {
                                                      setState(() {
                                                        selectedFiles.add(data[i]);
                                                      });
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
                                SizedBox(
                                  height: 40,
                                  child: AddressAutocompleteTextField(
                                      decoration: InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius: const BorderRadius.all(Radius.circular(20)),
                                              borderSide: BorderSide(
                                                  color: ColorClass.base_color,
                                                  width: 1,
                                                  style: BorderStyle.solid)),
                                          enabledBorder: OutlineInputBorder(
                                              borderRadius: const BorderRadius.all(Radius.circular(20)),
                                              borderSide: BorderSide(
                                                  color: ColorClass.middel_gray_base,
                                                  width: 1,
                                                  style: BorderStyle.solid)),
                                          contentPadding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                                          filled: true,
                                          fillColor: ColorClass.base_light_color,
                                          hintText: "Enter Address",
                                          hintStyle: TextStyle(
                                              color: Colors.grey[800],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w300),
                                          border: OutlineInputBorder(
                                              borderRadius: const BorderRadius.all(Radius.circular(20)),
                                              borderSide: BorderSide(color: ColorClass.light_browne))),
                                      mapsApiKey: 'AIzaSyBFtrosISezP-8z2NwTWKhD_5pNHoi0wRw',
                                      controller: addressController,
                                      onSuggestionClick: (place){
                                        addressController.text  = "";
                                        addressController.text = place.name??"";
                                        long = place.lng??0.0;
                                        late = place.lat??0.0;
                                      },
                                      language: 'en-US'
                                  ),
                                ),
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
                                    const SizedBox(width: 10,),
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
                                const SizedBox(
                                  height: 20,
                                ),
                                SizedBox(
                                    width: double.infinity,
                                    child: CommonWidget.getTextWidget500("Select Days",textAlign: TextAlign.left)),
                                const SizedBox(height: 10,),
                                SizedBox(
                                  height: 140,
                                  child: GridView.count(
                                    padding: EdgeInsets.zero,
                                    crossAxisCount: 3, // 2 columns, change to 3 if you prefer
                                    childAspectRatio: 3, // Wider cells
                                    children: List.generate(weekdays.length, (index) {
                                      return Card(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: isChecked[index],
                                              activeColor: ColorClass.base_color,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isChecked[index] = value ?? false;
                                                });
                                              },
                                            ),
                                            Text(weekdays[index]),
                                          ],
                                        ),
                                      );
                                    }),),
                                ),
                                const SizedBox(height: 10,),
                                GestureDetector(
                                    onTap: () {
                                      //FocusManager.instance.primaryFocus?.unfocus();
                                      if (BaseActivity.checkEmptyField(
                                          editingController: shopNameController,
                                          message: "Please Enter Shop Name.",
                                          context: context)) {
                                        return;
                                      } /*else if (BaseActivity.checkEmptyField(
                                          editingController: emailController,
                                          message: "Please Enter Email Address.",
                                          context: context)) {
                                        return;
                                      }*/ else if (BaseActivity.checkEmptyField(
                                          editingController: mobileController,
                                          message: "Please Enter Mobile.",
                                          context: context)) {
                                        return;
                                      }else if (BaseActivity.checkEmptyField(
                                          editingController: addressController,
                                          message: "Please Enter Address.",
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
                                      } /*else if (imageURl == "") {
                                        CommonWidget.successShowSnackBarFor(
                                            context, "Please Select Profile Image");
                                        return;
                                      }*/ else {
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
        addressController.text = data.data![0].location!.name??"";
        long = data.data![0].location!.coordinates!.long??0.0;
        late = data.data![0].location!.coordinates!.lat??0.0;
        networkImage = data.data![0].displayPicture??"";
        imageURl = data.data![0].displayPicture??"";
        for(int i = 0; i<weekdays.length; i++){
          if(data.data![0].daysAvailable.contains(weekdays[i])){
            isChecked[i] = true;
          }
        }
      });
      //CommonWidget.navigateToScreen(context, OTPScreenActivity());
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

}
