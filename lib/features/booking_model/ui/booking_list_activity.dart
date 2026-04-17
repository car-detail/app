import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Common/Color.dart';
import '../../../Common/Constant.dart';
import '../data_model/booking_data_manager.dart';
import '../data_model/booking_list_bean.dart';
import '../model/complete_model_bean.dart';

class BookingListActivity extends StatefulWidget {
  const BookingListActivity({super.key});

  @override
  State<BookingListActivity> createState() => _BookingListActivityState();
}

class _BookingListActivityState extends State<BookingListActivity> {
  BookingDataManager? dataManager;
  SharedPreferences? sharedPreferences;
  List<Records> records = [];
  var filterType = "Completed";
  TextEditingController reasone = TextEditingController();
  var show = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = BookingDataManager(sharedPreferences!);
    DateTime dateTime = DateTime.now();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    //getBookingList(context);
    getBookingListFilter(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Modern Header
          Container(
            padding: const EdgeInsets.only(top: 45, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              color: ColorClass.base_color,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                CommonWidget.buildBackButton(
                  context,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  iconColor: Colors.white,
                  onPressed: () {
                    if (mounted && context.mounted) {
                      CommonWidget.navigateToKillAllScreen(context, const DashboardActivity());
                    }
                  },
                ),
                const SizedBox(width: 16),
                const Text(
                  "Bookings",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: "Pop600",
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Filter Tabs
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterTab("Completed", filterType == "Completed"),
                ),
                Expanded(
                  child: _buildFilterTab("Pending", filterType == "Pending"),
                ),
                Expanded(
                  child: _buildFilterTab("Cancelled", filterType == "Cancelled"),
                ),
              ],
            ),
          ),
          
