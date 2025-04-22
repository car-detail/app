import 'dart:io';
import 'dart:ui';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:html/parser.dart' as html;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'Color.dart';

class CommonWidget {
  static convertHtmlToString(String htmlString) {
    final htmlText = HtmlUnescape().convert(htmlString);
    final document = html.parse(htmlText);
    String parsedString = html.parse(document.body!.text).documentElement!.text;
    return parsedString;
  }
  static String convertToLocalTimeWithAMPM(String utcTimeString) {
    // Parse the UTC time string into a DateTime object
    DateTime utcTime = DateTime.parse(utcTimeString).toUtc();

    // Convert to local time
    DateTime localTime = utcTime.toLocal();

    // Format the time in 12-hour format with AM/PM
    String formattedTime = DateFormat('hh:mm a').format(localTime);

    return formattedTime;
  }
  static String convertToLocalTime(String timeRange, {String sourceTimeZone = "UTC"}) {
    List<String> times = timeRange.split(" - ");
    if (times.length != 2) {
      return "Invalid time range format";
    }
    final now = DateTime.now();
    String startTime = times[0];
    String endTime = times[1];
    DateTime start =
        DateTime.parse("${now.toIso8601String().split('T')[0]}T$startTime:00Z")
            .toUtc();
    DateTime end =
        DateTime.parse("${now.toIso8601String().split('T')[0]}T$endTime:00Z")
            .toUtc();

    // Convert to local time
    DateTime localStart = start.toLocal();
    DateTime localEnd = end.toLocal();

    // Format the times for output
    String formattedStart = DateFormat('hh:mm a').format(localStart); // e.g., "02:00 PM"
    String formattedEnd = DateFormat('hh:mm a').format(localEnd);     // e.g., "03:00 PM"

    return "$formattedStart - $formattedEnd";
  }

  static String getImagePath(String imageName) {
    return "assets/images/$imageName";
  }

  static newconvertHtmlToText(String html) {
    return Html(
        data: "<!DOCTYPE html><html><body>$html</body></html>",
        shrinkWrap: true);
  }

  static void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  // Replace the current screen with a new one and destroy the previous screens in stack
  static void navigateToKillScreen(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static void navigateToKillAllScreen(BuildContext context, Widget page) {
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => page), (route) => false);
  }

  //paas some extra values when navigation from one screen to other screen
  static void navigateToScreenWithExtras(
      BuildContext context, Widget screen, Map<String, dynamic> extraValues) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => screen,
        settings: RouteSettings(
          arguments: extraValues, // Pass your Map of extra values here
        ),
      ),
    );
  }

  static Widget getTextWidgetPopSemi(String title,
      {textAlign = TextAlign.center,
      double size = 14,
      Color color = Colors.black}) {
    return Text(
      title,
      style: TextStyle(fontFamily: "PopSemi", color: color, fontSize: size),
      textAlign: textAlign,
    );
  }

  static Widget getTextWidgetPopbold(String title,
      {double textsize = 14,
      textAlign = TextAlign.center,
      Color color = Colors.black}) {
    return Text(
      title,
      style: TextStyle(fontFamily: "Popbold", color: color, fontSize: textsize),
      textAlign: textAlign,
    );
  }

  static Widget getTextWidgetPopReg(String title,
      {double textsize = 14,
      textAlign = TextAlign.center,
      Color color = Colors.black,
      int? maxline}) {
    return Text(
      title,
      style: TextStyle(fontFamily: "PopReg", color: color, fontSize: textsize),
      textAlign: textAlign,
      maxLines: maxline,
    );
  }

  static Widget getTextWidgetTitle(String title,
      {double textsize = 14,
      textAlign = TextAlign.center,
      Color color = Colors.black,
      int? maxline}) {
    return Text(
      title,
      style: TextStyle(fontFamily: "comBold", color: color, fontSize: textsize),
      textAlign: textAlign,
      maxLines: maxline,
    );
  }

  static Widget getTextWidgetSubTitle(String title,
      {double textsize = 14,
      textAlign = TextAlign.center,
      Color color = Colors.black,
      int? maxline}) {
    return Text(
      title,
      style:
          TextStyle(fontFamily: "interBold", color: color, fontSize: textsize),
      textAlign: textAlign,
      maxLines: maxline,
    );
  }

