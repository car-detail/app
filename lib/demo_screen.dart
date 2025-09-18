import 'package:flutter/material.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Color.dart';

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cahrz - Service & Package Management Demo'),
        backgroundColor: ColorClass.base_color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ColorClass.base_color, ColorClass.base_color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.car_repair, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  CommonWidget.getTextWidgetPopbold(
                    'Cahrz Car Services',
                    textsize: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  CommonWidget.getTextWidgetPopReg(
                    'Advanced Service & Package Management System',
                    textsize: 16,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Features Overview
            CommonWidget.getTextWidgetPopbold(
              '🚀 New Features Implemented',
              textsize: 20,
              color: Colors.black,
            ),
            const SizedBox(height: 16),
            
            // Multiple Services Feature
            _buildFeatureCard(
              icon: Icons.car_repair,
              title: 'Multiple Services per Vendor',
              description: 'Vendors can now add and manage multiple car-related services with individual pricing, duration, and availability.',
              features: [
                'Add unlimited services per vendor',
                'Individual pricing and duration for each service',
                'Service management with edit/delete/activate',
                'Category-based organization',
                'Time slot management',
              ],
              color: Colors.blue,
            ),
            
            const SizedBox(height: 16),
            
            // Packages Feature
            _buildFeatureCard(
              icon: Icons.inventory_2,
              title: 'Service Packages',
              description: 'Create bundled service packages with discounts to offer comprehensive car care solutions.',
              features: [
                'Bundle multiple services into packages',
                'Percentage-based discount system',
                'Package management with full CRUD operations',
                'Service selection with multi-select interface',
                'Automatic price calculation',
              ],
              color: Colors.orange,
            ),
            
            const SizedBox(height: 16),
            
            // Backend APIs
            _buildFeatureCard(
              icon: Icons.api,
              title: 'Backend API Endpoints',
              description: 'Complete RESTful API implementation for service and package management.',
              features: [
                'POST /api/v1/services/vendor/:vendorId/services - Add multiple services',
                'GET /api/v1/services/vendor/:vendorId - Get vendor services',
                'DELETE /api/v1/services/vendor/:vendorId/services/:serviceId - Remove service',
                'POST /api/v1/packages/create-package - Create package',
                'GET /api/v1/packages/vendor/:vendorId - Get vendor packages',
                'PATCH /api/v1/packages/:packageId - Update package',
                'DELETE /api/v1/packages/:packageId - Delete package',
              ],
              color: Colors.green,
            ),
            
            const SizedBox(height: 24),
            
            // Demo Buttons
            CommonWidget.getTextWidgetPopbold(
              '📱 Flutter UI Screens',
              textsize: 20,
              color: Colors.black,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildDemoButton(
                    context,
                    'Service Management',
                    Icons.car_repair,
                    Colors.blue,
                    () {
                      _showDemoDialog(context, 'Service Management', [
                        'Service list with cards showing details',
                        'Add/Edit service form with validation',
                        'Service status toggle (Active/Inactive)',
                        'Delete service with confirmation',
                        'Category selection dropdown',
                        'Price and duration input fields',
                      ]);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDemoButton(
                    context,
                    'Package Management',
                    Icons.inventory_2,
                    Colors.orange,
                    () {
                      _showDemoDialog(context, 'Package Management', [
                        'Package list with discount display',
                        'Create/Edit package form',
                        'Multi-select service interface',
                        'Discount percentage input',
                        'Package status management',
                        'Service count and pricing display',
                      ]);
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Technical Details
            _buildFeatureCard(
              icon: Icons.code,
              title: 'Technical Implementation',
              description: 'Built with modern Flutter and NestJS architecture.',
              features: [
                'Flutter: StatefulWidget with proper state management',
                'NestJS: RESTful APIs with MongoDB integration',
                'MongoDB: Document-based database with relationships',
                'Validation: Comprehensive input validation',
                'Error Handling: User-friendly error messages',
                'UI/UX: Modern Material Design components',
              ],
              color: Colors.purple,
            ),
            
            const SizedBox(height: 24),
            
            // Database Schema
            _buildFeatureCard(
              icon: Icons.storage,
              title: 'Database Schema',
              description: 'Optimized database design for scalability and performance.',
              features: [
                'Service Collection: serviceTitle, description, price, duration, categoryName, availableSlots, vendorId',
                'Package Collection: packageName, description, servicesIncluded[], price, discount, vendorId',
                'Relationships: Package.servicesIncluded references Service._id',
                'Indexing: Optimized for location-based queries',
                'Validation: Server-side validation for data integrity',
              ],
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required List<String> features,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CommonWidget.getTextWidgetPopbold(
                    title,
                    textsize: 18,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CommonWidget.getTextWidgetPopReg(
              description,
              textsize: 14,
              color: Colors.grey[600]!,
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: color, fontSize: 16)),
                  Expanded(
                    child: CommonWidget.getTextWidgetPopReg(
                      feature,
                      textsize: 13,
                      color: Colors.grey[700]!,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDemoButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            CommonWidget.getTextWidgetPopbold(
              title,
              textsize: 14,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDemoDialog(BuildContext context, String title, List<String> features) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✓ ', style: TextStyle(color: Colors.green, fontSize: 16)),
                  Expanded(
                    child: Text(feature, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
