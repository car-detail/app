import 'package:flutter/material.dart';

class ContainerDecoration{
  static BoxDecoration getboderwithshadowfillcolorblueE7F0FF({double borderRadius = 10,int colorbg = 0xffF8FCFF, colorBoder = 0xffD5EAFA}){
    return BoxDecoration(
      color: Color(colorbg),
      border: Border.all(
        color: Color(colorBoder), // Border color
        width: 1.0, // Border width
      ),
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      boxShadow: [
        BoxShadow(
          color: Color(0xffdedede).withOpacity(0.5),
          spreadRadius: 3,
          blurRadius: 5,
          offset: Offset(0, 2),
        ),
      ],
    );
  }
}