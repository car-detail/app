import 'dart:core';
import 'package:flutter/material.dart';

import '../../Common/Color.dart';
import '../../Common/CommonWidget.dart';
import '../../Models/check_dialog_box.dart';

class SearchDialogWithCheckBox extends StatefulWidget {
  String title;
  List<CheckDialogBox> checkListData;
  TextEditingController textController;
  List<String> idList;
  List<String> stringList;
  Function(String selectedDepIds, String selectedDepNames, List<String> idList,
      List<String> stringList) onSelectionDone;

  SearchDialogWithCheckBox(
      {required this.title,
      required this.checkListData,
      required this.textController,
      required this.idList,
      required this.stringList,
      required this.onSelectionDone,
      super.key});

  @override
  State<SearchDialogWithCheckBox> createState() =>
      _SearchDialogWithCheckBoxState();
}

class _SearchDialogWithCheckBoxState extends State<SearchDialogWithCheckBox> {
  List<CheckDialogBox> newData = [];
  var isSelectAll = false;

  @override
  void initState() {
    // TODO: implement initState
    newData.addAll(widget.checkListData);
    super.initState();
  }

  var searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      content: StatefulBuilder(
        builder:
            (BuildContext context, void Function(void Function()) setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.5,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Stack(
              children: [
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.only(top: 10, right: 10),
                      child: Image(
                        image: AssetImage("assets/images/delete.png"),
                        height: 25,
                        width: 25,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 25),
                        width: double.infinity,
                        child: CommonWidget.getTextWidgetPopbold(widget.title,color: ColorClass.base_color)
                      ),
                      CommonWidget.getTextFieldWithgrayboderWithIcon(
                          "Search", "search", searchController,
                          onchange: (text) {
                        filterSearchResults(text);
                      }),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          margin:EdgeInsets.only(left: 10,right: 10),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Container(
                                      margin: EdgeInsets.all(5),
                                      child: Text(
                                        "Select All",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          color: Colors.black, // Adjust this to match your getTextWidgetPopReg
                                        ),
                                      ),
                                    ),
                                  ),
                                  Checkbox(
                                    value: isSelectAll,
                                    onChanged: (value) {
                                      setState(() {
                                        isSelectAll = value!;
                                        if (isSelectAll) {
                                          setState(() {
                                            for (var i
                                                in widget.checkListData) {
                                              if(!widget.idList.contains(i.id)) {
                                                widget.idList.add(i.id);
                                                widget.stringList.add(i.title);
                                                i.ischeck = true;
                                              }
                                            }
                                          });
                                        } else {
                                          setState(() {
                                            for (var i
                                                in widget.checkListData) {
                                              widget.idList.remove(i.id);
                                              widget.stringList.remove(i.title);
                                              i.ischeck = false;
                                            }
                                          });
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              Divider(
                                color: ColorClass.middel_gray_base,
                                // Adjust this to match ColorClass.base_color
                                height: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: ListView.builder(
                            itemCount: newData.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              var data = newData[index];
                              return GestureDetector(
                                onTap: () {
                                  toggleSelection(data);
                                },
                                child: Container(
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              margin: EdgeInsets.all(5),
                                              child: Text(
                                                "${data.title}",
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black, // Adjust this to match your getTextWidgetPopReg
                                                ),
                                              ),
                                            ),
                                          ),
                                          Checkbox(
                                            value: data.ischeck,
                                            onChanged: (value) {
                                              setState(() {
                                                data.ischeck = value!;
                                              });
                                              toggleSelection(data);
                                            },
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        color: ColorClass.middel_gray_base,
                                        // Adjust this to match ColorClass.base_color
                                        height: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Divider(
                        color: ColorClass.middel_gray_base,
                        // Adjust this to match ColorClass.base_color
                        height: 1,
                      ),
                      GestureDetector(
                        onTap: () {
                          widget.textController.text =
                              widget.stringList.join(", ");
                          widget.onSelectionDone(
                              widget.idList.join(", "),
                              widget.stringList.join(", "),
                              widget.idList,
                              widget.stringList);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 100,
                          height: 32,
                          margin: EdgeInsets.only(top: 10),
                          padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ColorClass.start_color,
                                ColorClass.base_color
                              ], // Adjust this to match your gradient button
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              "OK",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void toggleSelection(CheckDialogBox data) {
    String departmentId = data.id;
    String departmentName = data.title;
    if (widget.idList.contains(departmentId)) {
      setState(() {
        widget.idList.remove(departmentId);
        widget.stringList.remove(departmentName);
        data.ischeck = false;
      });
    } else {
      setState(() {
        widget.idList.add(departmentId);
        widget.stringList.add(departmentName);
        data.ischeck = true;
      });
    }
  }

  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      List<CheckDialogBox> dummyListData = [];
      widget.checkListData.forEach((item) {
        if (item.id.toLowerCase().contains(query.toLowerCase()) ||
            item.title.toString().toLowerCase().contains(query.toLowerCase())) {
          dummyListData.add(item);
        }
      });
      setState(() {
        newData.clear();
        newData.addAll(dummyListData);
      });
    } else {
      setState(() {
        newData.clear();
        newData.addAll(widget.checkListData);
      });
    }
  }
}
