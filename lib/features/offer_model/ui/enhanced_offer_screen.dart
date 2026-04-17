import 'dart:convert';
import 'dart:io';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/Common/BaseActivity.dart';
import 'package:car_app/features/offer_model/data_manager/offer_data_manager.dart';
import 'package:car_app/features/home_module/model/services_model_data.dart';
import 'package:car_app/Models/image_module_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnhancedOfferScreen extends StatefulWidget {
  const EnhancedOfferScreen({super.key});

  @override
  State<EnhancedOfferScreen> createState() => _EnhancedOfferScreenState();
}

class _EnhancedOfferScreenState extends State<EnhancedOfferScreen> {
  int currentStep = 0;
  final PageController _pageController = PageController();
  
  // Form Controllers
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController discountController = TextEditingController();
  TextEditingController validUntilController = TextEditingController();
  
  // Data
  List<ServicesData> availableServices = [];
  List<ServicesData> selectedServices = [];
  List<File> selectedFiles = [];
  String uploadedImageUrl = "";
  DateTime? validUntilDate;
  String? offerType;
  bool isActive = true;
  
  // Managers
  OfferDataManager? offerDataManager;
  SharedPreferences? sharedPreferences;
  String? vendorId;
  
  // Offer Templates
  final List<OfferTemplate> offerTemplates = [
    OfferTemplate(
      name: "Percentage Discount",
      description: "Offer a percentage off the service price",
      icon: Icons.percent,
      color: Colors.green,
      type: "percentage",
    ),
    OfferTemplate(
      name: "Fixed Amount Off",
      description: "Offer a fixed amount discount",
      icon: Icons.attach_money,
      color: Colors.blue,
      type: "fixed",
    ),
    OfferTemplate(
      name: "Buy One Get One",
      description: "Buy one service, get another free",
      icon: Icons.card_giftcard,
      color: Colors.orange,
      type: "bogo",
    ),
    OfferTemplate(
      name: "First Time Customer",
      description: "Special offer for new customers",
      icon: Icons.person_add,
      color: Colors.purple,
      type: "first_time",
    ),
  ];

  @override
  void initState() {
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    offerDataManager = OfferDataManager(sharedPreferences!);
    vendorId = sharedPreferences!.getString(Constant.vendorId);
    await getAvailableServices();
  }

