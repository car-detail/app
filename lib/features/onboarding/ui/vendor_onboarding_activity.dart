import 'dart:convert';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/Common/UXHelperWidget.dart';
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
    final stepLabels = ["Welcome", "Your Info", "Business", "Services"];
    return UXHelperWidget.buildStepIndicator(
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      stepLabels: stepLabels,
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
            "Let's get your business online in just 4 simple steps! Don't worry - we'll guide you through everything.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          UXHelperWidget.buildInfoBanner(
            message: "💡 Tip: Look for the (?) help icons if you need assistance at any step!",
            icon: Icons.lightbulb_outline,
            backgroundColor: Colors.amber[50],
            iconColor: Colors.amber[700],
          ),
          const SizedBox(height: 30),
          _buildFeatureCard(
            Icons.person,
            "Step 1: Personal Profile",
            "Tell us your name and contact details",
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            Icons.store,
            "Step 2: Shop Details",
            "Add your business name and location",
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            Icons.design_services,
            "Step 3: Services",
            "Select what services you offer",
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            Icons.check_circle,
            "Step 4: You're Done!",
            "Start accepting bookings right away",
            Colors.purple,
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
              "Tell us about yourself - This helps customers contact you",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            UXHelperWidget.buildInfoBanner(
              message: "Don't worry! This information is safe and only used for your business profile.",
              icon: Icons.lock_outline,
              backgroundColor: Colors.green[50],
              iconColor: Colors.green[700],
            ),
            const SizedBox(height: 20),
            UXHelperWidget.buildHelpfulInputField(
              controller: _firstNameController,
              label: "First Name",
              icon: Icons.person,
              helpText: "Enter your first name as you want customers to see it",
              example: "John",
              isRequired: true,
              context: context,
            ),
            const SizedBox(height: 20),
            UXHelperWidget.buildHelpfulInputField(
              controller: _lastNameController,
              label: "Last Name",
              icon: Icons.person,
              helpText: "Enter your last name or family name",
              example: "Smith",
              isRequired: true,
              context: context,
            ),
            const SizedBox(height: 20),
            UXHelperWidget.buildHelpfulInputField(
              controller: _emailController,
              label: "Email Address",
              icon: Icons.email,
              helpText: "Enter your email address. We'll send important updates here.",
              example: "john.smith@example.com",
              keyboardType: TextInputType.emailAddress,
              isRequired: true,
              context: context,
            ),
            const SizedBox(height: 20),
            UXHelperWidget.buildHelpfulInputField(
              controller: _mobileController,
              label: "Mobile Number",
              icon: Icons.phone,
              helpText: "Enter your mobile number with country code. Customers can call you on this number.",
              example: "+1234567890",
              keyboardType: TextInputType.phone,
              isRequired: true,
              context: context,
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
              "Set up your business profile - This is what customers will see",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            // Business Type Selection
            Row(
              children: [
                const Expanded(
                  child: Text(
              "What type of business do you run?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    UXHelperWidget.showHelpDialog(
                      context,
                      title: "Business Type",
                      message: "Select the type that best matches your business. Don't worry, you can add more services later!",
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
            const SizedBox(height: 12),
            UXHelperWidget.buildInfoBanner(
              message: "Tap on the card that matches your business. You can change this later.",
            ),
            const SizedBox(height: 16),
            ..._businessTypes.map((type) => _buildBusinessTypeCard(type)),
            const SizedBox(height: 30),
            UXHelperWidget.buildHelpfulInputField(
              controller: _shopNameController,
              label: "Shop/Business Name",
              icon: Icons.store,
              helpText: "Enter the name of your shop or business as customers know it",
              example: "John's Car Wash & Detailing",
              isRequired: true,
              context: context,
            ),
            const SizedBox(height: 20),
            UXHelperWidget.buildHelpfulInputField(
              controller: _shopAddressController,
              label: "Business Address",
              icon: Icons.location_on,
              helpText: "Enter your complete business address. This helps customers find you.",
              example: "123 Main Street, City, State, ZIP Code",
              maxLines: 3,
              isRequired: true,
              context: context,
            ),
            const SizedBox(height: 20),
            UXHelperWidget.buildHelpfulInputField(
              controller: _shopMobileController,
              label: "Business Phone (Optional)",
              icon: Icons.phone,
              helpText: "Enter your business phone number if different from your personal number",
              example: "+1234567890",
              keyboardType: TextInputType.phone,
              context: context,
            ),
            const SizedBox(height: 20),
            UXHelperWidget.buildHelpfulInputField(
              controller: _shopEmailController,
              label: "Business Email (Optional)",
              icon: Icons.email,
              helpText: "Enter your business email if you have one",
              example: "info@yourbusiness.com",
              keyboardType: TextInputType.emailAddress,
              context: context,
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
              "Select the services you want to offer to customers",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            UXHelperWidget.buildInfoBanner(
              message: "Don't worry! You can add more services and packages later from your dashboard.",
              icon: Icons.info_outline,
              backgroundColor: Colors.blue[50],
              iconColor: Colors.blue[700],
            ),
            const SizedBox(height: 20),
            // Services Selection
            Row(
              children: [
                const Expanded(
                  child: Text(
              "Services",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    UXHelperWidget.showHelpDialog(
                      context,
                      title: "What are Services?",
                      message: "Services are individual things you offer, like 'Car Wash' or 'Oil Change'. Tap on the buttons below to select which services you want to offer. You must select at least one!",
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
            Text(
              "Tap to select (at least 1 required)",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
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
            if (_selectedServices.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Please select at least one service",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 30),
            // Packages Selection
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Packages (Optional)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    UXHelperWidget.showHelpDialog(
                      context,
                      title: "What are Packages?",
                      message: "Packages are combinations of multiple services sold together at a special price. For example, 'Complete Car Care Package' might include wash, wax, and interior cleaning. This is optional - you can skip this for now!",
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
            Text(
              "Tap to select (optional - you can add later)",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
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
          UXHelperWidget.showFriendlyError(
            context,
            "Please fill in all the required fields above. Look for the red * mark - those fields are required!",
          );
          return false;
        }
        // Basic email validation
        if (!_emailController.text.contains('@') || !_emailController.text.contains('.')) {
          UXHelperWidget.showFriendlyError(
            context,
            "Please enter a valid email address. Example: yourname@email.com",
          );
          return false;
        }
        return true;
      case 2:
        if (_shopNameController.text.isEmpty || _shopAddressController.text.isEmpty) {
          UXHelperWidget.showFriendlyError(
            context,
            "Please enter your shop name and address. These are required so customers can find you!",
          );
          return false;
        }
        return true;
      case 3:
        if (_selectedServices.isEmpty) {
          UXHelperWidget.showFriendlyError(
            context,
            "Please select at least one service. Tap on the service buttons above to select them!",
          );
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

      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context); // Close loading dialog
      }
      
      if (context.mounted) {
        UXHelperWidget.showSuccessMessage(
          context,
          "🎉 Great! Your business profile is ready! You can now start accepting bookings.",
        );
      }
      
      // Navigate to main dashboard
      if (context.mounted) {
        CommonWidget.navigateToKillAllScreen(context, const DashboardActivity());
      }
      
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context); // Close loading dialog
      }
      UXHelperWidget.showFriendlyError(
        context,
        "Oops! Something went wrong. Please check your internet connection and try again. If the problem continues, contact support.",
      );
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
