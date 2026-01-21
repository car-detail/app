import 'package:flutter/material.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/UXHelperWidget.dart';
import 'package:car_app/features/services_module/model/service_model.dart';

class AddServiceScreen extends StatefulWidget {
  final String vendorId;
  final ServiceModel? service;
  final bool isEdit;

  const AddServiceScreen({super.key, 
    required this.vendorId,
    this.service,
    this.isEdit = false,
  });

  @override
  _AddServiceScreenState createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _capacityController = TextEditingController();

  String? _selectedCategory;
  bool _isActive = true;
  bool _isLoading = false;

  final List<String> _categories = [
    'Car Wash',
    'Car Detailing',
    'Car Polishing',
    'Interior Cleaning',
    'Engine Cleaning',
    'Tire Service',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.service != null) {
      _initializeForm();
    }
  }

  void _initializeForm() {
    final service = widget.service!;
    _serviceTitleController.text = service.serviceTitle;
    _descriptionController.text = service.description;
    _priceController.text = service.price.toString();
    _durationController.text = service.duration;
    _selectedCategory = service.categoryName;
    _isActive = service.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Service' : 'Add New Service'),
        backgroundColor: ColorClass.base_color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              UXHelperWidget.buildInfoBanner(
                message: widget.isEdit 
                    ? "Update your service details below. Don't worry, you can change anything anytime!"
                    : "Let's add your service! Just fill in the basic details. We'll help you every step of the way.",
                icon: Icons.info_outline,
              ),
              const SizedBox(height: 30),
              
              // Service Title
              UXHelperWidget.buildHelpfulInputField(
                controller: _serviceTitleController,
                label: "Service Name",
                icon: Icons.design_services,
                helpText: "What do you call this service? This is what customers will see.",
                example: "Basic Car Wash",
                isRequired: true,
                context: context,
              ),
              const SizedBox(height: 20),
              
              // Description
              UXHelperWidget.buildHelpfulInputField(
                controller: _descriptionController,
                label: "Description",
                icon: Icons.description,
                helpText: "Briefly describe what this service includes. Keep it simple and clear.",
                example: "Complete exterior wash with soap and water",
                maxLines: 3,
                isRequired: true,
                context: context,
              ),
              const SizedBox(height: 20),
              
              // Category
              _buildCategoryDropdown(),
              const SizedBox(height: 20),
              
              // Price and Duration Row
              Row(
                children: [
                  Expanded(
                    child: UXHelperWidget.buildHelpfulInputField(
                      controller: _priceController,
                      label: "Price",
                      icon: Icons.attach_money,
                      helpText: "How much do you charge? Enter just the number.",
                      example: "25",
                      keyboardType: TextInputType.number,
                      isRequired: true,
                      context: context,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: UXHelperWidget.buildHelpfulInputField(
                      controller: _durationController,
                      label: "Duration",
                      icon: Icons.access_time,
                      helpText: "How long does this service take?",
                      example: "30 minutes",
                      isRequired: true,
                      context: context,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Capacity (Optional with help)
              _buildCapacityField(),
              const SizedBox(height: 20),
              
              // Active Switch with explanation
              _buildActiveSwitch(),
              const SizedBox(height: 30),
              
              // Save Button
              _buildSaveButton(),
            ],
          ),
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
              child: Row(
                children: [
                  Text(
                    "Service Type",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    " *",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ],
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(Icons.category, color: ColorClass.base_color),
            ),
            hint: const Text('Select service type'),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a service type';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }


  Widget _buildCapacityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Row(
                children: [
                  Text(
                    "How many cars can you handle at once?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                UXHelperWidget.showHelpDialog(
                  context,
                  title: "Capacity",
                  message: "How many cars can you service at the same time? This helps us manage bookings better.",
                  example: "If you can wash 5 cars at once, enter 5",
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
        TextFormField(
          controller: _capacityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.directions_car, color: ColorClass.base_color),
            hintText: 'e.g., 5',
            helperText: "Optional - We'll set a default if you skip this",
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActiveSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Make this service available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isActive 
                      ? "✅ Customers can book this service now"
                      : "⏸️ Service is hidden from customers",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
            activeThumbColor: ColorClass.base_color,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveService,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorClass.base_color,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isEdit ? Icons.check_circle : Icons.add_circle,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isEdit ? 'Update Service' : 'Save Service',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (!_isLoading) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _saveService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to save/update service
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit 
                  ? 'Service updated successfully!' 
                  : 'Service added successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _serviceTitleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }
}
