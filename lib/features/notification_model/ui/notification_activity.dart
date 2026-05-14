import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/home_module/model/notification_data_bean.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationActivity extends StatefulWidget {
  List<Notifications> notificationsList;
  NotificationActivity(this.notificationsList, {super.key});

  @override
  State<NotificationActivity> createState() => _NotificationActivityState();
}

class _NotificationActivityState extends State<NotificationActivity> {
  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  _markAsRead() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constant.lastReadNotificationsAt, DateTime.now().toIso8601String());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0FDF4),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF166534), Color(0xFF1CB273)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => CommonWidget.safePop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Notifications", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    Text("Stay up to date", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          if (widget.notificationsList.isNotEmpty)
            Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: widget.notificationsList.length,
                    itemBuilder: (context, index) {
                    var data = widget.notificationsList[index];
                      return Container(
                        margin: EdgeInsets.fromLTRB(16, 6, 16, 6),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 3))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 48, width: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF1CB273), Color(0xFF00C853)]),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          data.title ?? "",
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                                        ),
                                      ),
                                      Text(
                                        CommonWidget.formatTimeAgo(data.createdAt),
                                        style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(data.body ?? "", style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }))
          else
            Expanded(
                child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF1CB273).withOpacity(0.15), Color(0xFF00C853).withOpacity(0.1)]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_off_rounded, size: 36, color: Color(0xFF1CB273)),
                  ),
                  SizedBox(height: 20),
                  Text("No notifications yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.5)),
                  SizedBox(height: 8),
                  Text("You're all caught up!", style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            ))
        ],
      ),
    );
  }
}
