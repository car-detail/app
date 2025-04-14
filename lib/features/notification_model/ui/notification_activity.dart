import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:flutter/material.dart';

class NotificationActivity extends StatefulWidget {
  const NotificationActivity({super.key});

  @override
  State<NotificationActivity> createState() => _NotificationActivityState();
}

class _NotificationActivityState extends State<NotificationActivity> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CommonWidget.gettopbar("Notification", context),
          SizedBox(height: 10,),
          Expanded(
              child: ListView.builder(
                padding:  EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: 2,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                  color:ColorClass.base_light_color,

                                  borderRadius: BorderRadius.all(Radius.circular(30))
                              ),
                              child: Center(child: Image.asset(CommonWidget.getImagePath("noti_icon.png"), height: 25,width: 25,))),
                          SizedBox(width: 5,),
                          Expanded(
                              child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              index == 0
                                  ? CommonWidget.getTextWidget500(
                                      "Service Booked Successfully",
                                      color: ColorClass.base_color,
                                      textAlign: TextAlign.start,
                                      size: 12)
                                  : CommonWidget.getTextWidget500(
                                      "50% Off on your first Car Washing...",
                                      color: ColorClass.base_color,
                                      textAlign: TextAlign.start,
                                      size: 12),
                              CommonWidget.getTextRich("",
                                  "Lorem Ipsum been the industry's standard dummy text", textsize: 10)
                            ],
                          )),
                          SizedBox(width: 5,),

                          CommonWidget.getTextWidget500("1h ago", size: 12)
                        ],
                      ),
                    );
                  }))
        ],
      ),
    );
  }
}
