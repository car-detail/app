import 'dart:convert';
import 'dart:io';

import 'package:car_app/Common/CommonPopUp.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/features/services_model/data_manager/services_data_manager.dart';
import 'package:car_app/features/services_model/model/add_services_bean.dart';
import 'package:car_app/features/services_model/ui/services_list_activity.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/BaseActivity.dart';
import '../../../Common/Color.dart';
import '../../../Models/check_dialog_box.dart';
import '../../../Models/image_module_data.dart';
import '../../home_module/model/category_model_data.dart';
import '../../search_pop_up/search_dialog_with_single_select.dart';

class AddServicesActivity extends StatefulWidget {
  const AddServicesActivity({super.key});

  @override
  State<AddServicesActivity> createState() => _AddServicesActivityState();
}

class _AddServicesActivityState extends State<AddServicesActivity> {
  var titleController = TextEditingController();
  var aboutController = TextEditingController();
  var timeSlotController = TextEditingController();
  var priceController = TextEditingController();
  var durationController = TextEditingController();
  var categoryController = TextEditingController();
  var mobileController = TextEditingController();
  List<File> selectedFiles = [];
  List<File> selectedDetailsFiles = [];
  String categoryId = "";

  ApiFuntions apiFuntions = ApiFuntions();
  ServicesDataManager? servicesDataManager;
  SharedPreferences? sharedPreferences;
  String coverImage = "";
  List<String> detailsImage = [];
  List<CategoryData> categoryData = [];

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
    servicesDataManager = ServicesDataManager(sharedPreferences!);
    aboutController.text = "Best Car washing center";
    getCategory(context);
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
              Expanded(
                child: Container(
                  margin: Platform.isIOS
                      ? EdgeInsets.only(top: 245, left: 15, right: 15, bottom: 30)
                      : EdgeInsets.only(
                          top: 165, left: 15, right: 15, bottom: 30),
                  child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonWidget.getTextWidgetTitle("Add Services",
                              textsize: 22, color: ColorClass.base_color),
                          CommonWidget.getTextWidgetSubTitle(
                              "Please add the services for user better experience.",
                              textsize: 12,
                              color: ColorClass.middel_gray_base),
                          SizedBox(
                            height: 10,
                          ),
                          CommonWidget.getTextFieldWithgrayboder(
                              "Enter Service Cost", priceController,
                              keyboardType: TextInputType.number),

                          CommonWidget.getTextFieldWithgrayboder(
                              "Enter Mobile Number", mobileController, keyboardType: TextInputType.number),
                          CommonWidget.getTextFieldWithgrayboderandclickable(
                              "Enter Service Duration", durationController,(){showTimeRequierd();}, "dropdown"),
                          // Container(
                          //     margin: EdgeInsets.only(left: 10, right: 10),
                          //     child: CommonWidget.getTextWidget300(
                          //         "*Provide the duration in minute to complete one services(ex:-30).",
                          //         12,
                          //         textAlign: TextAlign.start)),
                          CommonWidget.getTextFieldWithgrayboderandclickable(
                              "Enter Services Capacity", timeSlotController,(){showCapacity();}, "dropdown"),
                          Container(
                              margin: EdgeInsets.only(left: 10, right: 10),
                              child: CommonWidget.getTextWidget300(
                                  "*Enter number of services complete in one hour.",
                                  12,
                                  textAlign: TextAlign.start)),
                          CommonWidget.getTextFieldWithgrayboder(
                              "Write about services..", aboutController,
                              maxline: 6, height: 120),
                          CommonWidget.getTextWidgetSubTitle("Add Cover Image",
                              textsize: 16),
                          GestureDetector(
                            onTap: () async {
                              //var data = await BaseActivity.pickmultipleFile();
                              BaseActivity.showFilePicker(context,
                                      (List<File>? list) {
                                    var data = list;
                                    if (data != null) {
                                      setState(() {
                                        if (data != null) {
                                          for (int i = 0; i < data.length; i++) {
                                            setState(() {
                                              if (selectedFiles.length < 1)
                                                selectedFiles.add(data[i]);
                                            });
                                            if (selectedFiles.length == 1 &&
                                                i < data.length - 1) {
                                              CommonWidget.errorShowSnackBarFor(
                                                  context,
                                                  "You can't add more then 1 Cover image.");
                                              break;
                                            }
                                          }
                                        }
                                      });
                                    }
                                    print(selectedFiles.length);
                                  });
                            },
                            child: Container(
                              color: ColorClass.base_color,
                              width: 170,
                              margin: EdgeInsets.only(top: 10),
                              padding: EdgeInsets.fromLTRB(10, 7, 10, 7),
                              child: Row(
                                children: [
                                  Image.asset(
                                    CommonWidget.getImagePath("upload.png"),
                                    height: 30,
                                  ),
                                  Container(
                                      margin: EdgeInsets.only(left: 5),
                                      child: CommonWidget.getTextWidgetPopbold(
                                          "Upload Image",
                                          color: Colors.white))
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          if (selectedFiles.length > 0)
                            Container(
                              height: 100,
                              child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: selectedFiles.length,
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: EdgeInsets.only(top: 10, left: 10),
                                      child: Stack(
                                        children: [
                                          Container(
                                              width: 80,
                                              margin: EdgeInsets.only(
                                                  top: 10, left: 10),
                                              child: CommonWidget
                                                  .determineImageAsset(
                                                  selectedFiles[index].path)),
                                          Align(
                                              alignment: Alignment.topRight,
                                              child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedFiles
                                                          .removeAt(index);
                                                    });
                                                  },
                                                  child: Image.asset(
                                                    CommonWidget.getImagePath(
                                                        "delete.png"),
                                                    height: 25,
                                                    width: 25,
                                                  )))
                                        ],
                                      ),
                                    );
                                  }),
                            ),
                          CommonWidget.getTextWidgetSubTitle("Add Details Image",
                              textsize: 16),
                          GestureDetector(
                            onTap: () async {
                              //var data = await BaseActivity.pickmultipleFile();
                              BaseActivity.showFilePicker(context,
                                      (List<File>? list) {
                                    var data = list;
                                    if (data != null) {
                                      setState(() {
                                        if (data != null) {
                                          for (int i = 0; i < data.length; i++) {
                                            setState(() {
                                              if (selectedDetailsFiles.length < 5)
                                                selectedDetailsFiles.add(data[i]);
                                            });
                                            if (selectedDetailsFiles.length == 5 &&
                                                i < data.length - 1) {
                                              CommonWidget.errorShowSnackBarFor(
                                                  context,
                                                  "You can't add more then 5 Details image.");
                                              break;
                                            }
                                          }
                                        }
                                      });
                                    }
                                    print(selectedDetailsFiles.length);
                                  });
                            },
                            child: Container(
                              color: ColorClass.base_color,
                              width: 170,
                              margin: EdgeInsets.only(top: 10),
                              padding: EdgeInsets.fromLTRB(10, 7, 10, 7),
                              child: Row(
                                children: [
                                  Image.asset(
                                    CommonWidget.getImagePath("upload.png"),
                                    height: 30,
                                  ),
                                  Container(
                                      margin: EdgeInsets.only(left: 5),
                                      child: CommonWidget.getTextWidgetPopbold(
                                          "Upload Image",
                                          color: Colors.white))
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          if (selectedDetailsFiles.length > 0)
                            Container(
                              height: 100,
                              child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: selectedDetailsFiles.length,
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: EdgeInsets.only(top: 10, left: 10),
                                      child: Stack(
                                        children: [
                                          Container(
                                              width: 80,
                                              margin: EdgeInsets.only(
                                                  top: 10, left: 10),
                                              child: CommonWidget
                                                  .determineImageAsset(
                                                  selectedDetailsFiles[index]
                                                      .path)),
                                          Align(
                                              alignment: Alignment.topRight,
                                              child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedDetailsFiles
                                                          .removeAt(index);
                                                    });
                                                  },
                                                  child: Image.asset(
                                                    CommonWidget.getImagePath(
                                                        "delete.png"),
                                                    height: 25,
                                                    width: 25,
                                                  )))
                                        ],
                                      ),
                                    );
                                  }),
                            ),
                          SizedBox(
                            height: 20,
                          ),
                          GestureDetector(
                              onTap: () async {
                                //FocusManager.instance.primaryFocus?.unfocus();
                                 if (BaseActivity.checkEmptyField(
                                    editingController: mobileController,
                                    message: "Please Enter Mobile.",
                                    context: context)) {
                                  return;
                                } /*else if (imageURl == "") {
                                          CommonWidget.successShowSnackBarFor(
                                              context, "Please Select Profile Image");
                                          return;
                                        }*/
                                /*else if (BaseActivity.checkEmptyField(
                                            editingController: categoryController,
                                            message: "Please select category.",
                                            context: context))
                                          return;*/
                                else if (BaseActivity.checkEmptyField(
                                    editingController: priceController,
                                    message: "Please enter service cost.",
                                    context: context))
                                  return;
                                else if (BaseActivity.checkEmptyField(
                                    editingController: durationController,
                                    message: "Please enter service duration.",
                                    context: context))
                                  return;
                                else if (BaseActivity.checkEmptyField(
                                    editingController: timeSlotController,
                                    message: "Please enter service capacity.",
                                    context: context))
                                  return;
                                else if (BaseActivity.checkEmptyField(
                                    editingController: aboutController,
                                    message: "Please enter about your service.",
                                    context: context))
                                  return;
                                /* else if (selectedFiles.length < 1) {
                                          CommonWidget.errorShowSnackBarFor(
                                              context, "Please select cover image");
                                          return;
                                        } else if (selectedDetailsFiles.length < 3) {
                                          CommonWidget.errorShowSnackBarFor(context,
                                              "Please select atleast 3 detail image");
                                          return;
                                        }*/ else {
                                  List<String> imageList = [];
                                  if(selectedFiles.length>0)
                                    await postImage(context);
                                  for (var i = 0;
                                  i < selectedDetailsFiles.length;
                                  i++) {
                                    imageList.add(await postMultiImage(
                                        context, [selectedDetailsFiles[i]]));
                                  }
                                  postServices(imageList);
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
                ),
              ),
            ],
          )),
    );
  }
  showCapacity() {
    List<CheckDialogBox> typeList = [];
    List<String> time = ["1", "2", "3", "4", "5","6", "10", "10-15", "15-20", "More then 25"];
    for (var i in time) {
      CheckDialogBox data =
      CheckDialogBox(i, i);
      typeList.add(data);
    }
    showDialog(
        context: context,
        builder: (context) {
          return SearchDialogWithSingleSelect(typeList, "Select Capacity",
                  (String id, String name) {
                setState(() {
                  timeSlotController.text = name;
                });
              });
        });
  }
  showTimeRequierd() {
    List<CheckDialogBox> typeList = [];
    List<String> time = ["0.5hr - 1hr","1hr - 2hr", "2hr - 3hr", "3hr - 4hr", "4hr - 5hr", "More then 5hr."];
    for (var i in time) {
      CheckDialogBox data =
      CheckDialogBox(i, i);
      typeList.add(data);
    }
    showDialog(
        context: context,
        builder: (context) {
          return SearchDialogWithSingleSelect(typeList, "Select Service Durations",
                  (String id, String name) {
                setState(() {
                  durationController.text = name;
                });
              });
        });
  }
  getCategory(BuildContext context) async {
    var response = await servicesDataManager!.getcategory(context);
    var data = CategoryModelData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        categoryData.clear();
        categoryData.addAll(data.data!);
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  postImage(BuildContext context) async {
    List<File> image = [selectedFiles[0]];
    var response = await servicesDataManager!.postImage(image, context);
    var data = ImageModuleData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      coverImage = data.data?.url ?? "";
      //CommonWidget.successShowSnackBarFor(context, data.message??"");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  Future<String> postMultiImage(BuildContext context, List<File> image) async {
    var response = await servicesDataManager!.postImage(image, context);
    var data = ImageModuleData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      return data.data?.url ?? "";
      //CommonWidget.successShowSnackBarFor(context, data.message??"");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      return "";
    }
  }

  void postServices(List<String> imageList) async {
    var response = await servicesDataManager?.postServies(
        context,
        titleController.text,
        aboutController.text,
        timeSlotController.text,
        priceController.text,
        durationController.text,
        categoryController.text,
        categoryId,
        imageList,
        coverImage,
        mobileController.text);
    var data = AddServicesBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      Navigator.pop(context,true);
      //CommonWidget.navigateToKillScreen(context, ServicesListActivity());
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  showCatDialog() {
    List<CheckDialogBox> typeList = [];
    for (var i in categoryData) {
      CheckDialogBox data =
          CheckDialogBox(i.categoryTitle ?? "", i.sId.toString());
      typeList.add(data);
    }
    showDialog(
        context: context,
        builder: (context) {
          return SearchDialogWithSingleSelect(typeList, "Select Category",
              (String id, String name) {
            setState(() {
              categoryController.text = name;
              categoryId = id;
            });
          });
        });
  }
}
