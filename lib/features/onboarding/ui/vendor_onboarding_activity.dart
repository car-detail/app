import 'dart:convert';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:car_app/features/log_in/data_manager/LoginDataManager.dart';
import 'package:car_app/features/resister_vendor_model/datamanager/add_shop_data_manager.dart';
import 'package:car_app/features/services_model/data_manager/services_data_manager.dart';
import 'package:car_app/features/packages_model/data_manager/package_data_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorOnboardingActivity extends StatefulWidget {
  const VendorOnboardingActivity({super.key});

  @override
  State<VendorOnboardingActivity> createState() => _VendorOnboardingActivityState();
}

class _VendorOnboardingActivityState extends State<VendorOnboardingActivity> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _shopMobileController = TextEditingController();
  final TextEditingController _shopEmailController = TextEditingController();

  // Data managers
  LoginDataManager? loginDataManager;
  AddShopDataManager? vendorDataManager;
  ServicesDataManager? servicesDataManager;
  PackageDataManager? packageDataManager;
  SharedPreferences? sharedPreferences;

  // Selected values
  String _selectedBusinessType = "Car Wash";
  String _selectedLocation = "";
  List<String> _selectedServices = [];
  List<String> _selectedPackages = [];

  // Predefined templates
  final List<BusinessTypeTemplate> _businessTypes = [
    BusinessTypeTemplate(
      name: "Car Wash",
      icon: Icons.local_car_wash,
      color: Colors.blue,
      description: "Complete car cleaning services",
      services: ["Basic Wash", "Premium Wash", "Waxing", "Interior Cleaning"],
      packages: ["Basic Package", "Premium Package", "Ultra Package"],
    ),
    BusinessTypeTemplate(
      name: "Auto Repair",
      icon: Icons.build,
      color: Colors.orange,
      description: "Vehicle maintenance and repair",
      services: ["Oil Change", "Brake Service", "Engine Repair", "Tire Service"],
      packages: ["Maintenance Package", "Repair Package", "Complete Service"],
    ),
    BusinessTypeTemplate(
      name: "Detailing",
      icon: Icons.cleaning_services,
      color: Colors.green,
      description: "Professional vehicle detailing",
      services: ["Paint Correction", "Ceramic Coating", "Interior Detailing", "Paint Protection"],
      packages: ["Basic Detail", "Premium Detail", "Ultra Detail"],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    loginDataManager = LoginDataManager(sharedPreferences!);
    vendorDataManager = AddShopDataManager(sharedPreferences!);
    servicesDataManager = ServicesDataManager(sharedPreferences!);
    packageDataManager = PackageDataManager(sharedPreferences!);
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
            : null,
        title: Text(
          "Setup Your Business",
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
                _buildWelcomeStep(),
                _buildPersonalInfoStep(),
                _buildBusinessInfoStep(),
                _buildServicesStep(),
                _buildCompleteStep(),
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

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: ColorClass.base_color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business,
              size: 80,
              color: ColorClass.base_color,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Welcome to Cahrz!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Let's get your business set up in just a few simple steps. We'll help you create your profile, add your shop details, and set up your services.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildFeatureCard(
            Icons.person,
            "Personal Profile",
            "Set up your basic information",
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            Icons.store,
            "Shop Details",
            "Add your business location and contact",
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            Icons.design_services,
            "Services & Packages",
            "Create your service offerings",
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Personal Information",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tell us about yourself",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            _buildInputField(
              controller: _firstNameController,
              label: "First Name",
              icon: Icons.person,
              isRequired: true,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _lastNameController,
              label: "Last Name",
              icon: Icons.person,
              isRequired: true,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _emailController,
              label: "Email Address",
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              isRequired: true,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _mobileController,
              label: "Mobile Number",
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              isRequired: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Business Information",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Set up your business profile",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            // Business Type Selection
            const Text(
              "What type of business do you run?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ..._businessTypes.map((type) => _buildBusinessTypeCard(type)),
            const SizedBox(height: 30),
            _buildInputField(
              controller: _shopNameController,
              label: "Shop/Business Name",
              icon: Icons.store,
              isRequired: true,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _shopAddressController,
              label: "Business Address",
              icon: Icons.location_on,
              maxLines: 3,
              isRequired: true,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _shopMobileController,
              label: "Business Phone",
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _shopEmailController,
              label: "Business Email",
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesStep() {
    final selectedTemplate = _businessTypes.firstWhere(
      (type) => type.name == _selectedBusinessType,
      orElse: () => _businessTypes.first,
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Services & Packages",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Select the services you want to offer",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            // Services Selection
            const Text(
              "Services",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: selectedTemplate.services.map((service) {
                final isSelected = _selectedServices.contains(service);
                return _buildServiceChip(service, isSelected, () {
                  setState(() {
                    if (isSelected) {
                      _selectedServices.remove(service);
                    } else {
                      _selectedServices.add(service);
                    }
                  });
                });
              }).toList(),
            ),
            const SizedBox(height: 30),
            // Packages Selection
            const Text(
              "Packages",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: selectedTemplate.packages.map((package) {
                final isSelected = _selectedPackages.contains(package);
                return _buildServiceChip(package, isSelected, () {
                  setState(() {
                    if (isSelected) {
                      _selectedPackages.remove(package);
                    } else {
                      _selectedPackages.add(package);
                    }
                  });
                });
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "You're All Set!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Your business profile has been created successfully. You can now start accepting bookings and managing your services.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
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
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: ColorClass.base_color),
            hintText: "Enter $label",
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

  Widget _buildBusinessTypeCard(BusinessTypeTemplate template) {
    final isSelected = _selectedBusinessType == template.name;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedBusinessType = template.name;
            _selectedServices.clear();
            _selectedPackages.clear();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? template.color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? template.color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: template.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(template.icon, color: template.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? template.color : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: template.color,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceChip(String name, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ColorClass.base_color : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ColorClass.base_color : Colors.grey[300]!,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Summary",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow("Business Type", _selectedBusinessType),
          _buildSummaryRow("Shop Name", _shopNameController.text),
          _buildSummaryRow("Services", "${_selectedServices.length} selected"),
          _buildSummaryRow("Packages", "${_selectedPackages.length} selected"),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
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
              onPressed: _currentStep == _totalSteps - 1 ? _completeOnboarding : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorClass.base_color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? "Complete Setup" : "Next",
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
        return true; // Welcome step
      case 1:
        if (_firstNameController.text.isEmpty ||
            _lastNameController.text.isEmpty ||
            _emailController.text.isEmpty ||
            _mobileController.text.isEmpty) {
          CommonWidget.errorShowSnackBarFor(context, "Please fill in all required fields");
          return false;
        }
        return true;
      case 2:
        if (_shopNameController.text.isEmpty || _shopAddressController.text.isEmpty) {
          CommonWidget.errorShowSnackBarFor(context, "Please fill in shop name and address");
          return false;
        }
        return true;
      case 3:
        if (_selectedServices.isEmpty) {
          CommonWidget.errorShowSnackBarFor(context, "Please select at least one service");
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _completeOnboarding() async {
    if (!_validateCurrentStep()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Create user profile
      await _createUserProfile();
      
      // Create vendor shop
      await _createVendorShop();
      
      // Create services
      await _createServices();
      
      // Create packages
      await _createPackages();

      Navigator.pop(context); // Close loading dialog
      
      CommonWidget.successShowSnackBarFor(context, "Onboarding completed successfully!");
      
      // Navigate to main dashboard
      CommonWidget.navigateToKillAllScreen(context, const DashboardActivity());
      
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      CommonWidget.errorShowSnackBarFor(context, "Error: ${e.toString()}");
    }
  }

  Future<void> _createUserProfile() async {
    // Implementation for creating user profile
    // This would call the appropriate API
  }

  Future<void> _createVendorShop() async {
    // Implementation for creating vendor shop
    // This would call the appropriate API
  }

  Future<void> _createServices() async {
    // Implementation for creating services
    // This would call the appropriate API
  }

  Future<void> _createPackages() async {
    // Implementation for creating packages
    // This would call the appropriate API
  }
}

class BusinessTypeTemplate {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> services;
  final List<String> packages;

  BusinessTypeTemplate({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.services,
    required this.packages,
  });
}
