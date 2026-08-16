import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../data_model/booking_data_manager.dart';
import '../data_model/booking_list_bean.dart';

class RescheduleBookingScreen extends StatefulWidget {
  final Records booking;
  final BookingDataManager dataManager;

  const RescheduleBookingScreen({
    required this.booking,
    required this.dataManager,
    super.key,
  });

  @override
  State<RescheduleBookingScreen> createState() => _RescheduleBookingScreenState();
}

class _RescheduleBookingScreenState extends State<RescheduleBookingScreen> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isSaving = false;

  final List<String> _timeSlots = [
    "09:00-10:00",
    "10:00-11:00",
    "11:00-12:00",
    "12:00-13:00",
    "13:00-14:00",
    "14:00-15:00",
    "15:00-16:00",
    "16:00-17:00",
    "17:00-18:00",
    "18:00-19:00"
  ];

  @override
  void initState() {
    super.initState();
    if (widget.booking.date != null) {
      _selectedDate = DateTime.parse(widget.booking.date!);
    }
    if (widget.booking.timeSlot != null) {
      _selectedTimeSlot = widget.booking.timeSlot!.replaceAll(" ", "");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorClass.base_color,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitReschedule() async {
    if (_selectedDate == null) {
      CommonWidget.errorShowSnackBarFor(context, "Please select a date");
      return;
    }
    if (_selectedTimeSlot == null) {
      CommonWidget.errorShowSnackBarFor(context, "Please select a time slot");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    try {
      final response = await widget.dataManager.rescheduleBooking(
        context,
        widget.booking.sId.toString(),
        formattedDate,
        _selectedTimeSlot!,
      );

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        if (resBody['status'] == 'success') {
          if (mounted) {
            CommonWidget.successShowSnackBarFor(context, "Booking rescheduled successfully!");
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Failed to reschedule booking: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Reschedule Booking",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: "Pop600",
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: ColorClass.base_color,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select New Date",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Pop600",
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate == null
                                ? "Choose Date"
                                : DateFormat('dd MMM yyyy').format(_selectedDate!),
                            style: const TextStyle(
                              fontSize: 15,
                              fontFamily: "Pop500",
                              color: Colors.black87,
                            ),
                          ),
                          Icon(Icons.calendar_today, color: ColorClass.base_color),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Select New Time Slot",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Pop600",
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.8,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _timeSlots.length,
                      itemBuilder: (context, index) {
                        final slot = _timeSlots[index];
                        final isSelected = _selectedTimeSlot == slot;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedTimeSlot = slot;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? ColorClass.base_color : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? ColorClass.base_color : Colors.grey[300]!,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              slot,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: "Pop500",
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitReschedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorClass.base_color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Confirm Reschedule",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: "Pop600",
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
