import 'package:flutter/material.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Color.dart';
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
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Service' : 'Add Service'),
        backgroundColor: ColorClass.base_color,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceTitleField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildPriceField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDurationField()),
                ],
              ),
              const SizedBox(height: 16),
              _buildCapacityField(),
              const SizedBox(height: 16),
              _buildActiveSwitch(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonWidget.getTextWidgetPopSemi(
          'Service Title *',
          size: 14,
          color: Colors.black,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _serviceTitleController,
          decoration: InputDecoration(
            hintText: 'Enter service title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter service title';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonWidget.getTextWidgetPopSemi(
          'Description *',
          size: 14,
          color: Colors.black,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter service description',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter service description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonWidget.getTextWidgetPopSemi(
          'Category *',
          size: 14,
          color: Colors.black,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          hint: const Text('Select category'),
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
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonWidget.getTextWidgetPopSemi(
          'Price (₹) *',
          size: 14,
          color: Colors.black,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter price';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter valid price';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonWidget.getTextWidgetPopSemi(
          'Duration *',
          size: 14,
          color: Colors.black,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _durationController,
          decoration: InputDecoration(
            hintText: 'e.g., 30 minutes',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter duration';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCapacityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonWidget.getTextWidgetPopSemi(
          'Slot Capacity *',
          size: 14,
          color: Colors.black,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _capacityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Number of bookings per slot',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter slot capacity';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActiveSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CommonWidget.getTextWidgetPopSemi(
          'Service Active',
          size: 14,
          color: Colors.black,
        ),
        Switch(
          value: _isActive,
          onChanged: (value) {
            setState(() {
              _isActive = value;
            });
          },
          activeColor: ColorClass.base_color,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveService,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorClass.base_color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.isEdit ? 'Update Service' : 'Add Service',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
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
