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
import 'package:image_picker/image_picker.dart';
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
  ServicesData? selectedService;
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
      print("Error loading services: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          const Text(
            "Choose which service this offer applies to",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
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
          else if (availableServices.length == 0)
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
                final isSelected = selectedService?.sId == service.sId;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedService = service;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected 
                            ? Border.all(color: ColorClass.base_color, width: 2)
                            : null,
                      ),
                      child: Row(
                        children: [
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.serviceTitle ?? "Unknown Service",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  service.description ?? service.about ?? "No description",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "\$${service.price ?? 0}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: ColorClass.base_color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: ColorClass.base_color,
                              size: 24,
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
                  print("🎯 Offer type clicked: ${template.type}");
                  print("🎯 Previous offer type: $offerType");
                  setState(() {
                    offerType = template.type;
                  });
                  print("🎯 New offer type: $offerType");
                  print("🎯 isSelected after tap: ${offerType == template.type}");
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
                          top: 8,
                          right: 8,
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
          
          // Discount Amount
          if (offerType == "percentage" || offerType == "fixed") ...[
            const Text(
              "Discount Amount *",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: offerType == "percentage" ? "20" : "10",
                labelText: offerType == "percentage" ? "Percentage (%)" : "Amount (\$)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(
                  offerType == "percentage" ? Icons.percent : Icons.attach_money,
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
          
          // Valid Until
          const Text(
            "Valid Until *",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: validUntilController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: "Select end date",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.calendar_today),
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
                  validUntilController.text = DateFormat('dd-MM-yyyy').format(date);
                });
              }
            },
          ),
          const SizedBox(height: 20),
          
          // Debug Info (remove in production)
          if (offerType != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                "Debug: Offer Type = $offerType",
                style: const TextStyle(fontSize: 10, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 10),
          ],
          
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
              BaseActivity.showFilePicker(context, (List<File>? list) {
                if (list != null) {
                  for (int i = 0; i < list.length; i++) {
                    if (selectedFiles.isEmpty) {
                      setState(() {
                        selectedFiles.add(list[i]);
                      });
                    } else {
                      CommonWidget.errorShowSnackBarFor(
                        context,
                        "You can only upload 1 offer image.",
                      );
                      break;
                    }
                  }
                }
                print("Selected file count: ${selectedFiles.length}");
              }, isFile: false, isPhoto: true, isOnlyPhoto: true, allowMultipleImage: false);
            },
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedFiles.isNotEmpty ? ColorClass.base_color : Colors.grey[300]!,
                  style: BorderStyle.solid,
                ),
              ),
              child: selectedFiles.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CommonWidget.imageFromFile(
                        selectedFiles[0],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap to upload image",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          if (selectedFiles.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedFiles.length,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(top: 10, left: 10),
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          margin: const EdgeInsets.only(top: 10, left: 10),
                          child: CommonWidget.determineImageAsset(selectedFiles[index].path),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedFiles.removeAt(index);
                                uploadedImageUrl = ""; // Clear uploaded URL when removing image
                              });
                            },
                            child: Image.asset(
                              CommonWidget.getImagePath("delete.png"),
                              height: 25,
                              width: 25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            if (uploadedImageUrl.isEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _uploadImage(context),
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("Upload Image"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorClass.base_color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      "Image uploaded successfully!",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
          ],
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
                              selectedService?.serviceTitle ?? "Service",
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
      CommonWidget.errorShowSnackBarFor(context, "Please select an image first");
      return;
    }
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      List<File> image = [selectedFiles[0]];
      var response = await offerDataManager!.postImage(image, context);
      var data = ImageModuleData.fromJson(jsonDecode(response.body));
      
      Navigator.pop(context); // Close loader
      
      if (data.status == "success") {
        setState(() {
          uploadedImageUrl = data.data?.url ?? "";
        });
        CommonWidget.successShowSnackBarFor(context, "Image uploaded successfully!");
      } else {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to upload image");
      }
    } catch (e) {
      Navigator.pop(context); // Close loader
      CommonWidget.errorShowSnackBarFor(context, "Error uploading image: $e");
    }
  }

  void _nextStep() {
    if (currentStep == 0) {
      if (selectedService == null) {
        CommonWidget.errorShowSnackBarFor(context, "Please select a service");
        return;
      }
    } else if (currentStep == 1) {
      if (titleController.text.isEmpty) {
        CommonWidget.errorShowSnackBarFor(context, "Please enter offer title");
        return;
      }
      if (descriptionController.text.isEmpty) {
        CommonWidget.errorShowSnackBarFor(context, "Please enter offer description");
        return;
      }
      if (offerType == null) {
        CommonWidget.errorShowSnackBarFor(context, "Please select offer type");
        return;
      }
      if ((offerType == "percentage" || offerType == "fixed") && discountController.text.isEmpty) {
        CommonWidget.errorShowSnackBarFor(context, "Please enter discount amount");
        return;
      }
      if (validUntilDate == null) {
        CommonWidget.errorShowSnackBarFor(context, "Please select valid until date");
        return;
      }
      if (selectedFiles.isEmpty) {
        CommonWidget.errorShowSnackBarFor(context, "Please select an offer image");
        return;
      }
      if (uploadedImageUrl.isEmpty) {
        CommonWidget.errorShowSnackBarFor(context, "Please upload the selected image");
        return;
      }
    }
    
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _createOffer() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Create offer with uploaded image URL
      var response = await offerDataManager!.addOffer(
        context,
        titleController.text,
        descriptionController.text,
        discountController.text,
        "", // fromDate - not used in current implementation
        validUntilDate!.toIso8601String(),
        selectedService!.sId!,
        uploadedImageUrl,
      );
      
      Navigator.pop(context); // Close loader
      
      var data = jsonDecode(response.body);
      if (data['status'] == "success") {
        CommonWidget.successShowSnackBarFor(context, "Offer created successfully!");
        Navigator.pop(context, true);
      } else {
        CommonWidget.errorShowSnackBarFor(context, data['message'] ?? "Failed to create offer");
      }
    } catch (e) {
      Navigator.pop(context); // Close loader
      CommonWidget.errorShowSnackBarFor(context, "Error creating offer: $e");
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
    