import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonBean.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/features/offer_model/data_manager/offer_data_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/BaseActivity.dart';
import '../../../Common/CommonPopUp.dart';
import '../../../Common/Constant.dart';
import '../../../Models/check_dialog_box.dart';
import '../../../Models/image_module_data.dart';
import '../../search_pop_up/search_dialog_with_single_select.dart';
import '../../services_model/model/services_list_bean.dart';

class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  var titleController = TextEditingController();
  var descriptionController = TextEditingController();
  var discountController = TextEditingController();
  var isActiveController = TextEditingController();
  var validFromController = TextEditingController();
  var validUntilController = TextEditingController();
  String fromDate = "";
  String toDate = "";
  List<File> selectedFiles = [];
  ApiFuntions apiFuntions = ApiFuntions();
  OfferDataManager? offerDataManager;
  SharedPreferences? sharedPreferences;
  String coverImage = "";
  var venderId = "";
  List<ServicesListData> servicesData = [];
  var serviceController = TextEditingController();
  var serviceId = "";

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
    offerDataManager = OfferDataManager(sharedPreferences!);
    setState(() {
      venderId = sharedPreferences!.getString(Constant.vendorId) ?? "";
    });
    if (venderId != "") getCategory(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: Column(
        children: [
          Stack(
            children: [
              Image(image: AssetImage(CommonWidget.getImagePath("new_bg.png"))),
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 45, left: 15),
                    child: InkWell(
                      onTap: () {
                        CommonWidget.safePop(context, result: true);
                      },
                      child: Image.asset(
                        CommonWidget.getImagePath("backspace.png"),
                        height: 40,
                        width: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (servicesData.isNotEmpty)
            Expanded(
                child: Container(
              margin: const EdgeInsets.only(right: 15, left: 15, bottom: 15),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(top: 10, left: 15),
                      child: CommonWidget.getTextWidgetPopbold("Add Offers",
                          color: ColorClass.base_color, textsize: 18),
                    ),
                    CommonWidget.getTextFieldWithgrayboderandclickable(
                        "Select Service", serviceController, () {
                      showCatDialog();
                    }, "dropdown"),
                    CommonWidget.getTextFieldWithgrayboder(
                        "Enter Title", titleController),
                    CommonWidget.getTextFieldWithgrayboder(
                        "Enter Description", descriptionController),
                    CommonWidget.getTextFieldWithgrayboder(
                        "Enter Discount(Optional)", discountController),
                    Row(
                      children: [
                        // Expanded(
                        //   child: CommonWidget
                        //       .getTextFieldWithgrayboderandclickable(
                        //           "Valid From", validFromController, () {
                        //     CommonPopUp.showdateNewDialog(context, (date) {
                        //       String formattedDate =
                        //           DateFormat('dd-MM-yyyy').format(date);
                        //       print(formattedDate);
                        //       setState(() {
                        //         validFromController.text = formattedDate;
                        //         /*fromDate =
                        //               DateFormat('yyyy-MM-dd').format(date);*/
                        //         fromDate = date.toString();
                        //         print(fromDate);
                        //       });
                        //     }, DateTime.now(), DateTime.now(), DateTime(2050));
                        //   }, "calendar_black"),
                        // ),
                        // SizedBox(
                        //   width: 10,
                        // ),
                        Expanded(
                          child: CommonWidget
                              .getTextFieldWithgrayboderandclickable(
                                  "Valid Until", validUntilController, () {
                            CommonPopUp.showdateNewDialog(context, (date) {
                              String formattedDate =
                                  DateFormat('dd-MM-yyyy').format(date);
                              print(formattedDate);
                              setState(() {
                                validUntilController.text = formattedDate;
                                /*toDate =
                                      DateFormat('yyyy-MM-dd').format(date);*/
                                toDate = date.toString();
                                print(toDate);
                              });
                            }, DateTime.now(), DateTime.now(), DateTime(2050));
                          }, "calendar_black"),
                        ),
                      ],
                    ),
                    // CommonWidget.getTextWidgetSubTitle("Add Offer Image",
                    //     textsize: 16),
                    GestureDetector(
                      onTap: () async {
                        BaseActivity.showFilePicker(context,
                            (List<File>? list) {
                          if (list != null) {
                            for (int i = 0; i < list.length; i++) {
                              if (selectedFiles.isEmpty) {
                                setState(() {
                                  selectedFiles.add(list[i]);
                                });
                              } else {
                                CommonWidget.errorShowSnackBarFor(
                                  context,
                                  "You can only upload 1 offer image.",
                                );
                                break;
                              }
                            }
                          }
                          print("Selected file count: ${selectedFiles.length}");
                        });
                      },
                      child: Container(
                        width: 170,
                        margin: const EdgeInsets.only(top: 10),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: ColorClass.base_color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_rounded,
                                color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            CommonWidget.getTextWidgetPopbold(
                              selectedFiles.isNotEmpty
                                  ? "1 Image Added"
                                  : "Upload Image",
                              color: Colors.white,
                              textsize: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (selectedFiles.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: selectedFiles.length,
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(top: 10, left: 10),
                                child: Stack(
                                  children: [
                                    Container(
                                        width: 80,
                                        margin:
                                            const EdgeInsets.only(top: 10, left: 10),
                                        child: CommonWidget.determineImageAsset(
                                            selectedFiles[index].path)),
                                    Align(
                                        alignment: Alignment.topRight,
                                        child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectedFiles.removeAt(index);
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
                  ],
                ),
              ),
            )),
          if (servicesData.isNotEmpty)
            InkWell(
                onTap: () async {
                  //DateTime fromDateTime = DateTime.parse(fromDate);
                  DateTime toDateTime = DateTime.parse(toDate);
                  if (BaseActivity.checkEmptyField(
                      editingController: titleController,
                      message: "Select service of offer.",
                      context: context)) {
                    return;
                  }
                  if (BaseActivity.checkEmptyField(
                      editingController: titleController,
                      message: "Enter Title of offer.",
                      context: context)) {
                    return;
                  }
                  if (BaseActivity.checkEmptyField(
                      editingController: descriptionController,
                      message: "Enter description of offer.",
                      context: context)) {
                    return;
                  }
                  // if (BaseActivity.checkEmptyField(
                  //     editingController: discountController,
                  //     message: "Enter discount of offer.",
                  //     context: context))
                  //   return;
                  if (discountController.text != "" &&
                      int.parse(discountController.text) > 100) {
                    CommonWidget.errorShowSnackBarFor(context,
                        "Discount percentage should be less then 100%");
                    return;
                  }
                  // if (BaseActivity.checkEmptyField(
                  //     editingController: validFromController,
                  //     message: "Enter valid date from.",
                  //     context: context))
                  //   return;
                  // if (BaseActivity.checkEmptyField(
                  //     editingController: discountController,
                  //     message: "Enter valid date to.",
                  //     context: context)) return;
                  if (selectedFiles.isEmpty) {
                    CommonWidget.errorShowSnackBarFor(
                        context, "Select offer image.");
                    return;
                  }
                  // if (fromDateTime.isAfter(toDateTime)) {
                  //   CommonWidget.errorShowSnackBarFor(
                  //       context, "From date cannot be greater than To date.");
                  //   return;
                  // }
                  // if (toDateTime.isBefore(fromDateTime)) {
                  //   CommonWidget.errorShowSnackBarFor(
                  //       context, "To date cannot be earlier than From date.");
                  //   return;
                  // }
                  if (toDateTime.isBefore(DateTime.now())) {
                    CommonWidget.errorShowSnackBarFor(
                        context, "Date should be grater then today date");
                    return;
                  }
                  await postImage(context);
                  addOffer();
                },
                child: Container(
                    margin: const EdgeInsets.only(right: 15, left: 15),
                    child: CommonWidget.getButtonWidget("Add Offer",
                        ColorClass.base_color, ColorClass.base_color))),
          if (servicesData.isNotEmpty)
            const SizedBox(
              height: 30,
            ),
          if (servicesData.isEmpty)
            Expanded(
                child: Center(
              child: CommonWidget.getTextWidgetPopSemi(
                  "Please Add Service First."),
            ))
        ],
      ),
    );
  }

  postImage(BuildContext context) async {
    List<File> image = [selectedFiles[0]];
    var response = await offerDataManager!.postImage(image, context);
    var data = ImageModuleData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      coverImage = data.data?.url ?? "";
      //CommonWidget.successShowSnackBarFor(context, data.message??"");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  void addOffer() async {
    var response = await offerDataManager?.addOffer(
        context,
        titleController.text,
        descriptionController.text,
        discountController.text,
        fromDate,
        toDate,
        serviceId,
        coverImage);
    var data = CommonBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      CommonWidget.safePop(context, result: true);
      //CommonWidget.navigateToKillScreen(context, ServicesListActivity());
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  getCategory(BuildContext context) async {
    var response = await offerDataManager!.getServicesList(context);
    var data = ServicesListBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        servicesData.clear();
        servicesData.addAll(data.data!);
        if(data.data!.isNotEmpty){
          serviceController.text = data.data![0].categoryName??"";
          serviceId = data.data![0].id??"";
        }
      });

      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  showCatDialog() {
    List<CheckDialogBox> typeList = [];
    for (var i in servicesData) {
      CheckDialogBox data =
          CheckDialogBox(i.categoryName ?? "", i.sId.toString());
      typeList.add(data);
    }
    showDialog(
        context: context,
        builder: (context) {
          return SearchDialogWithSingleSelect(typeList, "Select Category",
              (String id, String name) {
            setState(() {
              serviceController.text = name;
              serviceId = id;
            });
          });
        });
  }
}
