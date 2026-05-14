import 'dart:convert';
import 'dart:io' show File;

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
    if (venderId != "" && mounted && context.mounted) {
      getCategory(context);
    }
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
                        //           DateFormat(Constant.dateFormatDigits).format(date);
                        //                        //       setState(() {
                        //         validFromController.text = formattedDate;
                        //         /*fromDate =
                        //               DateFormat(Constant.dateFormatDigits).format(date);*/
                        //         fromDate = date.toString();
                        //                        //       });
                        //     }, DateTime.now(), DateTime.now(), DateTime(2050));
                        //   }, "calendar_black"),
                        // ),
                        // SizedBox(
                        //   width: 10,
                        // ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Valid Until",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "(Optional)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              CommonWidget
                                  .getTextFieldWithgrayboderandclickable(
                                      "Select end date (optional)", validUntilController, () {
                                CommonPopUp.showdateNewDialog(context, (date) {
                                  String formattedDate =
                                      DateFormat(Constant.dateFormatDigits).format(date);
                                  setState(() {
                                    validUntilController.text = formattedDate;
                                    toDate = date.toString();
                                  });
                                }, DateTime.now(), DateTime.now(), DateTime(2050));
                              }, "calendar_black"),
                            ],
                          ),
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
                  // Expiration date is now optional - only validate if provided
                  if (toDate.isNotEmpty) {
                    try {
                      DateTime toDateTime = DateTime.parse(toDate);
                      if (toDateTime.isBefore(DateTime.now())) {
                        CommonWidget.errorShowSnackBarFor(
                            context, "Expiration date should be greater than today's date");
                        return;
                      }
                    } catch (e) {
                      // Invalid date format - allow it to proceed (will be handled by backend)
                    }
                  }
                  final uploaded = await postImage(context);
                  if (!uploaded || coverImage.isEmpty) {
                    return;
                  }
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

  Future<bool> postImage(BuildContext context) async {
    if (!mounted || !context.mounted) return false;

    try {
      List<File> image = [selectedFiles[0]];
      var response = await offerDataManager!.postImage(image, context);

      if (!mounted || !context.mounted) return false;

      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to upload image. Please try again.");
        }
        return false;
      }

      try {
        var data = ImageModuleData.fromJson(jsonDecode(response.body));
        if (data.status == "success") {
          if (mounted) {
            setState(() {
              coverImage = data.data?.url ?? "";
            });
          }
          return coverImage.isNotEmpty;
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to upload image. Please try again.");
          }
          return false;
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error processing image upload. Please try again.");
        }
        return false;
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error uploading image. Please check your connection and try again.");
      }
      return false;
    }
  }

  void addOffer() async {
    if (!mounted || !context.mounted) return;
    
    try {
      // Send empty string if expiration date is not provided
      var response = await offerDataManager?.addOffer(
          context,
          titleController.text,
          descriptionController.text,
          discountController.text,
          fromDate,
          toDate.isEmpty ? "" : toDate,
          serviceId,
          coverImage);
      
      if (!mounted || !context.mounted) return;
      
      // Check response status code
      if (response?.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to create offer. Please try again.");
        }
        return;
      }
      
      try {
        var data = CommonBean.fromJson(jsonDecode(response!.body));
        if (data.status == "success") {
          if (mounted && context.mounted) {
            CommonWidget.successShowSnackBarFor(context, data.message ?? "Offer created successfully!");
            CommonWidget.safePop(context, result: true);
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to create offer. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error processing request. Please try again.");
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error creating offer. Please check your connection and try again.");
      }
    }
  }

  getCategory(BuildContext context) async {
    if (!mounted || !context.mounted) return;
    
    try {
      var response = await offerDataManager!.getServicesList(context);
      
      if (!mounted || !context.mounted) return;
      
      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        return;
      }
      
      // Check response status code
      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to load services. Please check your connection and try again.");
        }
        return;
      }
      
      try {
        var data = ServicesListBean.fromJson(jsonDecode(response.body));
        if (data.status == "success") {
          if (mounted) {
            setState(() {
              servicesData.clear();
              servicesData.addAll(data.data!);
              if(data.data!.isNotEmpty){
                serviceController.text = data.data![0].categoryName??"";
                serviceId = data.data![0].id??"";
              }
            });
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to load services. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error parsing services data. Please try again.");
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error loading services. Please check your connection and try again.");
      }
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
