import 'package:flutter/material.dart';

import 'CommonWidget.dart';

class NoDataLayout extends StatelessWidget {
  const NoDataLayout({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(height: 50),
              Image(
                image: AssetImage(CommonWidget.getImagePath("no_data_image.png")),
                height: 150,
                width: 150,
              ),
              const SizedBox(height: 10),
              CommonWidget.getTextWidgetPopSemi("No Data Available",size: 18)
            ],
          ),
        ),
      ),
    );
  }
}
