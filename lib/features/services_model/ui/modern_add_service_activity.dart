import 'dart:convert';
import 'dart:io';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/services_model/data_manager/services_data_manager.dart';
import 'package:car_app/features/services_model/model/add_services_bean.dart';
import 'package:car_app/features/services_model/model/services_list_bean.dart';
import 'package:car_app/Models/check_dialog_box.dart';
import 'package:car_app/Models/image_module_data.dart';
import 'package:car_app/features/home_module/model/category_model_data.dart';
import 'package:car_app/features/search_pop_up/search_dialog_with_single_select.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModernAddServiceActivity extends StatefulWidget {
  final ServicesListData? serviceToEdit;
  
  const ModernAddServiceActivity({super.key, this.serviceToEdit});

  @override
  State<ModernAddServiceActivity> createState() => _ModernAddServiceActivityState();
}

class _ModernAddServiceActivityState extends State<ModernAddServiceActivity> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Form controllers
  final TextEditingController _serviceTitleController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Data managers
  ServicesDataManager? servicesDataManager;
  SharedPreferences? sharedPreferences;

  // Selected values
  String _selectedCategory = "Car Wash";
  String _selectedServiceDuration = "0.5hr - 1hr";
  String _selectedCapacity = "5";
  String _selectedMobile = "";

  // Predefined options
  final List<String> _serviceDurations = [
    "0.5hr - 1hr",
    "1hr - 2hr", 
    "2hr - 3hr",
    "3hr - 4hr",
    "4hr - 5hr",
    "More then 5hr",
  ];

  final List<String> _capacityOptions = [
    "1", "2", "3", "4", "5", "6", "10", "10-15", "15-20", "More then 25"
  ];

  List<CategoryData> categoryData = [];
  String categoryId = "";

  // Image handling
  List<File> selectedFiles = [];
  String serviceImage = "";

  final List<String> carWashStatements = [
    "Quick wash, lasting shine!",
    "Refresh your ride today!",
    "Where clean cars happen.",
    "Shine on the move.",
    "Your car's second home.",
    "Drive clean, feel great.",
    "Perfect wash, every time.",
    "Sparkle your journey.",
    "Fast. Fresh. Flawless.",
    "We make cars smile!",
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    servicesDataManager = ServicesDataManager(sharedPreferences!);
    
    // Always clear form first
    _clearForm();
    
    if (widget.serviceToEdit != null) {
      // Populate fields for editing
      _serviceTitleController.text = widget.serviceToEdit!.serviceTitle ?? "";
      _aboutController.text = widget.serviceToEdit!.about ?? "";
      _selectedServiceDuration = widget.serviceToEdit!.serviceDuration ?? "0.5hr - 1hr";
      _selectedCapacity = widget.serviceToEdit!.timeSlotCapacity ?? "5";
      _priceController.text = widget.serviceToEdit!.price?.toString() ?? "0";
      _selectedCategory = widget.serviceToEdit!.categoryName ?? "Car Wash";
      categoryId = widget.serviceToEdit!.categoryId ?? "";
      _selectedMobile = widget.serviceToEdit!.mobile ?? "";
      
      // Set existing image
      serviceImage = widget.serviceToEdit!.coverImage ?? "";
    } else {
      // Default values for new service
      _selectedServiceDuration = "0.5hr - 1hr";
      _selectedCapacity = "5";
      _setRandomText();
    }
    
    getCategory(context);
  }
  
  void _clearForm() {
    // Clear all form fields
    _serviceTitleController.clear();
    _aboutController.clear();
    _priceController.clear();
    _selectedMobile = "";
    serviceImage = "";
    selectedFiles.clear();
    categoryId = "";
    
    // Reset to first step
    _currentStep = 0;
    _pageController.animateToPage(0, 
      duration: const Duration(milliseconds: 300), 
      curve: Curves.easeInOut
    );
  }

  void _setRandomText() {
    final random = DateTime.now().millisecondsSinceEpoch;
    int randomIndex = random % carWashStatements.length;
    _aboutController.text = carWashStatements[randomIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _previousStep,
              )
            : IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          widget.serviceToEdit != null ? "Edit Service" : "Add Service",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildBasicInfoStep(),
                _buildServiceDetailsStep(),
                _buildImagesStep(),
              ],
            ),
          ),
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? ColorClass.base_color
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            "Step ${_currentStep + 1} of $_totalSteps",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Service Information",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tell us about your service",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            _buildInputField(
              controller: _serviceTitleController,
              label: "Service Title",
              icon: Icons.design_services,
              hint: "e.g., Premium Car Wash",
              isRequired: true,
            ),
            const SizedBox(height: 20),
            _buildDropdownField(
              label: "Category",
              value: _selectedCategory,
              options: categoryData.map((cat) => cat.categoryTitle ?? "").toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                  categoryId = categoryData
                      .firstWhere((cat) => cat.categoryTitle == value)
                      .sId
                      .toString();
                });
              },
              icon: Icons.category,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _aboutController,
              label: "Service Description",
              icon: Icons.description,
              hint: "Describe your service...",
              maxLines: 4,
              isRequired: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetailsStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Service Details",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Set up pricing and capacity",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            _buildInputField(
              controller: _priceController,
              label: "Price (₹)",
              icon: Icons.attach_money,
              hint: "0 (Optional)",
              keyboardType: TextInputType.number,
              isRequired: false,
            ),
            const SizedBox(height: 20),
            _buildDropdownField(
              label: "Service Duration",
              value: _selectedServiceDuration,
              options: _serviceDurations,
              onChanged: (value) {
                setState(() {
                  _selectedServiceDuration = value!;
                });
              },
              icon: Icons.schedule,
            ),
            const SizedBox(height: 20),
            _buildDropdownField(
              label: "Capacity per hour",
              value: _selectedCapacity,
              options: _capacityOptions,
              onChanged: (value) {
                setState(() {
                  _selectedCapacity = value!;
                });
              },
              icon: Icons.people,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: TextEditingController(text: _selectedMobile),
              label: "Mobile Number (Optional)",
              icon: Icons.phone,
              hint: "Enter mobile number",
              keyboardType: TextInputType.phone,
              onChanged: (value) => _selectedMobile = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Service Images",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add images to showcase your service",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            _buildImageSection(
              title: "Service Image",
              subtitle: "Upload an image for your service",
              maxImages: 1,
              selectedFiles: selectedFiles,
              onFilesSelected: (files) {
                setState(() {
                  selectedFiles = files;
                });
              },
              existingImage: serviceImage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (isRequired)
              const Text(
                " *",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: ColorClass.base_color),
            hintText: hint ?? "Enter $label",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ColorClass.base_color, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : null,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: ColorClass.base_color),
              hint: Text("Select $label"),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      Icon(icon, color: ColorClass.base_color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection({
    required String title,
    required String subtitle,
    required int maxImages,
    required List<File> selectedFiles,
    required Function(List<File>) onFilesSelected,
    String? existingImage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showImagePicker(maxImages, onFilesSelected),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: ColorClass.base_color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  "Upload Images",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (existingImage != null && existingImage.isNotEmpty || selectedFiles.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _getImageCount(existingImage, selectedFiles),
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildImagePreview(index, existingImage, selectedFiles),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview(int index, String? existingImage, List<File> selectedFiles) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: existingImage != null && existingImage.isNotEmpty && index == 0
            ? Image.network(
                existingImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
              )
            : selectedFiles.isNotEmpty && index < selectedFiles.length
                ? Image.file(selectedFiles[index], fit: BoxFit.cover)
                : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: const Icon(
        Icons.image,
        color: Colors.grey,
        size: 40,
      ),
    );
  }

  int _getImageCount(String? existingImage, List<File> selectedFiles) {
    int count = 0;
    if (existingImage != null && existingImage.isNotEmpty) count++;
    count += selectedFiles.length;
    return count;
  }

  void _showImagePicker(int maxImages, Function(List<File>) onFilesSelected) {
    // This would integrate with your existing image picker
    // For now, we'll use a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Upload Images"),
        content: Text("This will open the image picker to select up to $maxImages images."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual image picker
              CommonWidget.successShowSnackBarFor(context, "Image picker will be implemented here");
            },
            child: const Text("Select Images"),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: ColorClass.base_color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Previous",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep == _totalSteps - 1 ? _saveService : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorClass.base_color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == _totalSteps - 1 
                    ? (widget.serviceToEdit != null ? "Update Service" : "Save Service") 
                    : "Next",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_serviceTitleController.text.isEmpty) {
          CommonWidget.errorShowSnackBarFor(context, "Please enter service title");
          return false;
        }
        if (_selectedCategory.isEmpty) {
          CommonWidget.errorShowSnackBarFor(context, "Please select a category");
          return false;
        }
        if (_aboutController.text.isEmpty) {
          CommonWidget.errorShowSnackBarFor(context, "Please enter service description");
          return false;
        }
        return true;
      case 1:
        // Price is now optional, so no validation needed
        return true;
      case 2:
        return true; // Images are optional
      default:
        return true;
    }
  }

  void _saveService() async {
    if (!_validateCurrentStep()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Upload service image if any
      if (selectedFiles.isNotEmpty) {
        serviceImage = await _postImage(context, selectedFiles);
      }

      var response;
      if (widget.serviceToEdit != null) {
        // Update existing service
        print("🔧 Updating service with ID: ${widget.serviceToEdit!.sId}");
        print("🔧 New title: ${_serviceTitleController.text}");
        print("🔧 New price: ${_priceController.text}");
        print("🔧 New category: $_selectedCategory");
        print("🔧 Service image: $serviceImage");
        
        response = await servicesDataManager?.updateService(
            context,
            widget.serviceToEdit!.sId!,
            _serviceTitleController.text,
            _aboutController.text,
            _selectedCapacity,
            _priceController.text.isEmpty ? "0" : _priceController.text,
            _selectedServiceDuration,
            _selectedCategory,
            categoryId,
            serviceImage,
            _selectedMobile);
      } else {
        // Create new service
        print("🔧 Creating new service with data:");
        print("🔧 Title: ${_serviceTitleController.text}");
        print("🔧 Description: ${_aboutController.text}");
        print("🔧 Capacity: $_selectedCapacity");
        print("🔧 Price: ${_priceController.text.isEmpty ? "0" : _priceController.text}");
        print("🔧 Duration: $_selectedServiceDuration");
        print("🔧 Category: $_selectedCategory");
        print("🔧 Category ID: $categoryId");
        print("🔧 Image: $serviceImage");
        print("🔧 Mobile: $_selectedMobile");
        
        response = await servicesDataManager?.postServies(
            context,
            _serviceTitleController.text,
            _aboutController.text,
            _selectedCapacity,
            _priceController.text.isEmpty ? "0" : _priceController.text,
            _selectedServiceDuration,
            _selectedCategory,
            categoryId,
            serviceImage,
            _selectedMobile);
      }
      
      Navigator.pop(context); // Close loading dialog
      
      print("🔧 API Response Status: ${response.statusCode}");
      print("🔧 API Response Body: ${response.body}");
      
      var data = AddServicesBean.fromJson(jsonDecode(response.body));
      if (data.status == "success") {
        print("✅ Service creation/update successful: ${data.message}");
        print("✅ Service Title: ${_serviceTitleController.text}");
        print("✅ Service Description: ${_aboutController.text}");
        print("✅ Service Price: ${_priceController.text}");
        print("✅ Service Category: $_selectedCategory");
        print("✅ Service Image: $serviceImage");
        CommonWidget.successShowSnackBarFor(context, data.message ?? "");
        Navigator.pop(context, true);
      } else {
        print("❌ Service creation/update failed: ${data.message}");
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      }
      
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      CommonWidget.errorShowSnackBarFor(context, "Error: ${e.toString()}");
    }
  }

  Future<String> _postImage(BuildContext context, List<File> image) async {
    var response = await servicesDataManager!.postImage(image, context);
    var data = ImageModuleData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      return data.data?.url ?? "";
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      return "";
    }
  }

  getCategory(BuildContext context) async {
    var response = await servicesDataManager!.getcategory(context);
    var data = CategoryModelData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        categoryData.clear();
        categoryData.addAll(data.data!);
        if (categoryData.isNotEmpty && _selectedCategory.isEmpty) {
          _selectedCategory = categoryData.first.categoryTitle ?? "";
          categoryId = categoryData.first.sId.toString();
        }
      });
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
}
