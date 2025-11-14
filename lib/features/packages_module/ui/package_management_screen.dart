import 'package:flutter/material.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/features/packages_module/model/package_model.dart';
import 'package:car_app/features/packages_module/ui/add_package_screen.dart';

class PackageManagementScreen extends StatefulWidget {
  final String vendorId;

  const PackageManagementScreen({super.key, required this.vendorId});

  @override
  _PackageManagementScreenState createState() => _PackageManagementScreenState();
}

class _PackageManagementScreenState extends State<PackageManagementScreen> {
  List<PackageModel> packages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPackages();
  }

  void loadPackages() async {
    // Mock data - replace with actual API call
    setState(() {
      packages = [
        PackageModel(
          id: '1',
          packageName: 'Premium Car Care Pack',
          description: 'Complete car care package including wash, detailing, and polishing',
          price: 899.0,
          discount: 15.0,
          servicesIncluded: ['1', '2', '3'],
          isActive: true,
        ),
        PackageModel(
          id: '2',
          packageName: 'Basic Wash Package',
          description: 'Basic car wash and interior cleaning',
          price: 399.0,
          discount: 10.0,
          servicesIncluded: ['1', '4'],
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
        title: const Text('Package Management'),
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
                  'My Packages (${packages.length})',
                  textsize: 18,
                  color: Colors.black,
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Temporarily disabled - AddPackageScreen commented out
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add Package feature temporarily disabled')),
                    );
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => AddPackageScreen(vendorId: widget.vendorId),
                    //   ),
                    // ).then((_) => loadPackages());
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Package', style: TextStyle(color: Colors.white)),
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
                : packages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            CommonWidget.getTextWidgetPopReg(
                              'No packages created yet',
                              textsize: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            CommonWidget.getTextWidgetPopReg(
                              'Create packages to bundle multiple services',
                              textsize: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: packages.length,
                        itemBuilder: (context, index) {
                          return PackageCard(
                            package: packages[index],
                            onEdit: () => _editPackage(packages[index]),
                            onDelete: () => _deletePackage(packages[index]),
                            onToggleStatus: () => _togglePackageStatus(packages[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _editPackage(PackageModel package) {
    // Temporarily disabled - AddPackageScreen commented out
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit Package feature temporarily disabled')),
    );
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => AddPackageScreen(
    //       vendorId: widget.vendorId,
    //       package: package,
    //       isEdit: true,
    //     ),
    //   ),
    // ).then((_) => loadPackages());
  }

  void _deletePackage(PackageModel package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Package'),
        content: Text('Are you sure you want to delete "${package.packageName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete package API call
              loadPackages();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _togglePackageStatus(PackageModel package) {
    // TODO: Implement toggle package status API call
    setState(() {
      package.isActive = !package.isActive;
    });
  }
}

class PackageCard extends StatelessWidget {
  final PackageModel package;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const PackageCard({super.key, 
    required this.package,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final discountedPrice = package.price - (package.price * package.discount / 100);
    
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
                    package.packageName,
                    textsize: 16,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: package.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    package.isActive ? 'Active' : 'Inactive',
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
              package.description,
              textsize: 14,
              color: Colors.grey[600]!,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                CommonWidget.getTextWidgetPopReg(
                  '${package.servicesIncluded.length} services',
                  textsize: 12,
                  color: Colors.grey[600]!,
                ),
                const Spacer(),
                if (package.discount > 0) ...[
                  Text(
                    '₹${package.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500]!,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                CommonWidget.getTextWidgetPopbold(
                  '₹${discountedPrice.toStringAsFixed(0)}',
                  textsize: 16,
                  color: ColorClass.base_color,
                ),
              ],
            ),
            if (package.discount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${package.discount.toInt()}% OFF',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onToggleStatus,
                    icon: Icon(
                      package.isActive ? Icons.pause : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(package.isActive ? 'Deactivate' : 'Activate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: package.isActive ? Colors.orange : Colors.green,
                      side: BorderSide(
                        color: package.isActive ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
