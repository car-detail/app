// Temporarily commented out to fix compilation issues
// import 'package:flutter/material.dart';
// import 'package:car_app/Common/CommonWidget.dart';
// import 'package:car_app/Common/Color.dart';
// import 'package:car_app/features/packages_module/model/package_model.dart';
// import 'package:car_app/features/services_module/model/service_model.dart';

// Temporarily commented out to fix compilation issues
/*
class AddPackageScreen extends StatefulWidget {
  final String vendorId;
  final PackageModel? package;
  final bool isEdit;

  AddPackageScreen({
    required this.vendorId,
    this.package,
    this.isEdit = false,
  });

  @override
  _AddPackageScreenState createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _packageNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();

  List<ServiceModel> _availableServices = [];
  List<String> _selectedServiceIds = [];
  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    loadAvailableServices();
    if (widget.isEdit && widget.package != null) {
      _initializeForm();
    }
  }

  void _initializeForm() {
    final package = widget.package!;
    _packageNameController.text = package.packageName;
    _descriptionController.text = package.description;
    _priceController.text = package.price.toString();
    _discountController.text = package.discount.toString();
    _selectedServiceIds = List.from(package.servicesIncluded);
    _isActive = package.isActive;
  }

  void loadAvailableServices() async {
    // Mock data - replace with actual API call
    setState(() {
      _availableServices = [
        ServiceModel(
          id: '1',
          serviceTitle: 'Car Wash',
          description: 'Complete car wash service',
          price: 299.0,
          duration: '30 minutes',
          categoryName: 'Wash',
        ),
        ServiceModel(
          id: '2',
          serviceTitle: 'Car Detailing',
          description: 'Premium car detailing service',
          price: 599.0,
          duration: '2 hours',
          categoryName: 'Detailing',
        ),
        ServiceModel(
          id: '3',
          serviceTitle: 'Car Polishing',
          description: 'Professional car polishing',
          price: 399.0,
          duration: '1 hour',
          categoryName: 'Polishing',
        ),
        ServiceModel(
          id: '4',
          serviceTitle: 'Interior Cleaning',
          description: 'Complete interior cleaning',
          price: 199.0,
          duration: '45 minutes',
          categoryName: 'Interior',
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Package' : 'Add Package'),
        backgroundColor: ColorClass.base_color,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPackageNameField(),
              SizedBox(height: 16),
              _buildDescriptionField(),
              SizedBox(height: 16),
              _buildServicesSelection(),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildPriceField()),
                  SizedBox(width: 16),
                  Expanded(child: _buildDiscountField()),
                ],
              ),
              SizedBox(height: 16),
              _buildActiveSwitch(),
              SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonWidget.getTextWidgetPopSemi(
          'Package Name *',
          size: 14,
          color: Colors.black,
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _packageNameController,
          decoration: InputDecoration(
            hintText: 'Enter package name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter package name';
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
        SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter package description',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter package description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildServicesSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonWidget.getTextWidgetPopSemi(
          'Select Services *',
          size: 14,
          color: Colors.black,
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: _availableServices.map((service) {
              final isSelected = _selectedServiceIds.contains(service.id);
              return CheckboxListTile(
                title: Text(service.serviceTitle),
                subtitle: Text('₹${service.price.toStringAsFixed(0)} - ${service.duration}'),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedServiceIds.add(service.id);
                    } else {
                      _selectedServiceIds.remove(service.id);
                    }
                  });
                },
                activeColor: ColorClass.base_color,
              );
            }).toList(),
          ),
        ),
        if (_selectedServiceIds.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one service',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonWidget.getTextWidgetPopSemi(
          'Package Price (₹) *',
          size: 14,
          color: Colors.black,
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  Widget _buildDiscountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonWidget.getTextWidgetPopSemi(
          'Discount (%)',
          size: 14,
          color: Colors.black,
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _discountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final discount = double.tryParse(value);
              if (discount == null || discount < 0 || discount > 100) {
                return 'Discount must be between 0-100';
              }
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
          'Package Active',
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
        onPressed: _isLoading ? null : _savePackage,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorClass.base_color,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.isEdit ? 'Update Package' : 'Create Package',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _savePackage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to save/update package
      await Future.delayed(Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit 
                  ? 'Package updated successfully!' 
                  : 'Package created successfully!',
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
    _packageNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }
}
*/
