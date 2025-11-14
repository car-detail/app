import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/features/home_module/model/notification_data_bean.dart';
import 'package:flutter/material.dart';

class NotificationActivity extends StatefulWidget {
  List<Notifications> notificationsList;
  NotificationActivity(this.notificationsList, {super.key});

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
          const SizedBox(height: 10,),
          Expanded(
              child: ListView.builder(
                padding:  EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: widget.notificationsList.length,
                  itemBuilder: (context, index) {
                  var data = widget.notificationsList[index];
                    return Container(
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                  color:ColorClass.base_light_color,

                                  borderRadius: const BorderRadius.all(Radius.circular(30))
                              ),
                              child: Center(child: Image.asset(CommonWidget.getImagePath("noti_icon.png"), height: 25,width: 25,))),
                          const SizedBox(width: 5,),
                          Expanded(
                              child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                  CommonWidget.getTextWidget500(
                                      data.title??"",
                                      color: ColorClass.base_color,
                                      textAlign: TextAlign.start,
                                      size: 14),
                              CommonWidget.getTextRich("",
                                  data.body??"", textsize: 12,valuecolor: Colors.black)
                            ],
                          )),
                          const SizedBox(width: 5,),

                          //CommonWidget.getTextWidget500("1h ago", size: 12)
                        ],
                      ),
                    );
                  }))
        ],
      ),
    );
  }
}