<<<<<<< HEAD
  static Widget getTextRich(String title, String value,
      {Color titlecolor = Colors.black,
      Color valuecolor = Colors.black,
      double textsize = 14,
      int maxLine = 5}) {
    return Text.rich(
        maxLines: maxLine,
        overflow: TextOverflow.ellipsis,
        TextSpan(
            text: title,
            style: TextStyle(
                fontFamily: "PopSemi", color: titlecolor, fontSize: textsize),
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                    fontFamily: "PopReg",
                    color: valuecolor,
                    fontSize: textsize),
              )
            ]));
=======
  static Widget getTextRich(
      String title,
      String value, {
        Color titlecolor = Colors.black,
        Color valuecolor = Colors.green,
        double textsize = 12, // Reduced text size for compactness
        int maxLine = 2, // Reduce the number of max lines
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0), // Smaller vertical padding
      child: Text.rich(
        maxLines: maxLine,
        overflow: TextOverflow.ellipsis,
        TextSpan(
          text: title,
          style: TextStyle(
            fontFamily: "PopSemi",
            color: titlecolor,
            fontSize: textsize,
            fontWeight: FontWeight.bold, // Keep title bold for emphasis
          ),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                fontFamily: "PopReg",
                color: valuecolor,
                fontSize: textsize,
                fontWeight: FontWeight.normal, // Regular weight for value
              ),
            ),
          ],
        ),
      ),
    );
