import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'Color.dart';

class CommonPopUp {
  static showalertDialog(
      BuildContext context,
      String boldtitle,
      String title,
      String positivetitle,
      String negativetitle,
      String image,
      Function() positivefuntion,
      Function() negativefuntion,
      double height,
      {bool isnevbuttom = true,
      bool isboldtitle = true,
      MainAxisAlignment mainAxisAlignment = MainAxisAlignment.spaceBetween,
      int positivetitlecolorButton = 0xff002C77,
      int navtextColorButton = 0xff3C3E41}) {
    AlertDialog alert = AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      content: SizedBox(
          height: height,
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 5, top: 5),
                    child: const Image(
                      image: AssetImage("assets/images/cross.png"),
                      height: 25,
                      width: 25,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    if (isboldtitle)
                      Text(
                        boldtitle,
                        style: TextStyle(
                            color: ColorClass.base_color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    if (image != "")
                      Image(
                        image: AssetImage("assets/images/$image.png"),
                        height: 60,
                        width: 60,
                      ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xff535353),
                            fontSize: 15,
                            fontWeight: FontWeight.normal),
                      ),
                    ),
                    Container(
                        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: const Divider(
                          height: 3,
                          color: Color(0xffdedede),
                        )),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: mainAxisAlignment,
                        children: [
                          if (isnevbuttom)
                            Expanded(
                              child: GestureDetector(
                                onTap: negativefuntion,
                                child: Container(
                                  margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: const Color(0xff3C3E41)),
                                    borderRadius:
                                        const BorderRadius.all(Radius.circular(20)),
                                    color: Color(navtextColorButton),
                                  ),
                                  child: Text(
                                    negativetitle,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          if (isnevbuttom)
                            Container(
                              height: 40,
                              width: 1,
                              decoration: const BoxDecoration(
                                color: Color(0xffE8E3E3),
                              ),
                            ),
                          Expanded(
                            child: GestureDetector(
                              onTap: positivefuntion,
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                                padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                                decoration: BoxDecoration(
                                  color: Color(positivetitlecolorButton),
                                  borderRadius:
                                      const BorderRadius.all(Radius.circular(20)),
                                ),
                                child: Text(
                                  positivetitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static showdateDialog(
      BuildContext context, Function(DateTime date) updatefield) async {
    showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: ColorClass.base_color, // <-- SEE HERE
                onPrimary: Colors.white, // <-- SEE HERE
                onSurface: ColorClass.base_color, // <-- SEE HERE
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: ColorClass.base_color, // button text color
                ),
              ),
            ),
            child: child!,
          );
        }).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      print(pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
      print(formattedDate);
      updatefield(
          pickedDate); //formatted date output using intl package =>  2021-03-16
      /*setState(() {
        dateController.text =
            formattedDate; //set output date to TextField value.
      });*/
    });
  }

  static showdateNewDialog(
      BuildContext context,
      Function(DateTime date) updatefield,
      DateTime initialDate,
      DateTime firstDate,
      DateTime lastDate) async {
    showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        //DateTime.now() - not to allow to choose before today.
        lastDate: lastDate,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: ColorClass.base_color, // <-- SEE HERE
                onPrimary: Colors.white, // <-- SEE HERE
                onSurface: ColorClass.base_color, // <-- SEE HERE
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: ColorClass.base_color, // button text color
                ),
              ),
            ),
            child: child!,
          );
        }).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      print(pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
      print(formattedDate);
      updatefield(
          pickedDate); //formatted date output using intl package =>  2021-03-16
      /*setState(() {
        dateController.text =
            formattedDate; //set output date to TextField value.
      });*/
    });
  }

  static showTimeDialog(
    BuildContext context,
    Function(TimeOfDay time) updatefield,
  ) async {
    showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: ColorClass.base_color, // <-- SEE HERE
                onPrimary: Colors.white, // <-- SEE HERE
                onSurface: ColorClass.base_color, // <-- SEE HERE
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: ColorClass.base_color, // button text color
                ),
              ),
            ),
            child: child!,
          );
        }).then((time) {
      if (time == null) {
        return;
      }
      print(time); //pickedDate output format => 2021-03-10 00:00:00.000
      updatefield(
          time); //formatted date output using intl package =>  2021-03-16
    });
  }

  static showalertDialogwithimage(
      BuildContext context,
      String boldtitle,
      String title,
      String positivetitle,
      String negativetitle,
      String image,
      Function() positivefuntion,
      Function() negativefuntion,
      double height,
      {bool isnevbuttom = true,
      bool isboldtitle = true,
      MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center}) {
    AlertDialog alert = AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      content: SizedBox(
          height: height,
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Image(
                    image: AssetImage("assets/images/delete.png"),
                    height: 25,
                    width: 25,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    if (isboldtitle)
                      Text(
                        boldtitle,
                        style: TextStyle(
                            color: ColorClass.base_color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    if (image != "")
                      Image(
                        image: AssetImage("assets/images/$image.png"),
                        height: 60,
                        width: 60,
                      ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xff535353),
                            fontSize: 15,
                            fontWeight: FontWeight.normal),
                      ),
                    ),
                    Container(
                        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: const Divider(
                          height: 3,
                          color: Color(0xffdedede),
                        )),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: mainAxisAlignment,
                        children: [
                          if (isnevbuttom)
                            Expanded(
                              child: GestureDetector(
                                onTap: negativefuntion,
                                child: Container(
                                  margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: const Color(0xff3C3E41)),
                                    borderRadius:
                                        const BorderRadius.all(Radius.circular(20)),
                                    color: const Color(0xff3C3E41),
                                  ),
                                  child: Text(
                                    negativetitle,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          if (isnevbuttom)
                            Container(
                              height: 40,
                              width: 1,
                              decoration: const BoxDecoration(
                                color: Color(0xffE8E3E3),
                              ),
                            ),
                          GestureDetector(
                            onTap: positivefuntion,
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                              padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                              decoration: BoxDecoration(
                                color: ColorClass.base_color,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(20)),
                              ),
                              child: Text(
                                positivetitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
