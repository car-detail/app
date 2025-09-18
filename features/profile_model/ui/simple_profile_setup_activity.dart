import 'dart:convert';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/home_module/data_manager/home_data_manager.dart';
import 'package:car_app/features/dashboard_module/model/vendor_details_main_bean.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleProfileSetupActivity extends StatefulWidget {
  const SimpleProfileSetupActivity({super.key});

  @override
  State<SimpleProfileSetupActivity> createState() => _SimpleProfileSetupActivityState();
}

class _SimpleProfileSetupActivityState extends State<SimpleProfileSetupActivity> {
  int currentStep = 0;
  final PageController _pageController = PageController();
  
  // Business Details
  TextEditingController businessNameController = TextEditingController();
  TextEditingController businessDescriptionController = TextEditingController();
  TextEditingController businessAddressController = TextEditingController();
  TextEditingController businessPhoneController = TextEditingController();
  TextEditingController businessEmailController = TextEditingController();
  
  // Business Hours
  String openingTime = "09:00";
  String closingTime = "18:00";
  List<String> workingDays = [];
  
  // Services
  List<String> selectedServices = [];
  List<String> availableServices = [
    "Car Wash",
    "Oil Change",
    "Tire Service",
    "Brake Service",
    "AC Service",
    "Engine Repair",
    "Transmission Service",
    "Battery Service",
    "Detailing",
    "Paint Job",
  ];
  
  HomeDataManager? dataManager;
  SharedPreferences? sharedPreferences;

  @override
  void initState() {
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = HomeDataManager(sharedPreferences!);
    await loadExistingData();
  }

  Future<void> loadExistingData() async {
    try {
      var response = await dataManager!.getdetails(context);
      var data = VendorDetailsMainBean.fromJson(jsonDecode(response.body));
      if (data.status == "success" && data.data != null) {
        setState(() {
          businessNameController.text = data.data!.businessName ?? "";
          businessDescriptionController.text = data.data!.businessDescription ?? "";
          businessAddressController.text = data.data!.address ?? "";
          businessPhoneController.text = data.data!.phoneNumber ?? "";
          businessEmailController.text = data.data!.email ?? "";
        });
      }
    } catch (e) {
      // Ignore errors, start fresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Setup"),
        backgroundColor: ColorClass.base_color,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildStepIndicator(0, "Basic Info"),
                Expanded(child: _buildStepLine(0)),
                _buildStepIndicator(1, "Hours"),
                Expanded(child: _buildStepLine(1)),
                _buildStepIndicator(2, "Services"),
                Expanded(child: _buildStepLine(2)),
                _buildStepIndicator(3, "Complete"),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentStep = index;
                });
              },
              children: [
                _buildBasicInfoStep(),
                _buildBusinessHoursStep(),
                _buildServicesStep(),
                _buildCompleteStep(),
              ],
            ),
          ),
          
          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (currentStep > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("Previous"),
                    ),
                  ),
                if (currentStep > 0) const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: currentStep < 3 ? _nextStep : _completeSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorClass.base_color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(currentStep < 3 ? "Next" : "Complete Setup"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String title) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: currentStep >= step ? ColorClass.base_color : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "${step + 1}",
              style: TextStyle(
                color: currentStep >= step ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: currentStep >= step ? ColorClass.base_color : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    return Container(
      height: 2,
      color: currentStep > step ? ColorClass.base_color : Colors.grey[300],
    );
  }

  Widget _buildBasicInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Business Information",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Tell us about your business",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          
          // Business Name
          const Text(
            "Business Name *",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: businessNameController,
            decoration: InputDecoration(
              hintText: "e.g., Mike's Auto Service",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 20),
          
          // Business Description
          const Text(
            "Business Description *",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: businessDescriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Describe your business and what makes it special...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 20),
          
          // Business Address
          const Text(
            "Business Address *",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: businessAddressController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Enter your business address...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 20),
          
          // Phone and Email Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Phone Number *",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: businessPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: "+1 (555) 123-4567",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Email *",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: businessEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "business@email.com",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHoursStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Business Hours",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Set your working hours and days",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          
          // Working Days
          const Text(
            "Working Days *",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
            ].map((day) {
              final isSelected = workingDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      workingDays.add(day);
                    } else {
                      workingDays.remove(day);
                    }
                  });
                },
                selectedColor: ColorClass.base_color.withOpacity(0.2),
                checkmarkColor: ColorClass.base_color,
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          
          // Opening and Closing Time
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Opening Time *",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            DateTime.parse("2023-01-01 $openingTime:00"),
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            openingTime = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time),
                            const SizedBox(width: 8),
                            Text(openingTime),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Closing Time *",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            DateTime.parse("2023-01-01 $closingTime:00"),
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            closingTime = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time),
                            const SizedBox(width: 8),
                            Text(closingTime),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Services You Offer",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Select the services you provide to customers",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: availableServices.length,
              itemBuilder: (context, index) {
                final service = availableServices[index];
                final isSelected = selectedServices.contains(service);
                
                return Card(
                  child: CheckboxListTile(
                    title: Text(
                      service,
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedServices.add(service);
                        } else {
                          selectedServices.remove(service);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Setup Complete!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Review your business information",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessNameController.text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    businessDescriptionController.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildInfoRow(Icons.location_on, businessAddressController.text),
                  _buildInfoRow(Icons.phone, businessPhoneController.text),
                  _buildInfoRow(Icons.email, businessEmailController.text),
                  const SizedBox(height: 15),
                  Text(
                    "Working Hours: $openingTime - $closingTime",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "Days: ${workingDays.join(", ")}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Services:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedServices.map((service) {
                      return Chip(
                        label: Text(service),
                        backgroundColor: ColorClass.base_color.withOpacity(0.1),
                        labelStyle: TextStyle(color: ColorClass.base_color),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _nextStep() {
    if (currentStep == 0) {
      if (businessNameController.text.isEmpty || 
          businessDescriptionController.text.isEmpty ||
          businessAddressController.text.isEmpty ||
          businessPhoneController.text.isEmpty ||
          businessEmailController.text.isEmpty) {
        CommonWidget.errorShowSnackBarFor(context, "Please fill all required fields");
        return;
      }
    } else if (currentStep == 1) {
      if (workingDays.isEmpty) {
        CommonWidget.errorShowSnackBarFor(context, "Please select at least one working day");
        return;
      }
    } else if (currentStep == 2) {
      if (selectedServices.isEmpty) {
        CommonWidget.errorShowSnackBarFor(context, "Please select at least one service");
        return;
      }
    }
    
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeSetup() async {
    try {
      CommonWidget.showLoaderDialog(context, "Saving business information...");
      
      // Here you would typically save the data to your backend
      // For now, we'll just show success and navigate back
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      Navigator.pop(context); // Close loader
      CommonWidget.successShowSnackBarFor(context, "Business setup completed successfully!");
      Navigator.pop(context); // Go back to previous screen
    } catch (e) {
      Navigator.pop(context); // Close loader
      CommonWidget.errorShowSnackBarFor(context, "Error saving information: $e");
    }
  }
}
