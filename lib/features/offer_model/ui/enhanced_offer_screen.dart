import 'dart:convert';
import 'dart:io';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/Common/BaseActivity.dart';
import 'package:car_app/features/offer_model/data_manager/offer_data_manager.dart';
import 'package:car_app/features/home_module/model/services_model_data.dart';
import 'package:car_app/Models/image_module_data.dart';
import 'package:car_app/features/offer_model/model/offer_list_model_bean.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnhancedOfferScreen extends StatefulWidget {
  final OfferListModelData? offerToEdit;
  const EnhancedOfferScreen({super.key, this.offerToEdit});

  @override
  State<EnhancedOfferScreen> createState() => _EnhancedOfferScreenState();
}

class _EnhancedOfferScreenState extends State<EnhancedOfferScreen> {
  // Form Controllers
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController validUntilController = TextEditingController();

  // Data
  List<ServicesData> availableServices = [];
  List<ServicesData> selectedServices = [];
  List<File> selectedFiles = [];
  String uploadedImageUrl = "";
  String? offerType;
  bool isLoadingServices = true;
  DateTime? validUntilDate; // Null means "Forever"

  // Managers
  OfferDataManager? offerDataManager;
  SharedPreferences? sharedPreferences;
  String? vendorId;

  // Offer Templates with predefined text
  final List<OfferTemplate> offerTemplates = [
    OfferTemplate(
      name: "Percentage",
      description: "Percentage off",
      icon: Icons.percent,
      color: Colors.green,
      type: "percentage",
      defaultTitle: "Flash Sale: 20% OFF",
      defaultDescription: "Get an exclusive 20% off our professional car wash services for a limited time!",
    ),
    OfferTemplate(
      name: "Flat Off",
      description: "Fixed amount off",
      icon: Icons.attach_money,
      color: Colors.blue,
      type: "fixed",
      defaultTitle: "Flat \$10 Off",
      defaultDescription: "Save \$10 on your next premium detailing service. Quality care for your vehicle!",
    ),
    OfferTemplate(
      name: "BOGO",
      description: "Buy 1 Get 1",
      icon: Icons.card_giftcard,
      color: Colors.orange,
      type: "bogo",
      defaultTitle: "Buy 1 Get 1 FREE",
      defaultDescription: "Book one interior cleaning and get a basic exterior wash absolutely free!",
    ),
    OfferTemplate(
      name: "New Customer",
      description: "First time deal",
      icon: Icons.person_add,
      color: Colors.purple,
      type: "first_time",
      defaultTitle: "Welcome Offer: 15% Off",
      defaultDescription: "First time at Cahrz? Enjoy a special 15% off your first booking with us.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.offerToEdit != null) {
      titleController.text = widget.offerToEdit!.title ?? "";
      descriptionController.text = widget.offerToEdit!.description ?? "";
      if (widget.offerToEdit!.validUntil != null && widget.offerToEdit!.validUntil!.isNotEmpty) {
        try {
          validUntilDate = DateTime.parse(widget.offerToEdit!.validUntil!);
          validUntilController.text = DateFormat('dd MMM yyyy').format(validUntilDate!);
        } catch (e) {}
      }
      uploadedImageUrl = widget.offerToEdit!.image ?? "";
    }
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

          // Auto-select if editing or only one service is available
          if (widget.offerToEdit != null && widget.offerToEdit!.service != null) {
            try {
              var matchingService = availableServices.firstWhere(
                (s) => s.sId == widget.offerToEdit!.service!.sId,
              );
              selectedServices.clear();
              selectedServices.add(matchingService);
            } catch (e) {
              if (availableServices.isNotEmpty) {
                selectedServices.clear();
                selectedServices.add(availableServices[0]);
              }
            }
          } else if (availableServices.length == 1) {
            selectedServices.clear();
            selectedServices.add(availableServices[0]);
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching services: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoadingServices = false;
        });
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    validUntilController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: CommonWidget.buildAppBarBackButton(
          context,
          backgroundColor: Colors.white.withOpacity(0.2),
          iconColor: Colors.white,
        ),
        title: Text(widget.offerToEdit != null ? "Edit Offer" : "Create Offer",
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: ColorClass.base_color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Image Selection
                  _buildImageSelectionSection(),
                  const SizedBox(height: 30),

                  // 2. Templates
                  const Text(
                    "Quick Templates",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "Pop600"),
                  ),
                  const SizedBox(height: 12),
                  _buildTemplateSelector(),
                  const SizedBox(height: 30),

