import 'package:flutter/material.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/features/services_module/model/service_model.dart';
import 'package:car_app/features/services_module/ui/add_service_screen.dart';

class ServiceManagementScreen extends StatefulWidget {
  final String vendorId;

  const ServiceManagementScreen({super.key, required this.vendorId});

  @override
  _ServiceManagementScreenState createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  List<ServiceModel> services = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  void loadServices() async {
    // Mock data - replace with actual API call
    setState(() {
      services = [
        ServiceModel(
          id: '1',
          serviceTitle: 'Car Wash',
          description: 'Complete car wash service',
          price: 299.0,
          duration: '30 minutes',
          categoryName: 'Wash',
          isActive: true,
        ),
        ServiceModel(
          id: '2',
          serviceTitle: 'Car Detailing',
          description: 'Premium car detailing service',
          price: 599.0,
          duration: '2 hours',
          categoryName: 'Detailing',
          isActive: true,
        ),
      ];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Management'),
        backgroundColor: ColorClass.base_color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CommonWidget.getTextWidgetPopbold(
                  'My Services (${services.length})',
                  textsize: 18,
                  color: Colors.black,
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddServiceScreen(vendorId: widget.vendorId),
                      ),
                    ).then((_) => loadServices());
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Service', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorClass.base_color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : services.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.car_repair, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            CommonWidget.getTextWidgetPopReg(
                              'No services added yet',
                              textsize: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            CommonWidget.getTextWidgetPopReg(
                              'Add your first service to get started',
                              textsize: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          return ServiceCard(
                            service: services[index],
                            onEdit: () => _editService(services[index]),
                            onDelete: () => _deleteService(services[index]),
                            onToggleStatus: () => _toggleServiceStatus(services[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _editService(ServiceModel service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServiceScreen(
          vendorId: widget.vendorId,
          service: service,
          isEdit: true,
        ),
      ),
    ).then((_) => loadServices());
  }

  void _deleteService(ServiceModel service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete "${service.serviceTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete service API call
              loadServices();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleServiceStatus(ServiceModel service) {
    // TODO: Implement toggle service status API call
    setState(() {
      service.isActive = !service.isActive;
    });
  }
}

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const ServiceCard({super.key, 
    required this.service,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CommonWidget.getTextWidgetPopbold(
                    service.serviceTitle,
                    textsize: 16,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: service.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    service.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CommonWidget.getTextWidgetPopReg(
              service.description,
              textsize: 14,
              color: Colors.grey[600]!,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.category, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                CommonWidget.getTextWidgetPopReg(
                  service.categoryName,
                  textsize: 12,
                  color: Colors.grey[600]!,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                CommonWidget.getTextWidgetPopReg(
                  service.duration,
                  textsize: 12,
                  color: Colors.grey[600]!,
                ),
                const Spacer(),
                CommonWidget.getTextWidgetPopbold(
                  '₹${service.price.toStringAsFixed(0)}',
                  textsize: 16,
                  color: ColorClass.base_color,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorClass.base_color,
                      side: BorderSide(color: ColorClass.base_color),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onToggleStatus,
                    icon: Icon(
                      service.isActive ? Icons.pause : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(service.isActive ? 'Deactivate' : 'Activate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: service.isActive ? Colors.orange : Colors.green,
                      side: BorderSide(
                        color: service.isActive ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