>>>>>>> 5685f242ff1ad28fee55833583424e8bd456bf1e
  }

  static Widget getMendatroyTextRich(String title,
      {Color titlecolor = Colors.black}) {
    return Text.rich(TextSpan(
        text: title,
        style:
            TextStyle(fontFamily: "PopSemi", color: titlecolor, fontSize: 14),
        children: [
          TextSpan(
            text: "*",
            style: TextStyle(
                fontFamily: "PopSemi", color: Colors.red, fontSize: 14),
          )
        ]));
  }

  static Widget getTextRich_value_bold(String title, String value,
      {Color titlecolor = Colors.black,
      Color valuecolor = Colors.black,
      double textsize = 14}) {
    return Text.rich(TextSpan(
        text: title,
        style: TextStyle(
            fontFamily: "PopReg", color: titlecolor, fontSize: textsize),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
                fontFamily: "Popbold", color: valuecolor, fontSize: textsize),
          )
        ]));
  }

  TextEditingController textEditing = TextEditingController();

  static Widget getTextFieldWithgrayboder(
      String hinttext, TextEditingController textEditingController,
      {double height = 40,
      int maxline = 1,
      double bottommargin = 10,
      ValueChanged<String>? onchange,
      bool readOnly = false,
      VoidCallback? funtion,
      TextInputType keyboardType = TextInputType.text,
      double fontsize = 14}) {
    return Container(
      margin: EdgeInsets.only(top: bottommargin, bottom: bottommargin),
      height: height,
      child: TextField(
        readOnly: readOnly,
        onTap: funtion,
        controller: textEditingController,
        maxLines: maxline,
        keyboardType: keyboardType,
        onChanged: onchange,
        style: TextStyle(
            color: Colors.black, fontFamily: "PopReg", fontSize: fontsize),
        decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                borderSide: BorderSide(
                    color: ColorClass.base_color,
                    width: 1,
                    style: BorderStyle.solid)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                borderSide: BorderSide(
                    color: ColorClass.middel_gray_base,
                    width: 1,
                    style: BorderStyle.solid)),
            contentPadding: EdgeInsets.fromLTRB(10, 5, 10, 5),
            filled: true,
            fillColor: ColorClass.base_light_color,
            hintText: hinttext,
            hintStyle: TextStyle(
                color: Colors.grey[800],
                fontSize: fontsize,
                fontWeight: FontWeight.w300),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                borderSide: BorderSide(color: ColorClass.light_browne))),
        //controller: userid,
      ),
    );
  }

  static Widget getTextFieldWithgrayboderandclickable(String hinttext,
      TextEditingController controller, VoidCallback funtion, String image,
      {double bottommargin = 10, double fontsize = 14, double height = 40}) {
    return Container(
      margin: EdgeInsets.only(top: bottommargin, bottom: bottommargin),
      height: height,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: funtion,
        keyboardType: TextInputType.text,
        style: TextStyle(
            color: Colors.black, fontFamily: "PopReg", fontSize: fontsize),
        decoration: InputDecoration(
          suffixIcon: Container(
            padding: EdgeInsets.all(10),
            child: Image(
              image: AssetImage("assets/images/$image.png"),
              height: 12,
              width: 12,
              color: ColorClass.base_color,
            ),
          ),
          contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
          filled: true,
          fillColor: ColorClass.base_light_color,
          hintText: hinttext,
          hintStyle: TextStyle(color: Colors.grey, fontSize: fontsize),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              borderSide: BorderSide(
                  color: ColorClass.base_color,
                  width: 1,
                  style: BorderStyle.solid)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              borderSide: BorderSide(
                  color: ColorClass.light_gray_base,
                  width: 1,
                  style: BorderStyle.solid)),
        ),
      ),
    );
  }

  static Widget getTextFieldWithgrayboderandclickablewithImage(
      String hinttext,
      TextEditingController controller,
      VoidCallback funtion,
      String image,
      String image2,
      {double bottommargin = 10}) {
    return Container(
      margin: EdgeInsets.only(top: bottommargin, bottom: bottommargin),
      height: 40,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: funtion,
        keyboardType: TextInputType.text,
        style:
            TextStyle(color: Colors.black, fontFamily: "PopReg", fontSize: 14),
        decoration: InputDecoration(
          suffixIcon: Container(
            padding: EdgeInsets.all(10),
            child: Image(
              image: AssetImage("assets/images/$image.png"),
              height: 12,
              width: 12,
            ),
          ),
          prefixIcon: Container(
            padding: EdgeInsets.all(10),
            child: Image(
              image: AssetImage("assets/images/$image2.png"),
              height: 12,
              width: 12,
            ),
          ),
          contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
          filled: true,
          fillColor: Colors.white,
          hintText: hinttext,
          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(
                  color: ColorClass.base_color,
                  width: 1,
                  style: BorderStyle.solid)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(
                  color: ColorClass.light_gray_base,
                  width: 1,
                  style: BorderStyle.solid)),
        ),
      ),
    );
  }

  static Widget getGradinetButton(String title,
      {int startcolor = 0xff082365,
      int endcolor = 0xff1042BC,
      double width = double.infinity,
      double height = 35,
      int textColor = 0xffFFFFFF}) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(startcolor), Color(endcolor)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        //color: Color(0xffFF701C),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Color(textColor),
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static Widget getButtonWidget(String title, Color bgcolor, Color bodercolor,
      {double size = 14, double height = 40, Color textcolor = Colors.white}) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
      height: height,
      decoration: BoxDecoration(
        color: bgcolor,
        border: Border.all(color: bodercolor, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
              color: textcolor, fontSize: size, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static Widget gettopbar(String title, BuildContext context , {bool isBack = true}) {
    return Stack(
      children: [
        Container(
          height: 90,
          width: double.infinity,
          color: ColorClass.base_color,
        ),
        Container(
          margin: EdgeInsets.only(top: 45, left: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if(isBack)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Image(
                  image: AssetImage("assets/images/left_icon.png"),
                  width: 30,
                  height: 30,
                ),
              )else
                Container(height: 30,width: 30,)
              ,
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: 5, right: 5),
                  child: Text(
                    title,
                    style: TextStyle(
                        fontFamily: "Popbold",
                        color: Colors.white,
                        fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Container(
                height: 30,
                width: 30,
              )
            ],
          ),
        ),
      ],
    );
  }

  static Widget getTextWidget500(String title,
      {textAlign = TextAlign.center,
      double size = 16,
      Color color = Colors.black}) {
    return Text(
      title,
      style: TextStyle(fontFamily: "Pop500", color: color, fontSize: size),
      textAlign: textAlign,
    );
  }

  static Widget getTextWidget400(String title, double textsize,
      {textAlign = TextAlign.center, Color color = Colors.black}) {
    return Text(
      title,
      style: TextStyle(fontFamily: "Pop400", color: color, fontSize: textsize),
      textAlign: textAlign,
    );
  }

  static Widget getTextWidget300(String title, double textsize,
      {textAlign = TextAlign.center, Color color = Colors.black}) {
    return Text(
      title,
      style: TextStyle(fontFamily: "Pop300", color: color, fontSize: textsize),
      textAlign: textAlign,
    );
  }

  static Widget getTextWidget600(String title, double textsize,
      {textAlign = TextAlign.center, Color color = Colors.black}) {
    return Text(
      title,
      style: TextStyle(fontFamily: "Pop600", color: color, fontSize: textsize),
      textAlign: textAlign,
    );
  }

  static gettopbarwithmenuicon(BuildContext context, title,
      {Function()? funtion,
      icon = "home",
      Function()? backFuntion,
      bool isHome = true,
      bool isBack = true}) {
    return Stack(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          child: Image(
            image: AssetImage("assets/images/top_bar_new.png"),
            fit: BoxFit.fill,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 0, left: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isBack)
                GestureDetector(
                  onTap: () {
                    if (backFuntion == null) {
                      Navigator.pop(context);
                    } else {
                      backFuntion.call();
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.only(left: 10, top: 45),
                    child: Image(
                      image: AssetImage("assets/images/left_icon.png"),
                      width: 30,
                      height: 30,
                    ),
                  ),
                )
              else
                Container(
                  margin: EdgeInsets.only(right: 10, top: 45),
                  height: 40,
                  width: 30,
                ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 45, left: 5, right: 5),
                  child: Text(
                    title,
                    style: TextStyle(
                        fontFamily: "Popbold",
                        color: Colors.white,
                        fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (isHome)
                Container(
                  margin: EdgeInsets.only(right: 10, top: 45),
                  child: Builder(builder: (context) {
                    return IconButton(
                      icon: Image.asset(
                        'assets/images/${icon}.png',
                        height: 25,
                        width: 25,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (funtion == null) {
                          /*Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  DashboardActivity(),
                            ),
                            (route) => false,
                          );*/
                        } else {
                          funtion.call();
                        }
                      },
                    );
                  }),
                )
              else
                Container(
                  margin: EdgeInsets.only(right: 10, top: 45),
                  height: 40,
                  width: 30,
                )
            ],
          ),
        ),
      ],
    );
  }

  static getTextWithImage(String text, String image,
      {double size = 25,
      Color textcolor = Colors.black,
      double textsixe = 15,
      MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center}) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: [
        Image(
          image: AssetImage("assets/images/$image.png"),
          height: size,
          width: size,
        ),
        Container(
            margin: EdgeInsets.only(left: 5),
            child: CommonWidget.getTextWidgetPopReg(text,
                textsize: textsixe, color: textcolor)),
      ],
    );
  }

  static getTextWithImagenew(String text, String image,
      {double size = 25,
      double textsixe = 15,
      Color color = Colors.black,
      TextAlign textAlign = TextAlign.start}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Image(
          image: AssetImage("assets/images/$image.png"),
          height: size,
          width: size,
        ),
        Expanded(
          child: Container(
              margin: EdgeInsets.only(left: 5),
              child: CommonWidget.getTextWidgetPopReg(text,
                  textsize: textsixe, textAlign: textAlign, color: color)),
        )
      ],
    );
  }

  static Widget gettopbarandroid() {
    if (Platform.isAndroid) {
      return Container(
        color: ColorClass.base_color,
        width: double.infinity,
        height: 35,
      );
    } else {
      return Container();
    }
  }

  static double gettopmaeginforAndropid() {
    if (Platform.isAndroid) {
      return 15;
    } else {
      return 45;
    }
  }

  static Widget getTextFieldWithgrayboderWithIcon(String hinttext, String image,
      TextEditingController textEditingController,
      {double radius = 20,
      double bottommargin = 10,
      ValueChanged<String>? onchange,
      TextInputType keytype = TextInputType.text}) {
    return Container(
      //color: Colors.red,
      margin: EdgeInsets.only(top: bottommargin, bottom: bottommargin),
      height: 40,
      child: TextField(
        controller: textEditingController,
        keyboardType: keytype,
        onChanged: onchange,
        style: const TextStyle(
            color: Colors.black, fontFamily: "PopReg", fontSize: 16),
        decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(radius)),
                borderSide: BorderSide(
                    color: ColorClass.base_color,
                    width: 1,
                    style: BorderStyle.solid)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(radius)),
                borderSide: BorderSide(
                    color: Color(0xffdedede),
                    width: 1,
                    style: BorderStyle.solid)),
            contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
            suffixIcon: Padding(
                padding: EdgeInsets.all(10),
                child: Image(
                  image: AssetImage("assets/images/$image.png"),
                  height: 15,
                  width: 15,
                )),
            filled: true,
            fillColor: Colors.white,
            hintText: hinttext,
            hintStyle: TextStyle(
                color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(radius)),
                borderSide: BorderSide(color: Color(0xffdedede)))),
        //controller: userid,
      ),
    );
  }

  static Widget getTextFieldWithgrayboderWithIconPre(String hinttext,
      String image, TextEditingController textEditingController,
      {double radius = 10,
      double bottommargin = 10,
      ValueChanged<String>? onchange}) {
    return Container(
      //color: Colors.red,
      margin: EdgeInsets.only(top: bottommargin, bottom: bottommargin),
      height: 40,
      child: TextField(
        controller: textEditingController,
        keyboardType: TextInputType.text,
        onChanged: onchange,
        style: const TextStyle(
            color: Colors.black, fontFamily: "PopReg", fontSize: 16),
        decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(radius)),
                borderSide: BorderSide(
                    color: ColorClass.base_color,
                    width: 1,
                    style: BorderStyle.solid)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(radius)),
                borderSide: BorderSide(
                    color: Color(0xffdedede),
                    width: 1,
                    style: BorderStyle.solid)),
            contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
            prefixIcon: Padding(
                padding: EdgeInsets.all(10),
                child: Image(
                  image: AssetImage("assets/images/$image.png"),
                  height: 15,
                  width: 15,
                )),
            filled: true,
            fillColor: Colors.white,
            hintText: hinttext,
            hintStyle: TextStyle(
                color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(radius)),
                borderSide: BorderSide(color: Color(0xffdedede)))),
        //controller: userid,
      ),
    );
  }

  static errorShowSnackBarFor(BuildContext context, String message) {
/*
    final snackBar = SnackBar(
        backgroundColor: Colors.red[100],
        content: Container(
            child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.red, fontWeight: FontWeight.w500, fontSize: 16),
        )));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
*/

    BotToast.showText(
      contentPadding: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      contentColor: Colors.red[100]!,
      text: message,
      textStyle: TextStyle(
          color: Colors.red, fontWeight: FontWeight.w500, fontSize: 16),
    );
  }

  static successShowSnackBarFor(BuildContext context, String message) {
    /*final snackBar = SnackBar(
        backgroundColor: Colors.green[100],
        content: Container(
            child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.green, fontWeight: FontWeight.w500, fontSize: 16),
        )));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);*/

    BotToast.showText(
      contentPadding: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      contentColor: Colors.green[100]!,
      text: message,
      textStyle: TextStyle(
          color: Colors.green, fontWeight: FontWeight.w500, fontSize: 16),
    );
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
      MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
      int nevcolor = 0xff3C3E41,
      int povColor = 0xff002C77}) {
    AlertDialog alert = AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      content: Container(
          height: height,
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image(
                    image: AssetImage("assets/images/delete.png"),
                    height: 25,
                    width: 25,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    if (isboldtitle)
                      Text(
                        boldtitle,
                        style: TextStyle(
                            color: Color(ColorClass.base_color_int),
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
                      margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xff535353),
                            fontSize: 15,
                            fontWeight: FontWeight.normal),
                      ),
                    ),
                    Container(
                        margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: Divider(
                          height: 3,
                          color: Color(0xffdedede),
                        )),
                    Container(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: mainAxisAlignment,
                        children: [
                          if (isnevbuttom)
                            Expanded(
                              child: GestureDetector(
                                onTap: negativefuntion,
                                child: Container(
                                  margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                                  padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20)),
                                    color: Color(nevcolor),
                                  ),
                                  child: Text(
                                    negativetitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
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
                              decoration: BoxDecoration(
                                color: Color(0xffE8E3E3),
                              ),
                            ),
                          Expanded(
                            child: GestureDetector(
                              onTap: positivefuntion,
                              child: Container(
                                margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                                padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                                decoration: BoxDecoration(
                                  color: Color(povColor),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                ),
                                child: Text(
                                  positivetitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
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

  static Widget determineImageAsset(String filePath) {
    if (filePath.endsWith(".pdf") || filePath.endsWith(".PDF")) {
      return Image.asset(
        getImagePath("pdf_logo.jpg"),
        height: 100,
        width: 100,
      );
    } else if (filePath.endsWith(".doc") || filePath.endsWith(".docx")) {
      return Image.asset(
        getImagePath("word_img.jpg"),
        height: 100,
        width: 100,
      );
    } else if (filePath.endsWith(".mp3") ||
        filePath.endsWith(".aac") ||
        filePath.endsWith(".wav") ||
        filePath.endsWith(".m4a")) {
      return Image.asset(
        getImagePath("audio.jpg"),
        height: 100,
        width: 100,
      );
    } else if (filePath.endsWith(".xlsx") || filePath.endsWith(".xls")) {
      return Image.asset(
        getImagePath("excel_img.jpg"),
        height: 100,
        width: 100,
      );
    } else if (filePath.endsWith(".pptx") || filePath.endsWith(".ppt")) {
      return Image.asset(
        getImagePath("ppt_img.jpg"),
        height: 100,
        width: 100,
      );
    } else {
      return Image.file(
        File(filePath),
        width: 100, // Adjust the width as needed
        height: 100, // Adjust the height as needed
        fit: BoxFit.cover, // Adjust the BoxFit property as needed
      );
    }
  }

  static Widget determineImageInternetNew(String filePath) {
    if (filePath.endsWith(".pdf") || filePath.endsWith(".PDF")) {
      return Image.asset(
        getImagePath("pdf_logo.jpg"),
        height: 100,
        width: 100,
      );
    } else if (filePath.endsWith(".doc") || filePath.endsWith(".docx")) {
      return Image.asset(
        getImagePath("word_img.jpg"),
        height: 100,
        width: 100,
      );
    } else if (filePath.endsWith(".mp3") ||
        filePath.endsWith(".aac") ||
        filePath.endsWith(".wav") ||
        filePath.endsWith(".m4a")) {
      return Image.asset(
        getImagePath("audio.jpg"),
        height: 100,
        width: 100,
      );
    } else if (filePath.endsWith(".xlsx") || filePath.endsWith(".xls")) {
      return Image.asset(
        getImagePath("excel_img.png"),
        height: 100,
        width: 100,
      );
    } else if (filePath.endsWith(".pptx") || filePath.endsWith(".ppt")) {
      return Image.asset(
        getImagePath("ppt_img.png"),
        height: 100,
        width: 100,
      );
    } else {
      return Image.network(
        filePath,
        width: 100, // Adjust the width as needed
        height: 100, // Adjust the height as needed
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return Image.asset(
            getImagePath("loading.png"), width: 100,
            // Adjust the width as needed
            height: 100,
          );
        }, // Adjust the BoxFit property as needed
      );
    }
  }

  static Widget getImageAssetwithinternet(String filePath) {
    return Image.network(
      filePath,
      width: 100, // Adjust the width as needed
      height: 100, // Adjust the height as needed
      fit: BoxFit.cover,
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        return Image.asset(
          getImagePath("loading.png"), width: 100, // Adjust the width as needed
          height: 100,
        );
      }, // Adjust the BoxFit property as needed
    );
  }

/*  static shareFile(List<String> files) async {
    List<XFile> listtoShare = [];
    for (int i = 0; i < files.length; i++) {
      final url = Uri.parse(files[i]);
      final response = await http.get(url);
      final contentType = response.headers['content-type'];
      listtoShare.add(XFile.fromData(
        response.bodyBytes,
        mimeType: contentType,
      ));
    }
    await Share.shareXFiles(listtoShare);
  }*/
  static Future<void> shareFile(
      BuildContext context, List<String> files) async {
    List<XFile> listToShare = [];

    for (int i = 0; i < files.length; i++) {
      final url = Uri.parse(files[i]);
      final response = await http.get(url);
      final contentType = response.headers['content-type'];
      listToShare.add(XFile.fromData(
        response.bodyBytes,
        mimeType: contentType,
      ));
    }

    final box = context.findRenderObject() as RenderBox?;

    if (box == null) {
      print("RenderBox is null");
      return;
    }
    await Share.shareXFiles(
      listToShare,
      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
    );
  }

  static getIconButtonWithImageAssets(
      {required String imageIcon,
      required VoidCallback clickEvent,
      double size = 30}) {
    return IconButton(
        onPressed: clickEvent,
        icon: Image.asset(
          CommonWidget.getImagePath(imageIcon),
          height: size,
          width: size,
        ));
  }

  static Widget getHtmlTextEditor(
      HtmlEditorController controller, String? hintText,
      {double margin = 10}) {
    return Container(
      margin: EdgeInsets.only(top: margin, bottom: margin),
      child: HtmlEditor(
        controller: controller,
        htmlEditorOptions: HtmlEditorOptions(
            hint: hintText,
            shouldEnsureVisible: false,
            androidUseHybridComposition: false,
            autoAdjustHeight: true
            //initialText: "<p>text content initial, if any</p>",
            ),
        htmlToolbarOptions: const HtmlToolbarOptions(
          defaultToolbarButtons: [
            InsertButtons(
              link: true,
              picture: false,
              audio: false,
              video: false,
              otherFile: false,
              table: false,
              hr: false,
            ),
            FontButtons(
              clearAll: false,
              strikethrough: false,
            ),
            ColorButtons(),
            ListButtons(listStyles: false),
            StyleButtons(),
            FontSettingButtons(),
          ],
          renderSeparatorWidget: false,
          allowImagePicking: false,
          toolbarType: ToolbarType.nativeExpandable,
        ),
        otherOptions: OtherOptions(
            height: 300,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: Colors.white,
                border: Border.all(
                  color: ColorClass.middel_gray_base,
                  width: 1,
                ))),
      ),
    );
  }

  static Future<String> getHtmlValueFromEditor(
      HtmlEditorController controller) async {
    var txt = await controller.getText();
    if (txt.contains('src=\"data:')) {
      txt =
          '<text removed due to base-64 data, displaying the text could cause the app to crash>';
    }
    print("====================$txt");
    return txt;
  }


  static String getDateFormat(String date){
    DateTime dateTime = DateTime.parse(date);
    String formattedDate = DateFormat("dd MMM yyyy").format(dateTime);
    return formattedDate;
  }
}