                  // 3. Form Fields
                  const Text(
                    "Offer Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "Pop600"),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: titleController,
                    label: "Offer Title *",
                    hint: "e.g., 20% Off Car Wash",
                    icon: Icons.title,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: descriptionController,
                    label: "Description",
                    hint: "Describe your offer...",
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  _buildDatePicker(),
                  const SizedBox(height: 30),

                  // 4. Service Selection
                  const Text(
                    "Apply to Services *",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "Pop600"),
                  ),
                  const SizedBox(height: 12),
                  _buildServiceSelectionList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _createOffer,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorClass.base_color,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: ColorClass.base_color.withOpacity(0.4),
              ),
              child: Text(
                widget.offerToEdit != null ? "Update Offer" : "Create Offer",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Offer Image",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "Pop600"),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            BaseActivity.showFilePicker(context, (List<File>? list) async {
              if (list != null && list.isNotEmpty) {
                setState(() {
                  selectedFiles = [list[0]];
                  uploadedImageUrl = ""; // Reset until upload complete
                });
                await _uploadImage(context);
              }
            });
          },
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
            ),
            child: uploadedImageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(uploadedImageUrl, fit: BoxFit.cover),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.5),
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                              onPressed: () {
                                // Re-trigger picker
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : selectedFiles.isNotEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, size: 48, color: ColorClass.base_color),
                          const SizedBox(height: 12),
                          const Text(
                            "Tap to add offer image",
                            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSelector() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: offerTemplates.length,
        itemBuilder: (context, index) {
          final template = offerTemplates[index];
          final isSelected = offerType == template.type;
          return GestureDetector(
            onTap: () {
              setState(() {
                offerType = template.type;
                titleController.text = template.defaultTitle;
                descriptionController.text = template.defaultDescription;
              });
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? template.color.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? template.color : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(template.icon, color: template.color, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    template.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? template.color : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: ColorClass.base_color, size: 20),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ColorClass.base_color, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Valid Until",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: (validUntilDate != null && validUntilDate!.isAfter(DateTime.now())) 
                  ? validUntilDate! 
                  : DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 10)), // Increased range to 10 years
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: ColorClass.base_color,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                validUntilDate = picked;
                validUntilController.text = DateFormat('dd MMM yyyy').format(picked);
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: ColorClass.base_color, size: 20),
                const SizedBox(width: 10),
                Text(
                  validUntilDate == null ? "Forever" : DateFormat('dd MMM yyyy').format(validUntilDate!),
                  style: TextStyle(
                    color: validUntilDate == null ? Colors.grey[500] : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceSelectionList() {
    if (isLoadingServices) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (availableServices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "No services found. Please add services first to create an offer.",
          style: TextStyle(color: Colors.orange),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableServices.map((service) {
        final isSelected = selectedServices.any((s) => s.sId == service.sId);
        return FilterChip(
          label: Text(service.categoryName ?? "Unnamed Service"),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedServices.add(service);
              } else {
                selectedServices.removeWhere((s) => s.sId == service.sId);
              }
            });
          },
          selectedColor: ColorClass.base_color.withOpacity(0.2),
          checkmarkColor: ColorClass.base_color,
          labelStyle: TextStyle(
            color: isSelected ? ColorClass.base_color : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? ColorClass.base_color : Colors.transparent,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _uploadImage(BuildContext context) async {
    if (selectedFiles.isEmpty) return;

    try {
      List<File> image = [selectedFiles[0]];
      var response = await offerDataManager!.postImage(image, context, skipAutoNavigation: true);

      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = ImageModuleData.fromJson(jsonDecode(response.body));
        if (data.status == "success") {
          setState(() {
            uploadedImageUrl = data.data?.url ?? "";
          });
          if (mounted && context.mounted) {
            CommonWidget.successShowSnackBarFor(context, "Image uploaded successfully!");
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to upload image");
          }
        }
      } else {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Upload failed with status: ${response.statusCode}");
        }
      }
    } catch (e) {
      debugPrint("Error uploading image: $e");
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error uploading image: $e");
      }
    }
  }

  bool _validateForm() {
    if (selectedServices.isEmpty) {
      CommonWidget.errorShowSnackBarFor(context, "Please select at least one service");
      return false;
    }
    if (titleController.text.trim().isEmpty) {
      CommonWidget.errorShowSnackBarFor(context, "Please enter offer title");
      return false;
    }
    // Offer validation removed for simplicity
    if (selectedFiles.isNotEmpty && uploadedImageUrl.isEmpty) {
      CommonWidget.errorShowSnackBarFor(context, "Please wait for image upload to complete");
      return false;
    }
    return true;
  }

  Future<void> _createOffer() async {
    if (!_validateForm()) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      int successCount = 0;
      String lastErrorMessage = "Failed to create offers";

      for (var service in selectedServices) {
        var response;
        if (widget.offerToEdit != null) {
          response = await offerDataManager!.editOffer(
            context,
            widget.offerToEdit!.sId!,
            titleController.text.trim(),
            descriptionController.text.trim(),
            "", // No explicit discount for now
            validUntilDate?.toIso8601String() ?? "",
            service.sId!,
            uploadedImageUrl,
          );
        } else {
          response = await offerDataManager!.addOffer(
            context,
            titleController.text.trim(),
            descriptionController.text.trim(),
            "", // No explicit offer value needed anymore
            "",
            validUntilDate?.toIso8601String() ?? "",
            service.sId!,
            uploadedImageUrl,
          );
        }

        if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
          lastErrorMessage = "API Error: Received HTML instead of JSON.";
          continue;
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          var data = jsonDecode(response.body);
          if (data['status'] == "success") {
            successCount++;
          } else {
            lastErrorMessage = data['message'] ?? lastErrorMessage;
          }
        } else {
          lastErrorMessage = "Server returned error: ${response.statusCode}";
        }
      }

      if (mounted) Navigator.of(context).pop(); // Close loading

      if (successCount > 0) {
        if (mounted && context.mounted) {
          CommonWidget.successShowSnackBarFor(context, widget.offerToEdit != null ? "Offer updated successfully!" : "Offer(s) created successfully!");
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, lastErrorMessage);
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
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
  final String defaultTitle;
  final String defaultDescription;

  OfferTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
    required this.defaultTitle,
    required this.defaultDescription,
  });
}
