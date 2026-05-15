import 'dart:convert';
import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/features/packages_model/data_manager/package_data_manager.dart';
import 'package:car_app/features/packages_model/model/package_model_data.dart';
import 'package:car_app/features/packages_model/ui/add_package_activity.dart';
import 'package:car_app/features/packages_model/ui/edit_package_activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PackageListActivity extends StatefulWidget {
  const PackageListActivity({super.key});

  @override
  State<PackageListActivity> createState() => _PackageListActivityState();
}

class _PackageListActivityState extends State<PackageListActivity> {
  List<PackageData> packages = [];
  PackageDataManager? dataManager;
  SharedPreferences? sharedPreferences;
  bool isLoading = true;

  // ── design tokens ───────────────────────────────────────────────
  static const _bg          = Color(0xFFF0FDF4);
  static const _card        = Colors.white;
  static const _borderAccent = Color(0xFF1CB273);
  static const _surface     = Color(0xFFF3F4F6);
  static const _textPrimary  = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF6B7280);
  static const _red          = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    dataManager = PackageDataManager(sharedPreferences!);
    await getPackages();
  }

  Future<void> getPackages() async {
    setState(() {
      isLoading = true;
    });

    try {
      var response = await dataManager!.getAllPackages(context);
      if (!mounted) return;
      var data = PackageModelData.fromJson(jsonDecode(response.body));

    if (mounted && data.status == "success") {
        setState(() {
          packages.clear();
          packages.addAll(data.data!);
        });
      } else if (mounted) {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to load packages");
      }
    } catch (e) {
      if (mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error loading packages: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> deletePackage(String packageId) async {
    try {
      var response = await dataManager!.deletePackage(context, packageId);
      if (!mounted) return;
      var data = PackageModelData.fromJson(jsonDecode(response.body));

    if (mounted && data.status == "success") {
        CommonWidget.successShowSnackBarFor(context, "Package deleted successfully");
        if (mounted) getPackages();
      } else if (mounted) {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to delete package");
      }
    } catch (e) {
      if (mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error deleting package: $e");
      }
    }
  }

  void _showDeleteDialog(PackageData package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Package"),
        content: Text("Are you sure you want to delete '${package.packageName}'?"),
        actions: [
          TextButton(
            onPressed: () => CommonWidget.safePop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              CommonWidget.safePop(context);
              deletePackage(package.sId!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: isLoading
                  ? _buildLoading()
                  : packages.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: getPackages,
                          color: ColorClass.base_color,
                          backgroundColor: _card,
                          child: _buildPackagesList(),
                        ),
            ),
          ],
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: ColorClass.base_color.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPackageActivity(),
                ),
              ).then((_) => getPackages());
            },
            backgroundColor: ColorClass.base_color,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            label: const Text(
              "Add Package",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: topPad + 12,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF166534), Color(0xFF1CB273), Color(0xFF26D17A)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1CB273).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "My Packages",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (!isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                "${packages.length}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        color: ColorClass.base_color,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 36, color: _textSecondary),
            ),
            const SizedBox(height: 24),
            const Text(
              "No packages yet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Create your first package to start offering bundled services to customers.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackagesList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: packages.length,
      itemBuilder: (context, index) => _buildPackageCard(packages[index]),
    );
  }

  Widget _buildPackageCard(PackageData package) {
    final isBestSeller = package.isBestSeller ?? false;
    final smallPrice = double.tryParse(
            package.smallVehiclePrice ?? package.packagePrice ?? "0") ??
        0;
    final largePrice = double.tryParse(
            package.largeVehiclePrice ?? package.packagePrice ?? "0") ??
        0;
    final duration =
        double.tryParse(package.packageDuration ?? "0") ?? 0;
    final servicesCount = package.servicesIncluded?.length ?? 0;
    final isActive = package.isActive ?? true;

    // build service names list
    List<String> serviceNames = [];
    if (package.customServices != null &&
        package.customServices!.isNotEmpty) {
      serviceNames.addAll(package.customServices!);
    }
    if (package.serviceDetails != null &&
        package.serviceDetails!.isNotEmpty) {
      final names = package.serviceDetails!
          .map((s) => s['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty && !n.startsWith('Service '))
          .toList();
      serviceNames.addAll(names);
    } else if (package.servicesIncluded != null &&
        package.customServices == null) {
      debugPrint(
          'Package: ${package.packageName} - No serviceDetails or customServices, servicesIncluded: ${package.servicesIncluded}');
      serviceNames.addAll(
          package.servicesIncluded!.map((id) => 'Service $id').toList());
    }
    serviceNames = serviceNames.toSet().toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderAccent.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // thin top accent strip
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorClass.base_color.withValues(alpha: 0.9),
                    ColorClass.base_color.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── row 1: name + badges ──────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.packageName ?? "Unknown Package",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: _textPrimary,
                                letterSpacing: -0.4,
                                height: 1.15,
                              ),
                            ),
                            if (package.packageDescription != null &&
                                package.packageDescription!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                package.packageDescription!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: _textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // best seller badge
                          if (isBestSeller)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    ColorClass.base_color,
                                    ColorClass.base_color
                                        .withValues(alpha: 0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Text(
                                "Best Seller",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          if (isBestSeller) const SizedBox(height: 6),
                          // status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? ColorClass.base_color.withValues(alpha: 0.12)
                                  : _surface,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              isActive ? "Active" : "Inactive",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? ColorClass.base_color
                                    : _textSecondary,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── row 2: price + stats ──────────────────
                  Row(
                    children: [
                      _buildStatCell(
                        label: "Small",
                        value: "\$${smallPrice.toStringAsFixed(0)}",
                        valueColor: _textPrimary,
                      ),
                      _buildDivider(),
                      _buildStatCell(
                        label: "Large",
                        value: "\$${largePrice.toStringAsFixed(0)}",
                        valueColor: _textPrimary,
                      ),
                      _buildDivider(),
                      _buildStatCell(
                        label: "Duration",
                        value: "${duration.toStringAsFixed(0)}h",
                        valueColor: _textPrimary,
                      ),
                      _buildDivider(),
                      _buildStatCell(
                        label: "Services",
                        value: "$servicesCount",
                        valueColor: _textPrimary,
                      ),
                    ],
                  ),

                  // ── row 3: service tags ───────────────────
                  if (serviceNames.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: serviceNames.map((name) {
                        final label = name.length > 25
                            ? '${name.substring(0, 25)}...'
                            : name;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // ── package tier ──────────────────────────
                  if (package.packageTier != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category,
                              size: 13, color: _textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            package.packageTier!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── row 4: actions ────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditPackageActivity(packageData: package),
                              ),
                            ).then((_) => getPackages());
                          },
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: ColorClass.base_color,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "Edit",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ghost delete icon button
                      GestureDetector(
                        onTap: () => _showDeleteDialog(package),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 20, color: _red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCell({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: valueColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: _textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: _surface,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

}
