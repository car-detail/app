import 'dart:convert';
import 'dart:io';
import 'package:car_app/Common/BaseActivity.dart';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/Common/UXHelperWidget.dart';
import 'package:car_app/Common/ModernDesignSystem.dart';
import 'package:car_app/design_system/components/app_header.dart';
import 'package:car_app/design_system/components/bouncy_tap.dart';
import 'package:car_app/design_system/components/staggered_fade_in.dart';
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
  final TextEditingController _mobileController = TextEditingController();

  // Data managers
  ServicesDataManager? servicesDataManager;
  SharedPreferences? sharedPreferences;

  // Selected values
  String _selectedCategory = "Car Wash";
  String _selectedServiceDuration = "0.5hr - 1hr";
  String _selectedCapacity = "5";

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
  List<CategoryData> filteredCategoryData = []; // Categories filtered to exclude those with existing services
  String categoryId = "";
  
  // Existing services to check which categories are already used
  List<ServicesListData> existingServices = [];

  // Image handling
  List<File> selectedFiles = [];
  String serviceImage = "";
  List<String> detailImages = [];
  List<File> selectedDetailFiles = [];

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
      _mobileController.text = widget.serviceToEdit!.mobile ?? "";
      
      // Set existing image
      serviceImage = widget.serviceToEdit!.coverImage ?? "";
      detailImages = widget.serviceToEdit!.detailImages ?? [];
    } else {
      // Default values for new service
      _selectedServiceDuration = "0.5hr - 1hr";
      _selectedCapacity = "5";
      _mobileController.text = sharedPreferences?.getString(Constant.mobile) ?? "";
      _setRandomText();
    }
    
    // Fetch categories and existing services
    await getCategory(context);
    await _fetchExistingServices(context);
    _filterCategories();
  }
  
  void _clearForm() {
    // Clear all form fields
    _serviceTitleController.clear();
    _aboutController.clear();
    _priceController.clear();
    _mobileController.clear();
    serviceImage = "";
    detailImages = [];
    selectedFiles.clear();
    selectedDetailFiles.clear();
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppHeader(
        title: widget.serviceToEdit != null ? "Edit Service" : "Add Service",
        subtitle: widget.serviceToEdit != null
            ? "Update your service details"
            : "Let's get your service listed",
        onBack: _currentStep > 0 ? _previousStep : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              // Steps must only be reachable through _nextStep()/_previousStep(),
              // which run _validateCurrentStep() -- free swiping let users skip
              // straight past required fields with no validation at all.
              physics: const NeverScrollableScrollPhysics(),
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

  static const _stepIcons = [
    Icons.edit_note_rounded,
    Icons.tune_rounded,
    Icons.photo_library_rounded,
  ];
  static const _stepLabels = ["Basics", "Details", "Photos"];

  Widget _buildProgressIndicator() {
    final accent = ModernDesignSystem.accentFor(1); // indigo, services identity
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      color: Colors.white,
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            final leftDone = (i - 1) ~/ 2 < _currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: leftDone ? accent : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          final index = i ~/ 2;
          final isDone = index < _currentStep;
          final isCurrent = index == _currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isCurrent ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: (isDone || isCurrent) ? ModernDesignSystem.brandGradient : null,
                    color: (isDone || isCurrent) ? null : Colors.grey[200],
                    boxShadow: isCurrent
                        ? ModernDesignSystem.getColoredShadow(accent, opacity: 0.35)
                        : null,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isDone ? Icons.check_rounded : _stepIcons[index],
                      key: ValueKey(isDone),
                      color: (isDone || isCurrent) ? Colors.white : Colors.grey[500],
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _stepLabels[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent ? accent : Colors.grey[500],
                ),
              ),
            ],
          );
        }),
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
            // Welcome Banner
            StaggeredFadeIn(
              child: UXHelperWidget.buildInfoBanner(
                iconColor: ModernDesignSystem.accentFor(1),
                message: widget.serviceToEdit != null
                    ? "Update your service information below. You can change anything anytime!"
                    : "Let's add your service! Just fill in the basic details. We'll help you every step of the way.",
                icon: widget.serviceToEdit != null ? Icons.edit_outlined : Icons.info_outline,
              ),
            ),
            const SizedBox(height: 30),
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 80),
              child: UXHelperWidget.buildHelpfulInputField(
                accentColor: ModernDesignSystem.accentFor(1),
                context: context,
                controller: _serviceTitleController,
                label: "Service Name",
                icon: Icons.design_services,
                helpText: "Give your service a clear and descriptive name, like 'Basic Car Wash' or 'Premium Interior Detailing'. This is what customers will see.",
                example: "Basic Car Wash",
                isRequired: true,
              ),
            ),
            const SizedBox(height: 20),
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 160),
              child: _buildCategoryDropdown(),
            ),
            const SizedBox(height: 20),
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 240),
              child: UXHelperWidget.buildHelpfulInputField(
                accentColor: ModernDesignSystem.accentFor(1),
                context: context,
                controller: _aboutController,
                label: "Service Description",
                icon: Icons.description,
                helpText: "Briefly describe what this service includes. Keep it simple and clear so customers know what to expect.",
                example: "Complete exterior wash with soap and water",
                maxLines: 4,
                isRequired: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Service Type *",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                UXHelperWidget.showHelpDialog(
                  context,
                  title: "Service Type",
                  message: "What type of service is this? Choose the category that best matches your service.",
                  example: "Car Wash, Car Detailing, etc.",
                );
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: ColorClass.base_color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline,
                  size: 14,
                  color: ColorClass.base_color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: filteredCategoryData.any((cat) => cat.categoryTitle == _selectedCategory) ? _selectedCategory : null,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF192028)),
              hint: const Text("Select service type", style: TextStyle(color: Colors.grey)),
              items: filteredCategoryData.map((CategoryData cat) {
                return DropdownMenuItem<String>(
                  value: cat.categoryTitle ?? "",
                  child: Text(
                    cat.categoryTitle ?? "",
                    style: const TextStyle(fontSize: 15),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                    categoryId = filteredCategoryData
                        .firstWhere((cat) => cat.categoryTitle == value)
                        .sId
                        .toString();
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceDetailsStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredFadeIn(
              child: UXHelperWidget.buildInfoBanner(
                iconColor: ModernDesignSystem.accentFor(1),
                message: "Set up pricing and capacity for your service. Don't worry, you can change these later.",
                icon: Icons.settings_outlined,
              ),
            ),
            const SizedBox(height: 30),
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 80),
              child: UXHelperWidget.buildHelpfulInputField(
                accentColor: ModernDesignSystem.accentFor(1),
                context: context,
                controller: _priceController,
                label: "Price",
                icon: Icons.attach_money,
                helpText: "How much do you charge for this service? Enter just the number. You can leave this empty and set it later.",
                example: "25",
                hintText: "e.g., 25 (Optional)",
                keyboardType: TextInputType.number,
                isRequired: false,
              ),
            ),
            const SizedBox(height: 20),
            StaggeredFadeIn(delay: const Duration(milliseconds: 160), child: _buildDurationDropdown()),
            const SizedBox(height: 20),
            StaggeredFadeIn(delay: const Duration(milliseconds: 240), child: _buildCapacityDropdown()),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDurationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Service Duration *",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                UXHelperWidget.showHelpDialog(
                  context,
                  title: "Service Duration",
                  message: "How long does it take to complete this service? This helps customers plan their visit.",
                  example: "0.5hr - 1hr for a basic wash",
                );
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: ColorClass.base_color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline,
                  size: 14,
                  color: ColorClass.base_color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildDropdownField(
          value: _selectedServiceDuration,
          options: _serviceDurations,
          onChanged: (value) {
            setState(() {
              _selectedServiceDuration = value!;
            });
          },
          icon: Icons.schedule,
        ),
      ],
    );
  }
  
  Widget _buildCapacityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "How many cars can you handle at once? *",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                UXHelperWidget.showHelpDialog(
                  context,
                  title: "Capacity",
                  message: "How many cars can you service at the same time? This helps us manage bookings better.",
                  example: "If you can wash 5 cars at once, select 5",
                );
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: ColorClass.base_color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline,
                  size: 14,
                  color: ColorClass.base_color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildDropdownField(
          value: _selectedCapacity,
          options: _capacityOptions,
          onChanged: (value) {
            setState(() {
              _selectedCapacity = value!;
            });
          },
          icon: Icons.directions_car,
        ),
      ],
    );
  }

  Widget _buildImagesStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredFadeIn(
              child: UXHelperWidget.buildInfoBanner(
                iconColor: ModernDesignSystem.accentFor(1),
                message: "Add a cover image for your service. This helps customers see what to expect. You can skip this and add it later.",
                icon: Icons.image_outlined,
              ),
            ),
            const SizedBox(height: 30),
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 100),
              child: _buildImageSection(
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
            ),
            const SizedBox(height: 30),
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 200),
              child: _buildImageSection(
                title: "Service Gallery (Optional)",
                subtitle: "Upload multiple images showing your work",
                maxImages: 10,
                selectedFiles: selectedDetailFiles,
                onFilesSelected: (files) {
                  setState(() {
                    selectedDetailFiles = files;
                  });
                  _uploadSelectedImage(isDetailImage: true);
                },
                existingImages: detailImages,
                isMultiple: true,
              ),
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
    String? label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : null,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF192028)),
              hint: Text("Select $label", style: const TextStyle(color: Colors.grey)),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: const TextStyle(fontSize: 15),
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
    List<String>? existingImages,
    bool isMultiple = false,
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
          onTap: () => _pickAndUploadImage(maxImages, onFilesSelected, isDetailImage: isMultiple),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: ColorClass.base_color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  "Upload Images",
                  style: TextStyle(
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
        if (serviceImage.isNotEmpty || selectedFiles.isNotEmpty || detailImages.isNotEmpty || selectedDetailFiles.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: isMultiple 
                  ? detailImages.length + selectedDetailFiles.length
                  : (serviceImage.isNotEmpty ? 1 : 0) + selectedFiles.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: isMultiple
                      ? _buildDetailImagePreview(index)
                      : _buildImagePreview(index, serviceImage, selectedFiles),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview(int index, String? existingImage, List<File> selectedFiles) {
    // If we have an uploaded image URL, show that first
    bool hasUploadedImage = existingImage != null && existingImage.isNotEmpty;
    bool isUploadedImage = hasUploadedImage && index == 0;
    bool isSelectedFile = !isUploadedImage && selectedFiles.isNotEmpty && 
                         (hasUploadedImage ? index - 1 < selectedFiles.length : index < selectedFiles.length);
    
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isUploadedImage
                ? Image.network(
                    existingImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                  )
                : isSelectedFile
                    ? CommonWidget.imageFromFile(
                        selectedFiles[hasUploadedImage ? index - 1 : index], 
                        fit: BoxFit.cover
                      )
                    : _buildImagePlaceholder(),
          ),
        ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isUploadedImage) {
                  serviceImage = "";
                } else if (isSelectedFile) {
                  int fileIndex = hasUploadedImage ? index - 1 : index;
                  if (fileIndex >= 0 && fileIndex < selectedFiles.length) {
                    selectedFiles.removeAt(fileIndex);
                  }
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailImagePreview(int index) {
    bool isExisting = index < detailImages.length;
    
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isExisting
                ? Image.network(
                    detailImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                  )
                : CommonWidget.imageFromFile(
                    selectedDetailFiles[index - detailImages.length], 
                    fit: BoxFit.cover
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isExisting) {
                  detailImages.removeAt(index);
                } else {
                  selectedDetailFiles.removeAt(index - detailImages.length);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
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
  
  // Get image count for display
  int _getImageCountForDisplay() {
    int count = 0;
    if (serviceImage.isNotEmpty) count++;
    count += selectedFiles.length;
    return count;
  }

  void _pickAndUploadImage(int maxImages, Function(List<File>) onFilesSelected, {bool isDetailImage = false}) async {
    // Show image picker dialog
    BaseActivity.showFilePicker(
      context,
      (List<File>? files) async {
        if (files != null && files.isNotEmpty) {
          // Limit to maxImages
          List<File> selectedFilesList = files.take(maxImages).toList();
          
          if (isDetailImage) {
            setState(() {
              selectedDetailFiles.clear();
              selectedDetailFiles.addAll(selectedFilesList);
            });
            await _uploadSelectedImage(isDetailImage: true);
          } else {
            setState(() {
              selectedFiles.clear();
              selectedFiles.addAll(selectedFilesList);
            });
            await _uploadSelectedImage();
          }
        }
      },
      isFile: false,
      isPhoto: true,
      isOnlyPhoto: true,
      allowMultipleImage: maxImages > 1,
    );
  }

  Future<void> _uploadSelectedImage({bool isDetailImage = false}) async {
    List<File> filesToUpload = isDetailImage ? selectedDetailFiles : selectedFiles;

    if (filesToUpload.isEmpty) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Please select an image first");
      }
      return;
    }
    
    if (!mounted || !context.mounted) return;
    
    // Store dialog context to prevent navigation issues
    BuildContext? dialogContext;
    
    try {
      // Check if access token exists before uploading
      String? accessToken = sharedPreferences?.getString(Constant.accessToken);
      if (accessToken == null || accessToken.isEmpty) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Session expired. Please login again.");
        }
        return;
      }
      
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
      
      if (isDetailImage) {
        // Upload multiple images
        List<String> uploadedUrls = [];
        for (var file in filesToUpload) {
          String url = await _postImage(context, [file]);
          if (url.isNotEmpty) uploadedUrls.add(url);
        }
        
        if (mounted && dialogContext != null && dialogContext!.mounted) {
           Navigator.of(dialogContext!).pop();
        }

        if (uploadedUrls.isNotEmpty) {
          setState(() {
            detailImages.addAll(uploadedUrls);
            selectedDetailFiles.clear();
          });
          CommonWidget.successShowSnackBarFor(context, "${uploadedUrls.length} image(s) uploaded successfully!");
        } else {
          CommonWidget.errorShowSnackBarFor(context, "Failed to upload images");
        }
      } else {
        // Upload single cover image
        String uploadedUrl = await _postImage(context, [filesToUpload[0]]);
        
        if (mounted && dialogContext != null && dialogContext!.mounted) {
           Navigator.of(dialogContext!).pop();
        }

        if (uploadedUrl.isNotEmpty) {
          setState(() {
            serviceImage = uploadedUrl;
            selectedFiles.clear();
          });
          CommonWidget.successShowSnackBarFor(context, "Cover image uploaded successfully!");
        } else {
          CommonWidget.errorShowSnackBarFor(context, "Failed to upload image");
        }
      }
    } catch (e) {
      // Close loading dialog on error
      if (mounted && dialogContext != null && dialogContext!.mounted) {
        try {
          Navigator.of(dialogContext!).pop();
        } catch (e2) {
          // Fallback: try with main context if dialog context fails
          if (mounted && context.mounted && Navigator.of(context).canPop()) {
            try {
              Navigator.of(context).pop();
            } catch (e3) {
            }
          }
        }
      }
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error uploading image: ${e.toString()}");
      }
    }
  }

  Widget _buildNavigationButtons() {
    final accent = ModernDesignSystem.accentFor(1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: BouncyTap(
                onTap: _previousStep,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ModernDesignSystem.radiusRound),
                    border: Border.all(color: accent, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Previous",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: BouncyTap(
              onTap: _currentStep == _totalSteps - 1 ? _saveService : _nextStep,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: ModernDesignSystem.brandGradient,
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusRound),
                  boxShadow: ModernDesignSystem.getColoredShadow(ColorClass.base_color, opacity: 0.3),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentStep == _totalSteps - 1
                          ? (widget.serviceToEdit != null ? "Update" : "Save")
                          : "Next",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _currentStep == _totalSteps - 1
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
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
      // Upload service image if any new files selected (not already uploaded)
      if (selectedFiles.isNotEmpty && serviceImage.isEmpty) {
        if (!mounted || !context.mounted) return;
        serviceImage = await _postImage(context, [selectedFiles[0]]);
        if (!mounted || !context.mounted) return;
      }

      var response;
      if (widget.serviceToEdit != null) {
        // Update existing service
        
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
            detailImages,
            _mobileController.text);
      } else {
        // Create new service
        
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
            detailImages,
            _mobileController.text);
      }
      
      if (!mounted || !context.mounted) return;
      
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }
      
      
      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        return;
      }
      
      // Check response status code
      if (response.statusCode != 200 && response.statusCode != 201) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to save service. Please check your connection and try again.");
        }
        return;
      }
      
      try {
        var data = AddServicesBean.fromJson(jsonDecode(response.body));
        if (data.status == "success") {
          if (mounted && context.mounted) {
            // Show success message
            CommonWidget.successShowSnackBarFor(context, data.message ?? "Service saved successfully!");
            // Wait a bit for the snackbar to show, then pop the screen
            await Future.delayed(const Duration(milliseconds: 500));
            // Ensure we're still mounted and can pop
            if (mounted && context.mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop(true);
            }
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to save service. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error parsing response. Please try again.");
        }
      }
      
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error saving service. Please check your connection and try again.");
      }
    }
  }

  Future<String> _postImage(BuildContext context, List<File> image) async {
    if (!mounted || !context.mounted) return "";
    
    var response = await servicesDataManager!.postImage(
      image,
      context,
      skipAutoNavigation: true, // Prevent auto-navigation
    );
    
    // Check if response is HTML (error page) instead of JSON
    if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
      }
      return "";
    }
    
    if (response.statusCode == 401) {
      // Handle 401 without navigating away
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Session expired. Please login again.");
      }
      return "";
    }
    
    try {
      var data = ImageModuleData.fromJson(jsonDecode(response.body));
      if (data.status == "success") {
        return data.data?.url ?? "";
      } else {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to upload image");
        }
        return "";
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error parsing upload response");
      }
      return "";
    }
  }

  getCategory(BuildContext context) async {
    var response = await servicesDataManager!.getcategory(context);
    
    if (!mounted) return;
    
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
      // Filter categories after loading
      _filterCategories();
    } else {
      if (context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      }
    }
  }

  Future<void> _fetchExistingServices(BuildContext context) async {
    try {
      var response = await servicesDataManager!.getServicesList(context);
      
      if (!mounted) return;
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = ServicesListBean.fromJson(jsonDecode(response.body));
        if (data.status == "success" && data.data != null) {
          setState(() {
            existingServices = data.data!;
          });
          // Re-filter categories after fetching services
          _filterCategories();
        }
      }
    } catch (e) {
      // Don't show error to user, just continue with all categories
    }
  }

  void _filterCategories() {
    if (categoryData.isEmpty) return;
    
    // Get set of category IDs that already have services
    Set<String> usedCategoryIds = {};
    for (var service in existingServices) {
      // Skip the service being edited (if any)
      if (widget.serviceToEdit != null && service.sId == widget.serviceToEdit!.sId) {
        continue;
      }
      if (service.categoryId != null && service.categoryId!.isNotEmpty) {
        usedCategoryIds.add(service.categoryId!);
      }
      // Also check by category name as fallback
      if (service.categoryName != null && service.categoryName!.isNotEmpty) {
        var matchingCategory = categoryData.firstWhere(
          (cat) => cat.categoryTitle == service.categoryName,
          orElse: () => CategoryData(sId: "", categoryTitle: ""),
        );
        if (matchingCategory.sId != null && matchingCategory.sId!.isNotEmpty) {
          usedCategoryIds.add(matchingCategory.sId!);
        }
      }
    }
    
    // Filter categories: exclude those with existing services, but always include the currently selected one (if editing)
    setState(() {
      filteredCategoryData = categoryData.where((category) {
        // If editing and this is the current category, always include it
        if (widget.serviceToEdit != null && 
            (category.sId == widget.serviceToEdit!.categoryId || 
             category.categoryTitle == widget.serviceToEdit!.categoryName)) {
          return true;
        }
        // Otherwise, exclude if it's already used
        if (category.sId == null || category.sId!.isEmpty) return false;
        return !usedCategoryIds.contains(category.sId);
      }).toList();
      
      // If current selection is not in filtered list (shouldn't happen when editing), reset it
      if (filteredCategoryData.isNotEmpty && 
          !filteredCategoryData.any((cat) => cat.categoryTitle == _selectedCategory)) {
        _selectedCategory = filteredCategoryData.first.categoryTitle ?? "";
        categoryId = filteredCategoryData.first.sId?.toString() ?? "";
      }
    });
  }
}
