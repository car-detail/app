import 'package:flutter/material.dart';

import '../../Common/Color.dart';
import '../../Common/CommonWidget.dart';
import '../../Models/check_dialog_box.dart';

class SearchDialogWithSingleSelectMultiId extends StatefulWidget {
  List<CheckDialogBox> teacherData;
  String title;
  Function(String id, String id2, String name) onTeacherSelected;
  bool isAll;

  SearchDialogWithSingleSelectMultiId(
      {required this.teacherData, required this.title, required this.onTeacherSelected,
      this.isAll = false, super.key});

  @override
  State<SearchDialogWithSingleSelectMultiId> createState() =>
      _SearchDialogWithSingleSelectMultiIdState();
}

class _SearchDialogWithSingleSelectMultiIdState
    extends State<SearchDialogWithSingleSelectMultiId> {
  List<CheckDialogBox> filteredTeacherData = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredTeacherData = widget.teacherData;
  }

  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      List<CheckDialogBox> dummyListData = [];
      widget.teacherData.forEach((item) {
        if (item.title.toLowerCase().contains(query.toLowerCase()) ||
            item.id.toString().toLowerCase().contains(query.toLowerCase())) {
          dummyListData.add(item);
        }
      });
      setState(() {
        filteredTeacherData = dummyListData;
      });
    } else {
      setState(() {
        filteredTeacherData = widget.teacherData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      content: Container(
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
                    margin: EdgeInsets.only(left: 25, right: 25),
                    width: double.infinity,
                    child: CommonWidget.getTextWidgetPopSemi(widget.title, color: ColorClass.base_color),
                  ),
                  Container(
                    child: CommonWidget.getTextFieldWithgrayboderWithIcon(
                        "Search here...", "search", searchController,
                        onchange: (text) {
                      filterSearchResults(text);
                    }),
                  ),
                  if (widget.isAll)
                    GestureDetector(
                      onTap: () {
                        widget.onTeacherSelected("0","0", "All");
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.fromLTRB(15, 0, 15, 5),
                        child: CommonWidget.getTextWidgetPopReg(
                          "All",textAlign: TextAlign.start
                        ),
                      ),
                    ),
                  if (widget.isAll)
                    Container(
                      margin: EdgeInsets.only(left: 10, right: 10),
                      child: Divider(
                        color: ColorClass.middel_gray_base,
                        height: 1,
                      ),
                    ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: ListView.builder(
                        itemCount: filteredTeacherData.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          var data = filteredTeacherData[index];
                          return GestureDetector(
                            onTap: () {
                              widget.onTeacherSelected(
                                  data.id, data.id2,data.title);
                              Navigator.pop(context);
                            },
                            child: Container(
                              child: Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.all(5),
                                    child: CommonWidget.getTextWidgetPopReg(
                                        "${data.title ?? ""}",textsize: 14, textAlign: TextAlign.start
                                    ),
                                    width: double.infinity,
                                  ),
                                  Divider(
                                    color: ColorClass.middel_gray_base,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