          // Bookings List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (mounted && context.mounted) {
                  await getBookingListFilter(context);
                }
              },
            child: records.isEmpty && show
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      var data = records[index];
                      return _buildBookingCard(data);
                    },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          filterType = title;
          getBookingListFilter(context);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? ColorClass.base_color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontFamily: "Pop500",
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Records data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with customer info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Customer Avatar with proper error handling
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  child: data.createdByImage != null && data.createdByImage!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            data.createdByImage!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          ),
                        )
                      : _buildDefaultAvatar(),
                ),
                const SizedBox(width: 10),
                // Customer details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${data.createdByFirstName ?? ""} ${data.createdByLastName ?? ""}".trim().isEmpty
                            ? "Customer"
                            : "${data.createdByFirstName ?? ""} ${data.createdByLastName ?? ""}".trim(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontFamily: "Pop600",
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.createdByMobile ?? "No contact",
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: "Pop400",
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge and Call button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(data.orderStatus ?? "pending"),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.orderStatus ?? "Pending",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontFamily: "Pop500",
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (data.createdByMobile != null && data.createdByMobile!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: data.createdByMobile,
                          );
                          if (await canLaunchUrl(launchUri)) {
                            await launchUrl(launchUri);
                          } else {
                            if (context.mounted) {
                              CommonWidget.errorShowSnackBarFor(context, "Could not launch dialer");
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ColorClass.base_color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.call,
                            color: ColorClass.base_color,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Booking details
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                _buildDetailRow(Icons.access_time, "Time Slot", CommonWidget.convertToLocalTime(data.timeSlot ?? "")),
                const SizedBox(height: 6),
                _buildDetailRow(Icons.calendar_today, "Date", DateFormat(Constant.dateFormatDigits).format(DateTime.parse(data.date ?? ""))),
                const SizedBox(height: 6),
                if (data.price != null && data.price! > 0)
                  _buildDetailRow(Icons.attach_money, "Price", "\$${data.price}"),
                
                // Action buttons for pending bookings
                if (data.orderStatus == "Pending") ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => putStatusCompleted(context, data),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text("Complete", style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => showDetailPopUp(context, data),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text("Cancel", style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Cancellation details
                if (data.orderStatus == "Cancelled") ...[
                  const SizedBox(height: 8),
                  if (data.cancelledBy != null && data.cancelledBy!.isNotEmpty) ...[
                    _buildDetailRow(Icons.person_off, "Cancelled By", data.cancelledBy!),
                    const SizedBox(height: 4),
                  ],
                  if (data.commentByUser != null && data.commentByUser!.isNotEmpty) ...[
                    _buildDetailRow(Icons.comment, "User Remark", data.commentByUser!),
                    const SizedBox(height: 4),
                  ],
                  if (data.commentByVendor != null && data.commentByVendor!.isNotEmpty)
                    _buildDetailRow(Icons.comment, "Vendor Remark", data.commentByVendor!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 12,
            fontFamily: "Pop500",
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: "Pop400",
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: 20,
      color: Colors.grey[600],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No Bookings Found",
            style: TextStyle(
              fontSize: 20,
              fontFamily: "Pop600",
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No $filterType bookings available",
            style: TextStyle(
              fontSize: 14,
              fontFamily: "Pop400",
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  getBookingList(BuildContext context) async {
    var response = await dataManager!.getBookingList(context);
    var data = BookingListBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        records.clear();
        records.addAll(data.data!.records!);
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      setState(() {
        records.clear();
      });
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  getBookingListFilter(BuildContext context) async {
    if (!mounted || !context.mounted) return;
    
    setState(() {
      show = false;
    });
    
    try {
      var response = await dataManager!.getBookingListFilter(context, filterType);
      
      if (!mounted || !context.mounted) return;
      
      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        setState(() {
          show = true;
        });
        return;
      }
      
      // Check response status code
      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to load bookings. Please check your connection and try again.");
        }
        setState(() {
          records.clear();
          show = true;
        });
        return;
      }
      
      try {
        var data = BookingListBean.fromJson(jsonDecode(response.body));
        if (data.status == "success") {
          if (mounted) {
            setState(() {
              records.clear();
              records.addAll(data.data!.records!);
              show = true;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              records.clear();
              show = true;
            });
          }
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to load bookings. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted) {
          setState(() {
            records.clear();
            show = true;
          });
        }
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error parsing bookings data. Please try again.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          records.clear();
          show = true;
        });
      }
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error loading bookings. Please check your connection and try again.");
      }
    }
  }

  putStatusCompleted(BuildContext context, Records datas) async {
    if (!mounted || !context.mounted) return;
    
    try {
      var response = await dataManager!.putStatusCompleted(context, datas.sId.toString());
      
      if (!mounted || !context.mounted) return;
      
      // Check response status code
      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to complete booking. Please try again.");
        }
        return;
      }
      
      try {
        var data = CompletedModelBean.fromJson(jsonDecode(response.body));
        if (data.status == "success") {
          if (mounted && context.mounted) {
            CommonWidget.successShowSnackBarFor(context, data.message ?? "Booking completed successfully!");
          }
          if (mounted && context.mounted) {
            getBookingListFilter(context);
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to complete booking. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error processing request. Please try again.");
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error completing booking. Please check your connection and try again.");
      }
    }
  }

  putStatusCancel(BuildContext context, Records datas) async {
    if (!mounted || !context.mounted) return;
    
    try {
      var response = await dataManager!
          .putStatusCancel(context, reasone.text, datas.sId.toString());
      
      if (!mounted || !context.mounted) return;
      
      // Check response status code
      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to cancel booking. Please try again.");
        }
        return;
      }
      
      try {
        var data = CompletedModelBean.fromJson(jsonDecode(response.body));
        if (data.status == "success") {
          reasone.text = "";
          
          // Immediately remove the booking from the local list if viewing Pending bookings
          // since cancelled bookings shouldn't appear in the Pending list
          if (mounted && filterType == "Pending") {
            setState(() {
              records.removeWhere((record) => record.sId == datas.sId);
            });
          }
          
          if (mounted && context.mounted) {
            CommonWidget.successShowSnackBarFor(context, data.message ?? "Booking cancelled successfully!");
          }
          
          // Refresh the list to ensure consistency with server
          if (mounted && context.mounted) {
            getBookingListFilter(context);
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to cancel booking. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error processing request. Please try again.");
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error cancelling booking. Please check your connection and try again.");
      }
    }
  }

  showDetailPopUp(
    BuildContext context,
    Records data,
  ) {
    AlertDialog alert = AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      content: SizedBox(
          height: 330,
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: GestureDetector(
                  onTap: () {
                    if (mounted && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.only(top: 10, right: 10),
                    child: const Image(
                      image: AssetImage("assets/images/cross.png"),
                      height: 25,
                      width: 25,
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 25, right: 25),
                      width: double.infinity,
                      child: Text(
                        "Reason For Cancel", // ?? "",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: ColorClass.base_color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: const Divider(
                          height: 3,
                          color: Color(0xffdedede),
                        )),
                    Container(
                        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: Column(
                          children: [
                            CommonWidget.getTextWidgetPopReg(
                                "You will not be able to undo this process once continue! Are you want to cancel this booking request?",
                                textsize: 12),
                            Container(
                              margin: const EdgeInsets.only(top: 10, bottom: 10),
                              height: 120,
                              child: TextField(
                                controller: reasone,
                                maxLines: 5,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontFamily: "Krub500",
                                    fontSize: 16),
                                decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        borderSide: BorderSide(
                                            color: ColorClass.light_browne,
                                            width: 1,
                                            style: BorderStyle.solid)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        borderSide: BorderSide(
                                            color: ColorClass.light_browne,
                                            width: 1,
                                            style: BorderStyle.solid)),
                                    contentPadding:
                                        const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                    filled: true,
                                    fillColor: Colors.green[50],
                                    hintText: "Enter Reason....",
                                    hintStyle: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500),
                                    border: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        borderSide: BorderSide(
                                            color: ColorClass.light_browne))),
                                //controller: userid,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                      margin: const EdgeInsets.only(right: 5),
                                      child: CommonWidget.getButtonWidget(
                                          "No",
                                          Colors.green[300]!,
                                          Colors.green[300]!)),
                                )),
                                Expanded(
                                    child: GestureDetector(
                                  onTap: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    //FocusManager.instance.primaryFocus?.unfocus();
                                    Navigator.pop(context);
                                    putStatusCancel(context, data);
                                  },
                                  child: Container(
                                      margin: const EdgeInsets.only(left: 5),
                                      child: CommonWidget.getButtonWidget("Yes",
                                          Colors.red[400]!, Colors.red[400]!)),
                                ))
                              ],
                            )
                          ],
                        )),
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