  Future<void> getAvailableServices() async {
    if (vendorId == null) return;
    
    try {
      var response = await offerDataManager!.getServicesList(context);
      var data = ServicesModelData.fromJson(jsonDecode(response.body));
      
      if (data.status == "success") {
        setState(() {
          availableServices.clear();
          availableServices.addAll(data.data!);
        });
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CommonWidget.buildAppBarBackButton(
          context,
          backgroundColor: Colors.white.withOpacity(0.2),
          iconColor: Colors.white,
        ),
        title: const Text("Create Offer"),
        backgroundColor: ColorClass.base_color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildStepIndicator(0, "Service"),
                Expanded(child: _buildStepLine(0)),
                _buildStepIndicator(1, "Details"),
                Expanded(child: _buildStepLine(1)),
                _buildStepIndicator(2, "Preview"),
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
                _buildServiceSelectionStep(),
                _buildOfferDetailsStep(),
                _buildPreviewStep(),
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
                    onPressed: currentStep < 2 ? _nextStep : _createOffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorClass.base_color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(currentStep < 2 ? "Next" : "Create Offer"),
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

  Widget _buildServiceSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Service",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Choose which service(s) this offer applies to (you can select multiple)",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              if (selectedServices.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ColorClass.base_color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${selectedServices.length} selected",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 30),
          
          if (availableServices.isEmpty)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading services..."),
                ],
              ),
            )
          else if (availableServices.isEmpty)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No services available", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text("Please add some services first", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availableServices.length,
              itemBuilder: (context, index) {
                final service = availableServices[index];
                final isSelected = selectedServices.any((s) => s.sId == service.sId);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected 
                          ? ColorClass.base_color 
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedServices.removeWhere((s) => s.sId == service.sId);
                        } else {
                          selectedServices.add(service);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Checkbox
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  if (!selectedServices.any((s) => s.sId == service.sId)) {
                                    selectedServices.add(service);
                                  }
                                } else {
                                  selectedServices.removeWhere((s) => s.sId == service.sId);
                                }
                              });
                            },
                            activeColor: ColorClass.base_color,
                          ),
                          const SizedBox(width: 8),
                          // Icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: ColorClass.base_color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.local_car_wash,
                              color: ColorClass.base_color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Content - Only Category Name
                          Expanded(
                            child: Text(
                              service.categoryName ?? "Uncategorized",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? ColorClass.base_color : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOfferDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Offer Details",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Define your offer details and terms",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          
          // Offer Type Selection
          const Text(
            "Offer Type",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5, // Further reduced to prevent overflow
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: offerTemplates.length,
            itemBuilder: (context, index) {
              final template = offerTemplates[index];
              final isSelected = offerType == template.type;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    offerType = template.type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? template.color.withOpacity(0.2)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected 
                        ? Border.all(color: template.color, width: 3)
                        : Border.all(color: Colors.grey[300]!),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: template.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ] : null,
                  ),
                  child: Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            template.icon,
                            color: isSelected ? template.color : Colors.grey[600],
                            size: 20, // Reduced icon size
                          ),
                          const SizedBox(height: 6),
                          Text(
                            template.name,
                            style: TextStyle(
                              fontSize: 12, // Reduced font size
                              fontWeight: FontWeight.w600,
                              color: isSelected ? template.color : Colors.black,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            template.description,
                            style: TextStyle(
                              fontSize: 10, // Reduced font size
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      if (isSelected)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: template.color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          
          // Selected Offer Type Indicator
          if (offerType != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: offerTemplates.firstWhere((t) => t.type == offerType).color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: offerTemplates.firstWhere((t) => t.type == offerType).color.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    offerTemplates.firstWhere((t) => t.type == offerType).icon,
                    color: offerTemplates.firstWhere((t) => t.type == offerType).color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Selected: ${offerTemplates.firstWhere((t) => t.type == offerType).name}",
                    style: TextStyle(
                      color: offerTemplates.firstWhere((t) => t.type == offerType).color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
          ],
          
          // Offer Title
          const Text(
            "Offer Title *",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              hintText: "e.g., 20% Off Car Wash",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 15),
          
          // Description
          const Text(
            "Description *",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Describe your offer details...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 15),
          
          // Discount Amount (Optional)
          Row(
            children: [
              const Text(
                "Discount Amount",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "(Optional)",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: discountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: offerType == "percentage" ? "20" : offerType == "fixed" ? "10" : "Enter discount amount",
              labelText: offerType == "percentage" 
                  ? "Percentage (%)" 
                  : offerType == "fixed" 
                      ? "Amount (\$)" 
                      : "Discount Amount",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: Icon(
                offerType == "percentage" 
                    ? Icons.percent 
                    : offerType == "fixed" 
                        ? Icons.attach_money 
                        : Icons.discount,
              ),
            ),
          ),
          const SizedBox(height: 15),
          
          // Valid Until (Optional)
          Row(
            children: [
              const Text(
                "Valid Until",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "(Optional)",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Leave empty if you want the offer to never expire",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: validUntilController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: "Select end date (optional)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.calendar_today),
              suffixIcon: validUntilController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          validUntilDate = null;
                          validUntilController.clear();
                        });
                      },
                    )
                  : null,
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  validUntilDate = date;
                  validUntilController.text = DateFormat(Constant.dateFormatDigits).format(date);
                });
              }
            },
          ),
          const SizedBox(height: 20),
          
          // Image Upload
          const Text(
            "Offer Image",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              BaseActivity.showFilePicker(context, (List<File>? list) async {
                if (list != null && list.isNotEmpty) {
                  if (selectedFiles.isEmpty) {
                    setState(() {
                      selectedFiles.add(list[0]);
                    });
                    // Automatically upload the image when selected
                    await _uploadImage(context);
                  } else {
                    CommonWidget.errorShowSnackBarFor(
                      context,
                      "You can only upload 1 offer image.",
                    );
                  }
                }
              }, isFile: false, isPhoto: true, isOnlyPhoto: true, allowMultipleImage: false);
            },
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedFiles.isNotEmpty && uploadedImageUrl.isNotEmpty
                      ? ColorClass.base_color 
                      : Colors.grey[300]!,
                  width: selectedFiles.isNotEmpty && uploadedImageUrl.isNotEmpty ? 2 : 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: selectedFiles.isNotEmpty
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CommonWidget.imageFromFile(
                            selectedFiles[0],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Upload status indicator
                        if (uploadedImageUrl.isEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Uploading...",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Uploaded",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Remove button
                        Positioned(
                          top: 8,
                          left: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedFiles.clear();
                                uploadedImageUrl = "";
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: ColorClass.base_color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: ColorClass.base_color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Tap to select image",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Image will be uploaded automatically",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPreviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Preview Offer",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Review your offer before creating",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          
          // Offer Preview Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorClass.base_color,
                        ColorClass.base_color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (selectedFiles.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CommonWidget.imageFromFile(
                            selectedFiles[0],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_offer,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleController.text.isNotEmpty 
                                  ? titleController.text 
                                  : "Offer Title",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedServices.isNotEmpty
                                  ? selectedServices.length == 1
                                      ? selectedServices[0].categoryName ?? "Category"
                                      : "${selectedServices.length} categories selected"
                                  : "Category",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Discount Badge
                      if (discountController.text.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.withOpacity(0.5), width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_offer, color: Colors.red, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                offerType == "percentage" 
                                    ? "${discountController.text}% OFF"
                                    : "\$${discountController.text} OFF",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Description
                      Text(
                        descriptionController.text.isNotEmpty 
                            ? descriptionController.text 
                            : "Offer description",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Validity
                      if (validUntilController.text.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                "Valid until: ${validUntilController.text}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.all_inclusive, size: 16, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Text(
                                "No expiration date - offer never expires",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadImage(BuildContext context) async {
    if (selectedFiles.isEmpty) {
      return;
    }
    
    if (!mounted) return;
    
    // Store dialog context to prevent navigation issues
    BuildContext? dialogContext;
    
    try {
      // Show loading indicator
      if (mounted && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogBuildContext) {
            dialogContext = dialogBuildContext;
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      }
      
      List<File> image = [selectedFiles[0]];
      var response = await offerDataManager!.postImage(image, context, skipAutoNavigation: true);
      
      // Close loading indicator using the dialog's context
      if (mounted && dialogContext != null && dialogContext!.mounted) {
        try {
          Navigator.of(dialogContext!).pop();
        } catch (e) {
          // Fallback: try with main context if dialog context fails
          if (mounted && context.mounted && Navigator.of(context).canPop()) {
            try {
              Navigator.of(context).pop();
            } catch (e2) {
            }
          }
        }
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          var data = ImageModuleData.fromJson(jsonDecode(response.body));
          
          if (data.status == "success") {
            if (mounted) {
              setState(() {
                uploadedImageUrl = data.data?.url ?? "";
              });
            }
            if (mounted && context.mounted) {
              CommonWidget.successShowSnackBarFor(context, "Image uploaded successfully!");
            }
          } else {
            if (mounted && context.mounted) {
              CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to upload image");
            }
            // Remove the selected file if upload failed
            if (mounted) {
              setState(() {
                selectedFiles.clear();
              });
            }
          }
        } catch (parseError) {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, "Error processing upload response");
          }
          if (mounted) {
            setState(() {
              selectedFiles.clear();
            });
          }
        }
      } else if (response.statusCode == 401) {
        // Handle 401 without redirecting
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Session expired. Please login again.");
        }
        if (mounted) {
          setState(() {
            selectedFiles.clear();
          });
        }
      } else {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Failed to upload image. Please try again.");
        }
        if (mounted) {
          setState(() {
            selectedFiles.clear();
          });
        }
      }
    } catch (e) {
      
      // Close loading indicator if still open
      if (mounted && dialogContext != null && dialogContext!.mounted) {
        try {
          Navigator.of(dialogContext!).pop();
        } catch (e) {
          if (mounted && context.mounted && Navigator.of(context).canPop()) {
            try {
              Navigator.of(context).pop();
            } catch (e2) {
            }
          }
        }
      }
      
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error uploading image: $e");
      }
      if (mounted) {
        setState(() {
          selectedFiles.clear();
        });
      }
    }
  }

  bool _validateStep(int step) {
    if (step == 0) {
      // Step 0: Service Selection
      if (selectedServices.isEmpty) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Please select at least one service");
        }
        return false;
      }
      return true;
    } else if (step == 1) {
      // Step 1: Offer Details
      
      // Validate Title
      if (titleController.text.trim().isEmpty) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Please enter offer title");
        }
        return false;
      }
      if (titleController.text.trim().length < 3) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Offer title must be at least 3 characters");
        }
        return false;
      }
      if (titleController.text.trim().length > 100) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Offer title must be less than 100 characters");
        }
        return false;
      }
      
      // Validate Description
      if (descriptionController.text.trim().isEmpty) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Please enter offer description");
        }
        return false;
      }
      if (descriptionController.text.trim().length < 10) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Offer description must be at least 10 characters");
        }
        return false;
      }
      if (descriptionController.text.trim().length > 500) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Offer description must be less than 500 characters");
        }
        return false;
      }
      
      // Validate Discount (if provided)
      if (discountController.text.trim().isNotEmpty) {
        final discountValue = double.tryParse(discountController.text.trim());
        if (discountValue == null) {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, "Please enter a valid discount amount");
          }
          return false;
        }
        if (discountValue < 0) {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, "Discount amount cannot be negative");
          }
          return false;
        }
        if (offerType == "percentage" && discountValue > 100) {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, "Percentage discount cannot exceed 100%");
          }
          return false;
        }
      }
      
      // Validate Valid Until Date (if provided)
      if (validUntilDate != null) {
        if (validUntilDate!.isBefore(DateTime.now())) {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, "Valid until date must be in the future");
          }
          return false;
        }
      }
      
      // Validate Image
      if (selectedFiles.isEmpty) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Please select an offer image");
        }
        return false;
      }
      if (uploadedImageUrl.isEmpty) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Please wait for the image to finish uploading");
        }
        return false;
      }
      
      return true;
    } else if (step == 2) {
      // Step 2: Preview - Validate all previous steps silently
      // First check services
      if (selectedServices.isEmpty) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Please select at least one service");
        }
        return false;
      }
      // Then check details (this will show appropriate error message)
      return _validateStep(1);
    }
    return true;
  }

  void _nextStep() {
    if (!_validateStep(currentStep)) {
      return;
    }
    
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _createOffer() async {
    // Validate all steps before creating offer
    if (!_validateStep(0) || !_validateStep(1)) {
      return;
    }
    
    if (!mounted || !context.mounted) return;
    
    BuildContext? dialogContext;
    
    try {
      // Show loading dialog
      if (mounted && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogBuildContext) {
            dialogContext = dialogBuildContext;
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      }
      
      int successCount = 0;
      int failCount = 0;
      
      // Create an offer for each selected service
      for (var service in selectedServices) {
        if (!mounted) break;
        
        try {
          var response = await offerDataManager!.addOffer(
            context,
            titleController.text.trim(),
            descriptionController.text.trim(),
            discountController.text.trim(),
            "", // fromDate - not used in current implementation
            validUntilDate != null ? validUntilDate!.toIso8601String() : "",
            service.sId!,
            uploadedImageUrl,
          );
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            try {
              var data = jsonDecode(response.body);
              if (data['status'] == "success") {
                successCount++;
              } else {
                failCount++;
              }
            } catch (parseError) {
              failCount++;
            }
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
        }
      }
      
      // Close loading dialog safely
      if (mounted) {
        if (dialogContext != null && dialogContext!.mounted) {
          try {
            if (Navigator.of(dialogContext!).canPop()) {
              Navigator.of(dialogContext!).pop();
            }
          } catch (e) {
            // Fallback: try with main context
            if (context.mounted && Navigator.of(context).canPop()) {
              try {
                Navigator.of(context).pop();
              } catch (e2) {
              }
            }
          }
        } else if (context.mounted && Navigator.of(context).canPop()) {
          // Try to pop from main context if dialog context is not available
          try {
            Navigator.of(context).pop();
          } catch (e) {
          }
        }
      }
      
      if (!mounted || !context.mounted) return;
      
      // Show result and navigate
      if (successCount > 0) {
        String message = successCount == selectedServices.length
            ? "All $successCount offer(s) created successfully!"
            : "$successCount of ${selectedServices.length} offer(s) created successfully.";
        if (failCount > 0) {
          message += " $failCount offer(s) failed.";
        }
        CommonWidget.successShowSnackBarFor(context, message);
        
        // Add delay to allow snackbar to show before navigating
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted && context.mounted) {
          // Check if we can pop before navigating back
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          } else {
            // If we can't pop, try using pushAndRemoveUntil or just pop without result
            Navigator.of(context).pop();
          }
        }
      } else {
        CommonWidget.errorShowSnackBarFor(context, "Failed to create offers. Please try again.");
      }
    } catch (e) {
      
      // Close loading dialog if still open
      if (mounted) {
        if (dialogContext != null && dialogContext!.mounted) {
          try {
            if (Navigator.of(dialogContext!).canPop()) {
              Navigator.of(dialogContext!).pop();
            }
          } catch (e) {
            if (context.mounted && Navigator.of(context).canPop()) {
              try {
                Navigator.of(context).pop();
              } catch (e2) {
              }
            }
          }
        } else if (context.mounted && Navigator.of(context).canPop()) {
          try {
            Navigator.of(context).pop();
          } catch (e2) {
          }
        }
      }
      
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error creating offer: $e");
      }
    }
  }
}

class OfferTemplate {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String type;

  OfferTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
  });
}
    