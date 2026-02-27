import 'dart:convert';
import 'dart:io';

import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonBean.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/ContainerDecoration.dart';
import 'package:car_app/features/log_in/ui/new_login_activity.dart';
import 'package:car_app/features/resister_vendor_model/ui/edit_vendor_activity.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/CommonPopUp.dart';
import '../../../Common/Constant.dart';
import '../../log_in/model/vendor_details_bean.dart';
import '../../resister_vendor_model/ui/registor_vendor_activity_simple.dart';
import '../data_manager/profile_list_data_manager.dart';
import '../../packages_model/ui/package_list_activity.dart';
import '../../packages_model/data_manager/package_data_manager.dart';
import '../../log_in/data_manager/LoginDataManager.dart';
import '../../packages_model/model/package_model_data.dart';
import '../../offer_model/ui/enhanced_offer_list_screen.dart';
import '../../offer_model/data_manager/offer_data_manager.dart';
import '../../offer_model/model/offer_list_model_bean.dart';
import '../../dashboard_module/ui/dashboard_activity.dart';
import '../../services_model/data_manager/services_data_manager.dart';
import '../../services_model/model/services_list_bean.dart';
import '../../services_model/ui/modern_add_service_activity.dart';
import '../../packages_model/ui/edit_package_activity.dart';

class ProfileVendorListActivity extends StatefulWidget {
  final bool isActive;
  const ProfileVendorListActivity({this.isActive = false, super.key});

  @override
  State<ProfileVendorListActivity> createState() =>
      _ProfileVendorListActivityState();
}

class _ProfileVendorListActivityState extends State<ProfileVendorListActivity> with SingleTickerProviderStateMixin {
  ApiFuntions apiFuntions = ApiFuntions();
  ProfileListDataManager? dataManager;
  late SharedPreferences? sharedPreferences;
  final bool _isPasswordVisible = false;
  int maxLength = 10;
  VendorDetailData? dataNew;
  LoginDataManager? loginDataManager;
  var venderId = "";
  PackageDataManager? packageDataManager;
  OfferDataManager? offerDataManager;
  ServicesDataManager? servicesDataManager;
  List<PackageData> packages = [];
  List<OfferListModelData> offers = [];
  List<ServicesListData> services = [];
  bool isLoadingPackages = false;
  bool isLoadingOffers = false;
  bool isLoadingServices = false;
  PageController? offerPageController;
  int currentOfferPage = 0;
  PageController? packagePageController;
  int currentPackagePage = 0;
  TabController? _tabController;
  VoidCallback? _tabListener;

  @override
  void initState() {
    super.initState();
    offerPageController = PageController();
    packagePageController = PageController();
    // Initialize TabController with 3 tabs (Services, Packages, Offers)
    _tabController = TabController(length: 3, vsync: this);
    // Add listener to update UI when tab changes
    _tabListener = () {
      // Update UI whenever tab index changes
      if (mounted && _tabController != null) {
        setState(() {
          // Force rebuild to update tab button states
        });
      }
    };
    _tabController?.addListener(_tabListener!);
    init();
  }

  Future<void> _recoverVendorId() async {
    if (loginDataManager == null || sharedPreferences == null) return;
    
    debugPrint('=== Profile: Attempting self-healing vendorId recovery ===');
    try {
      final vendorResponse = await loginDataManager!.getVendorDetails(context);
      if (vendorResponse.statusCode == 200) {
        final vendorData = jsonDecode(vendorResponse.body);
        if (vendorData['status'] == 'success' && 
            vendorData['data'] != null && 
            vendorData['data'] is List && 
            vendorData['data'].isNotEmpty) {
          
          String recoveredId = vendorData['data'][0]['_id'] ?? '';
          if (recoveredId.isNotEmpty) {
            await sharedPreferences!.setString(Constant.vendorId, recoveredId);
            setState(() {
              venderId = recoveredId;
            });
            debugPrint('=== Profile: vendorId recovered and stored: $venderId ===');
          }
        }
      }
    } catch (e) {
      debugPrint('=== Profile: Error during self-healing: $e ===');
    }
  }

  @override
  void dispose() {
    if (_tabListener != null && _tabController != null) {
      _tabController!.removeListener(_tabListener!);
    }
    _tabController?.dispose();
    offerPageController?.dispose();
    packagePageController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible
    if (venderId.isNotEmpty && packages.isEmpty && offers.isEmpty && services.isEmpty && !isLoadingPackages && !isLoadingOffers && !isLoadingServices) {
      getPackages(context);
      getOffers(context);
      getServices(context);
    }
  }

  @override
  void didUpdateWidget(covariant ProfileVendorListActivity oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data if the screen becomes active
    if (widget.isActive && !oldWidget.isActive) {
      debugPrint('🔄 Profile tab became active - triggering refresh');
      init();
    }
  }

  void init() async {
    start();
  }

  start() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      
      if (sharedPreferences == null) {
        return;
      }
      
      dataManager = ProfileListDataManager(sharedPreferences!);
      
      packageDataManager = PackageDataManager(sharedPreferences!);
      
      offerDataManager = OfferDataManager(sharedPreferences!);
      
      servicesDataManager = ServicesDataManager(sharedPreferences!);
      
      loginDataManager = LoginDataManager(sharedPreferences!);
      
      venderId = (sharedPreferences!.getString(Constant.vendorId) ?? "").trim();
      debugPrint('=== Profile Screen: Current vendorId: $venderId ===');
      
      await getUser(context);
      
      // Update venderId after getUser completes
      venderId = (sharedPreferences!.getString(Constant.vendorId) ?? "").trim();
      
      // Self-healing: If still missing, try explicit recovery
      if (venderId.isEmpty) {
        await _recoverVendorId();
      }
      
      // Fetch packages, offers, and services if vendor exists
      if (venderId.isNotEmpty) {
        debugPrint('=== Profile: Starting data fetch for vendor: $venderId ===');
        getPackages(context);
        getOffers(context);
        getServices(context);
      } else {
        debugPrint('=== Profile: No valid vendorId found even after recovery attempt ===');
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          bottom: false,
          child: Column(
          children: [
            // Enhanced Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorClass.base_color,
                    ColorClass.base_color.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  // Back Button
                  CommonWidget.buildBackButton(
                    context,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    iconColor: Colors.white,
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        CommonWidget.safePop(context);
                      } else {
                        // Fallback: Navigate to dashboard if no route to pop
                        CommonWidget.navigateToKillAllScreen(context, const DashboardActivity());
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Profile",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dataNew?.firstName != null 
                              ? "Welcome back, ${dataNew!.firstName}!"
                              : "Manage your account",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Small logout button in top right
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: InkWell(
                      onTap: () {
                        _showLogoutDialog(context);
                      },
                      child: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await getUser(context);
                  if (venderId.isNotEmpty) {
                    await Future.wait([
                      getPackages(context),
                      getOffers(context),
                      getServices(context),
                    ]);
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Shop Details Card
                      if (dataNew != null &&
                          dataNew!.vendorDetails!.isNotEmpty &&
                          dataNew!.vendorDetails![0].sId != "")
                        _buildShopDetailsCard()
                      else
                        _buildAddShopCard(),
                      const SizedBox(height: 20),
                      // Services, Packages, and Offers Tabs - after Shop Details
                      if (venderId.isNotEmpty) _buildTabsSection(),
                      const SizedBox(height: 20),
                      // Settings Card - after tabs
                      _buildSettingsCard(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
        ),
    );
  }

  Widget _buildShopDetailsCard() {
    return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
                                    BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
      child: Column(
                                  children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.green.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
                                          children: [
                                            const Icon(
                  Icons.store,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  "Shop Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context)
                                            .push(
                                          MaterialPageRoute(
                        builder: (context) => const EditVendorActivity(),
                                          ),
                                        )
                                            .then((onValue) {
                                          if (onValue == true) {
                                            getUser(context);
                                          }
                                        });
                                      },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                                              "Edit",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Shop Image
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: ClipOval(
                      child: Image.network(
                        dataNew?.vendorDetails![0].displayPicture ?? "",
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.store,
                            size: 50,
                            color: Colors.green,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Details
                _buildDetailRow("Shop Name", dataNew?.vendorDetails![0].displayName ?? ""),
                _buildDetailRow("Email", dataNew?.vendorDetails![0].officialEmail ?? "N/A"),
                _buildDetailRow("Mobile", dataNew?.vendorDetails![0].mobile ?? ""),
                  _buildDetailRow("Shop Hours", 
                      "${CommonWidget.convertToLocalTimeWithAMPM(dataNew?.vendorDetails![0].openTime ?? "")} - ${CommonWidget.convertToLocalTimeWithAMPM(dataNew?.vendorDetails![0].closeTime ?? "")}"),
                if (dataNew?.vendorDetails![0].daysAvailable != null && 
                    dataNew!.vendorDetails![0].daysAvailable!.isNotEmpty)
                  _buildDetailRow("Days", 
                      dataNew!.vendorDetails![0].daysAvailable!.join(", ")),
                _buildDetailRow("Location", dataNew?.vendorDetails![0].location!.name ?? ""),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddShopCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.1),
                  Colors.orange.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.add_business,
                  color: Colors.orange,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  "Add Your Shop",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.store,
                    size: 48,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "No Shop Added Yet",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Add your shop details to start offering services and manage your business.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                              Navigator.of(context)
                                  .push(
                                MaterialPageRoute(
                        builder: (context) => const RegistorVendorActivitySimple(),
                                ),
                              )
                                  .then((onValue) {
                                if (onValue == true) {
                                  getUser(context);
                                }
                              });
                            },
                  icon: const Icon(Icons.add_business),
                  label: const Text("Add Shop"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.1),
                  Colors.red.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Colors.red,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  "Account Settings",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Logout Option
                InkWell(
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.logout,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Logout",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.orange.withOpacity(0.6),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Delete Account Option
                InkWell(
                          onTap: () {
                _showDeleteAccountDialog(context);
                          },
                          child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Delete Account",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.red.withOpacity(0.6),
                      size: 16,
                    ),
                    ],
                  ),
                ),
                ),
              ],
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            "Logout",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to logout?",
          ),
          actions: [
            TextButton(
              onPressed: () => CommonWidget.safePop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: ColorClass.base_color,
              ),
              onPressed: () {
                CommonWidget.safePop(context);
                sharedPreferences!.clear();
                CommonWidget.navigateToKillAllScreen(
                    context, const NewLoginActivity());
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            "Delete Account",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => CommonWidget.safePop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                CommonWidget.safePop(context);
                deleteAccount();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  getRowDetails(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CommonWidget.getTextWidget500(title, size: 14),
        CommonWidget.getTextWidget400(value, 14)
      ],
    );
  }

  deleteAccount() async {
    var response = await dataManager!.deleteAccount(context);
    var data = CommonBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      CommonWidget.navigateToKillAllScreen(context, const NewLoginActivity());
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  getUser(BuildContext context) async {
    var response = await dataManager!.getUserDetails(context);
    var data = VendorDetailBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      if (data.data!.isNotEmpty) {
        setState(() {
          dataNew = data.data![0];
        });
        sharedPreferences!
            .setString(Constant.firstName, data.data?[0].firstName ?? "");
        sharedPreferences!
            .setString(Constant.lastName, data.data?[0].lastName ?? "");
        sharedPreferences!.setString(Constant.email, data.data?[0].email ?? "");
        sharedPreferences!
            .setString(Constant.mobile, data.data?[0].mobile ?? "");
        sharedPreferences!.setString(
            Constant.isNewUser, data.data?[0].isNewUser.toString() ?? "");
        sharedPreferences!
            .setString(Constant.roleName, data.data?[0].roleName ?? "");
        sharedPreferences!
            .setString(Constant.id, data.data?[0].sId.toString() ?? "");
        if (data.data![0].vendorDetails!.isNotEmpty) {
          String newVendorId = (data.data?[0].vendorDetails![0].sId.toString() ?? "").trim();
          sharedPreferences!.setString(Constant.vendorId, newVendorId);
          // Update local venderId in setState
          setState(() {
            venderId = newVendorId;
          });
          // Fetch packages, offers, and services if vendorId was just set
          if (venderId.isNotEmpty && mounted) {
            getPackages(context);
            getOffers(context);
            getServices(context);
          }
        }
      }
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  // Fetch packages
  Future<void> getPackages(BuildContext context) async {
    if (packageDataManager == null) {
      return;
    }
    
    if (!mounted) return;
    
    setState(() {
      isLoadingPackages = true;
    });
    
    debugPrint('=== Profile: Fetching Packages for Vendor: $venderId ===');
    try {
      var response = await packageDataManager!.getAllPackages(context);
      debugPrint('🟢 [Profile] Packages API Status: ${response.statusCode} for Vendor: $venderId');
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        try {
          var jsonData = jsonDecode(response.body);
          var data = PackageModelData.fromJson(jsonData);
          
          if (data.status == "success" && data.data != null) {
            if (mounted) {
              setState(() {
                // SUCCESS - replace data
                packages = data.data!;
                isLoadingPackages = false;
              });
              debugPrint('📦 [Profile] Successfully loaded ${packages.length} packages.');
            }
          } else {
            debugPrint('⚠️ [Profile] Packages API success status but data issues: ${data.message}');
            if (mounted) {
              setState(() {
                // If the response is clear success/empty, we can clear the list
                // but let's be safe: only clear if message is not an error
                if (data.status == "success") {
                  packages = [];
                }
                isLoadingPackages = false;
              });
            }
          }
        } catch (parseError) {
          debugPrint('❌ [Profile] Failed to parse packages JSON: $parseError');
          if (mounted) {
            setState(() {
              // RETAIN OLD DATA on parsing error to avoid blank UI
              isLoadingPackages = false;
            });
          }
        }
      } else {
        debugPrint('❌ [Profile] Packages API Error Status: ${response.statusCode}');
        if (mounted) {
          setState(() {
            // RETAIN OLD DATA on server error
            isLoadingPackages = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [Profile] Exception during getPackages: $e');
      if (mounted) {
        setState(() {
          // RETAIN OLD DATA on exception
          isLoadingPackages = false;
        });
      }
    }
  }

  // Fetch services
  Future<void> getServices(BuildContext context) async {
    if (servicesDataManager == null) {
      return;
    }
    
    if (!mounted) return;
    
    setState(() {
      isLoadingServices = true;
    });
    
    debugPrint('=== Profile: Fetching Services for Vendor: $venderId ===');
    try {
      var response = await servicesDataManager!.getServicesList(context);
      debugPrint('🟢 [Profile] Services API Status: ${response.statusCode}');
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        try {
          var data = ServicesListBean.fromJson(jsonDecode(response.body));
          if (data.status == "success" && data.data != null) {
            if (mounted) {
              setState(() {
                services = data.data!;
                isLoadingServices = false;
              });
              debugPrint('🛠️ [Profile] Successfully loaded ${services.length} services.');
            }
          } else {
            debugPrint('⚠️ [Profile] Services API issue: ${data.message}');
            if (mounted) {
              setState(() {
                if (data.status == "success") services = [];
                isLoadingServices = false;
              });
            }
          }
        } catch (e) {
          debugPrint('❌ [Profile] Failed to parse services JSON: $e');
          if (mounted) {
            setState(() {
              isLoadingServices = false;
            });
          }
        }
      } else {
        debugPrint('❌ [Profile] Services API Error: ${response.statusCode}');
        if (mounted) {
          setState(() {
            isLoadingServices = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [Profile] Exception during getServices: $e');
      if (mounted) {
        setState(() {
          isLoadingServices = false;
        });
      }
    }
  }

  // Fetch offers
  Future<void> getOffers(BuildContext context) async {
    if (offerDataManager == null) {
      return;
    }
    
    if (!mounted) return;
    
    setState(() {
      isLoadingOffers = true;
    });
    
    debugPrint('=== Profile: Fetching Offers for Vendor: $venderId ===');
    try {
      var response = await offerDataManager!.getOfferList(context);
      debugPrint('🟢 [Profile] Offers API Status: ${response.statusCode}');
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        try {
          var data = OfferListModelBean.fromJson(jsonDecode(response.body));
          
          if (data.status == "success" && data.data != null) {
            if (mounted) {
              setState(() {
                offers = data.data!;
                isLoadingOffers = false;
              });
              debugPrint('🏷️ [Profile] Successfully loaded ${offers.length} offers.');
            }
          } else {
            debugPrint('⚠️ [Profile] Offers API issue: ${data.message}');
            if (mounted) {
              setState(() {
                if (data.status == "success") offers = [];
                isLoadingOffers = false;
              });
            }
          }
        } catch (e) {
          debugPrint('❌ [Profile] Failed to parse offers JSON: $e');
          if (mounted) {
            setState(() {
              isLoadingOffers = false;
            });
          }
        }
      } else {
        debugPrint('❌ [Profile] Offers API Error: ${response.statusCode}');
        if (mounted) {
          setState(() {
            isLoadingOffers = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [Profile] Exception during getOffers: $e');
      if (mounted) {
        setState(() {
          isLoadingOffers = false;
        });
      }
    }
  }

  // Build Tabs Section
  Widget _buildTabsSection() {
    // Ensure TabController is initialized
    if (_tabController == null) {
      _tabController = TabController(length: 3, vsync: this);
      // Add listener if not already added
      if (_tabListener != null) {
        _tabController!.addListener(_tabListener!);
      }
    }
    
    List<Widget> tabViews = [
      _buildServicesTabContent(),
      _buildPackagesTabContent(),
      _buildOffersTabContent(),
    ];
    
    // Use ValueListenableBuilder or AnimatedBuilder to rebuild when tab changes
    return AnimatedBuilder(
      animation: _tabController!,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom Tab Bar with improved design
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCustomTabButton(
                      icon: Icons.build_circle_rounded,
                      label: "Services",
                      index: 0,
                    ),
                    _buildCustomTabButton(
                      icon: Icons.card_giftcard,
                      label: "Packages",
                      index: 1,
                    ),
                    _buildCustomTabButton(
                      icon: Icons.local_offer_rounded,
                      label: "Offers",
                      index: 2,
                    ),
                  ],
                ),
              ),
              // Tab Content - Dynamic list that expands to fit items
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _tabController!.index == 0
                    ? _buildServicesTabContent()
                    : _tabController!.index == 1
                        ? _buildPackagesTabContent()
                        : _buildOffersTabContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomTabButton({
    required IconData icon,
    required String label,
    required int index,
  }) {
    // Get current index from tab controller, default to 0 if null
    final currentIndex = _tabController?.index ?? 0;
    final isSelected = currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_tabController != null) {
            _tabController!.animateTo(index);
            // Force immediate update
            setState(() {});
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? ColorClass.base_color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: ColorClass.base_color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Icon(
                  icon,
                  key: ValueKey<bool>(isSelected),
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                style: TextStyle(
                  fontSize: isSelected ? 13 : 12,
                  fontFamily: isSelected ? "Pop600" : "Pop500",
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build Services Tab Content
  Widget _buildServicesTabContent() {
    if (isLoadingServices) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
        ),
      );
    }
    
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_rounded, color: Colors.grey[400], size: 64),
            const SizedBox(height: 16),
            Text(
              "No services yet",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add services to showcase your offerings",
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFullServiceCard(services[index]),
        );
      },
    );
  }

  // Build Packages Tab Content
  Widget _buildPackagesTabContent() {
    if (isLoadingPackages) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
        ),
      );
    }
    
    if (packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, color: Colors.grey[400], size: 64),
            const SizedBox(height: 16),
            Text(
              "No packages yet",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Create packages to offer bundled services",
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildCompactPackageCard(packages[index]),
        );
      },
    );
  }

  // Build Offers Tab Content
  Widget _buildOffersTabContent() {
    if (isLoadingOffers) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
        ),
      );
    }
    
    if (offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer, color: Colors.grey[400], size: 64),
            const SizedBox(height: 16),
            Text(
              "No offers yet",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Create special offers to attract customers",
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildCompactOfferCard(offers[index]),
        );
      },
    );
  }

  // Build Full Service Card with improved UI - matching packages/offers style
  Widget _buildFullServiceCard(ServicesListData service) {
    return InkWell(
      onTap: () async {
        // Navigate to edit service screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ModernAddServiceActivity(serviceToEdit: service),
          ),
        );
        // Refresh services list after returning
        if (result == true && mounted && venderId.isNotEmpty) {
          await getServices(context);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Image/Gradient and Status
            Container(
              height: 180,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  // Background Image or Gradient
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: service.coverImage != null && service.coverImage!.isNotEmpty
                        ? Image.network(
                            service.coverImage!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 180,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.blue[600]!,
                                      Colors.blue[400]!,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.build_circle_rounded,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 64,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue[600]!,
                                  Colors.blue[400]!,
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.build_circle_rounded,
                              color: Colors.white.withOpacity(0.3),
                              size: 64,
                            ),
                          ),
                  ),
                  // Gradient Overlay
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Status Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (service.isActive ?? true) 
                            ? Colors.green 
                            : Colors.grey[600]!,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        (service.isActive ?? true) ? "Active" : "Inactive",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Name (Main Title)
                  Text(
                    service.categoryName ?? service.serviceTitle ?? "Service",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: "Pop600",
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Service Title (if different from category)
                  if (service.serviceTitle != null && service.serviceTitle != service.categoryName)
                    Text(
                      service.serviceTitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: "Pop500",
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  // Description
                  if (service.about != null && service.about!.isNotEmpty)
                    Text(
                      service.about!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16),
                  // Info Cards Row
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // Price Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: ColorClass.base_color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_money, size: 18, color: ColorClass.base_color),
                            const SizedBox(width: 6),
                            Text(
                              "\$${service.price ?? 0}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ColorClass.base_color,
                                fontFamily: "Pop600",
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Duration Card
                      if (service.serviceDuration != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.blue[700]),
                              const SizedBox(width: 6),
                              Text(
                                service.serviceDuration!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Capacity Card
                      if (service.timeSlotCapacity != null && service.timeSlotCapacity!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people, size: 16, color: Colors.orange[700]),
                              const SizedBox(width: 6),
                              Text(
                                "${service.timeSlotCapacity} slots",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // Mobile Number (if available)
                  if (service.mobile != null && service.mobile!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            service.mobile!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Keep old method name for backward compatibility
  Widget _buildServiceCard(ServicesListData service) {
    return _buildFullServiceCard(service);
  }

  // Build Packages Card
  Widget _buildPackagesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Colors.purple,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Packages",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PackageListActivity(),
                      ),
                    ).then((_) {
                      if (venderId.isNotEmpty) {
                        getPackages(context);
                      }
                    });
                  },
                  child: Text(
                    "See All",
                    style: TextStyle(
                      color: ColorClass.base_color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoadingPackages)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (packages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.grey[400], size: 48),
                    const SizedBox(height: 8),
                    Text(
                      "No packages yet",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: packagePageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentPackagePage = index;
                      });
                    },
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildFullWidthPackageCard(packages[index]),
                      );
                    },
                  ),
                ),
                if (packages.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        packages.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentPackagePage == index
                                ? ColorClass.base_color
                                : Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Build Compact Package Card with more info
  Widget _buildCompactPackageCard(PackageData package) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditPackageActivity(packageData: package),
          ),
        ).then((result) {
          if (result == true) {
            // Refresh packages after editing
            getPackages(context);
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Image/Icon and Status
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple[600]!,
                    Colors.purple[400]!,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  // Package Image or Icon
                  Center(
                    child: Icon(
                      Icons.card_giftcard,
                      size: 64,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  // Status Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (package.isActive ?? true) 
                            ? Colors.green 
                            : Colors.grey[600]!,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        (package.isActive ?? true) ? "Active" : "Inactive",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Best Seller Badge
                  if (package.isBestSeller == true)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              "Best Seller",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Package Name
                  Text(
                    package.packageName ?? "Package",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: "Pop600",
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Description
                  if (package.packageDescription != null && package.packageDescription!.isNotEmpty)
                    Text(
                      package.packageDescription!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16),
                  // Price Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.purple[700], size: 24),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (package.smallVehiclePrice != null && package.smallVehiclePrice!.isNotEmpty)
                              Text(
                                "Small Vehicle: \$${package.smallVehiclePrice}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple[700],
                                ),
                              ),
                            if (package.largeVehiclePrice != null && package.largeVehiclePrice!.isNotEmpty)
                              Text(
                                "Large Vehicle: \$${package.largeVehiclePrice}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple[700],
                                ),
                              ),
                            if ((package.smallVehiclePrice == null || package.smallVehiclePrice!.isEmpty) &&
                                (package.largeVehiclePrice == null || package.largeVehiclePrice!.isEmpty) &&
                                package.packagePrice != null && package.packagePrice!.isNotEmpty)
                              Text(
                                "\$${package.packagePrice}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[700],
                                  fontFamily: "Pop600",
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Details Row
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      if (package.packageDuration != null && package.packageDuration!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 18, color: Colors.blue[600]),
                            const SizedBox(width: 6),
                            Text(
                              package.packageDuration!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      if (package.servicesIncluded != null && package.servicesIncluded!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.build_circle_rounded, size: 18, color: Colors.orange[600]),
                            const SizedBox(width: 6),
                            Text(
                              "${package.servicesIncluded!.length} services",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      if (package.packageTier != null && package.packageTier!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 18, color: Colors.amber[600]),
                            const SizedBox(width: 6),
                            Text(
                              package.packageTier!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Services Included - Show as Tags
                  if (package.servicesIncluded != null && package.servicesIncluded!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      "Services Included:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getServiceCategoryTags(package),
                    ),
                  ],
                  // Toggle Switch
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              (package.isActive ?? true) ? Icons.visibility : Icons.visibility_off,
                              color: (package.isActive ?? true) ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Visible to Users",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: package.isActive ?? true,
                          onChanged: (value) {
                            _togglePackageStatus(package, value);
                          },
                          activeThumbColor: ColorClass.base_color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get service category tags
  List<Widget> _getServiceCategoryTags(PackageData package) {
    if (package.servicesIncluded == null || package.servicesIncluded!.isEmpty) {
      return [];
    }

    // Get unique category names from services
    Set<String> categoryNames = {};
    
    for (String serviceId in package.servicesIncluded!) {
      // Find the service in the services list
      try {
        var service = services.firstWhere(
          (s) => s.sId == serviceId,
        );
        
        if (service.categoryName != null && service.categoryName!.isNotEmpty) {
          categoryNames.add(service.categoryName!);
        }
      } catch (e) {
        // Service not found in the list, skip it
      }
    }

    // If no categories found, show service count
    if (categoryNames.isEmpty) {
      return [
        Chip(
          label: Text(
            "${package.servicesIncluded!.length} service${package.servicesIncluded!.length > 1 ? 's' : ''}",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.blue[50],
          labelStyle: TextStyle(color: Colors.blue[700]),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ];
    }

    // Return chips for each category
    return categoryNames.map((categoryName) {
      return Chip(
        label: Text(
          categoryName,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        backgroundColor: ColorClass.base_color.withOpacity(0.1),
        labelStyle: TextStyle(color: ColorClass.base_color),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        avatar: Icon(
          Icons.check_circle,
          size: 16,
          color: ColorClass.base_color,
        ),
      );
    }).toList();
  }

  // Build Full Width Package Card for Carousel
  Widget _buildFullWidthPackageCard(PackageData package) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background Image or Color
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple[600]!,
                    Colors.purple[400]!,
                  ],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
            // Content Overlay
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          color: Colors.purple[200],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            package.packageName ?? "Package",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: "Pop600",
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      package.packageDescription ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.purple[600],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "\$${package.packagePrice ?? "0"}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Pop600",
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (package.isActive ?? true) ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (package.isActive ?? true) ? "Active" : "Inactive",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build Package Card (keeping for compatibility if needed elsewhere)
  Widget _buildPackageCard(PackageData package) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.packageName ?? "Package",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: "Pop600",
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              package.packageDescription ?? "",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "\$${package.packagePrice ?? "0"}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorClass.base_color,
                    fontFamily: "Pop600",
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (package.isActive ?? true) ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (package.isActive ?? true) ? "Active" : "Inactive",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build Offers Card
  Widget _buildOffersCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      color: Colors.orange,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Offers",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EnhancedOfferListScreen(),
                      ),
                    ).then((_) {
                      if (venderId.isNotEmpty) {
                        getOffers(context);
                      }
                    });
                  },
                  child: Text(
                    "See All",
                    style: TextStyle(
                      color: ColorClass.base_color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoadingOffers)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (offers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.local_offer, color: Colors.grey[400], size: 48),
                    const SizedBox(height: 8),
                    Text(
                      "No offers yet",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: offerPageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentOfferPage = index;
                      });
                    },
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildFullWidthOfferCard(offers[index]),
                      );
                    },
                  ),
                ),
                if (offers.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        offers.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentOfferPage == index
                                ? ColorClass.base_color
                                : Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Build Full Offer Card with improved UI - matching packages style
  Widget _buildCompactOfferCard(OfferListModelData offer) {
    final offerTitle = offer.title ?? "Special Offer";
    final description = offer.description ?? '';
    final imageUrl = offer.image;
    final discount = offer.discount;
    final validUntil = offer.validUntil;
    final validFrom = offer.validFrom;
    final categoryName = offer.service?.categoryName;
    
    // Format dates
    String? formattedValidUntil;
    if (validUntil != null && validUntil.isNotEmpty) {
      formattedValidUntil = _formatDate(validUntil);
    }
    String? formattedValidFrom;
    if (validFrom != null && validFrom.isNotEmpty) {
      formattedValidFrom = _formatDate(validFrom);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Image/Gradient
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange[400]!,
                      Colors.red[400]!,
                    ],
                  ),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.orange[400],
                              child: Icon(
                                Icons.local_offer_rounded,
                                color: Colors.white.withOpacity(0.3),
                                size: 48,
                              ),
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.local_offer_rounded,
                        color: Colors.white.withOpacity(0.3),
                        size: 48,
                      ),
              ),
              // Gradient Overlay
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // Status Badge - Top Right
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: offer.isCurrentlyActive 
                        ? Colors.green 
                        : Colors.grey[600]!,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        offer.isCurrentlyActive ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        offer.isCurrentlyActive ? "Active" : "Inactive",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Pop600",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Discount Badge - Top Left (only if discount exists and > 0)
              if (discount != null && discount > 0)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red[700],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.percent, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "$discount% OFF",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Pop600",
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Title and Category - Bottom Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offerTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Pop600",
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (categoryName != null && categoryName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            categoryName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: "Pop500",
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (description.isNotEmpty) const SizedBox(height: 16),
                // Info Row - Validity Dates
                if (formattedValidFrom != null || formattedValidUntil != null) ...[
                  Row(
                    children: [
                      // Valid From
                      if (formattedValidFrom != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.blue[700]),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "From",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        formattedValidFrom,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (formattedValidFrom != null && formattedValidUntil != null)
                        const SizedBox(width: 10),
                      // Valid Until
                      if (formattedValidUntil != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_busy, size: 16, color: Colors.orange[700]),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Until",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        formattedValidUntil,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                // Toggle Switch
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            offer.isCurrentlyActive ? Icons.visibility : Icons.visibility_off,
                            color: offer.isCurrentlyActive ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Visible to Users",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontFamily: "Pop500",
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: offer.isCurrentlyActive ?? false,
                        onChanged: (value) {
                          _toggleOfferStatus(offer, value);
                        },
                        activeThumbColor: ColorClass.base_color,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format date
  String _formatDate(String dateString) {
    try {
      // Try to parse the date string
      DateTime date = DateTime.parse(dateString);
      // Format as "DD MMM YYYY"
      return "${date.day} ${_getMonthName(date.month)} ${date.year}";
    } catch (e) {
      // If parsing fails, return the original string or a formatted version
      if (dateString.contains(' ')) {
        return dateString.split(' ')[0];
      }
      return dateString;
    }
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // Toggle Package Status
  Future<void> _togglePackageStatus(PackageData package, bool newStatus) async {
    if (packageDataManager == null || package.sId == null) {
      CommonWidget.errorShowSnackBarFor(context, "Unable to update package status");
      return;
    }

    try {
      // Optimistically update UI
      setState(() {
        package.isActive = newStatus;
      });

      var response = await packageDataManager!.togglePackageStatus(context, package.sId!, newStatus);

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(response.body);
        if (data['status'] == "success") {
          // Update from response data
          if (data['data'] != null) {
            final updatedPackage = data['data'];
            setState(() {
              // Find and update the package in the list
              final index = packages.indexWhere((p) => p.sId == package.sId);
              if (index != -1) {
                packages[index].isActive = updatedPackage['isActive'] ?? newStatus;
              } else {
                // If not found in list, update the passed package object
                package.isActive = updatedPackage['isActive'] ?? newStatus;
              }
            });
          }
          CommonWidget.successShowSnackBarFor(context, "Package status updated!");
        } else {
          // Revert on error
          setState(() {
            package.isActive = !newStatus;
          });
          CommonWidget.errorShowSnackBarFor(context, data['message'] ?? "Failed to update package status");
        }
      } else {
        // Revert on error
        setState(() {
          package.isActive = !newStatus;
        });
        CommonWidget.errorShowSnackBarFor(context, "Failed to update package status");
      }
    } catch (e) {
      // Revert on error
      setState(() {
        package.isActive = !newStatus;
      });
      CommonWidget.errorShowSnackBarFor(context, "Error updating package status: $e");
    }
  }

  // Toggle Offer Status
  Future<void> _toggleOfferStatus(OfferListModelData offer, bool newStatus) async {
    if (offerDataManager == null || offer.sId == null) {
      CommonWidget.errorShowSnackBarFor(context, "Unable to update offer status");
      return;
    }

    try {
      // Optimistically update UI - update isCurrentlyActive (backend uses this field)
      setState(() {
        offer.isCurrentlyActive = newStatus;
        offer.isActive = newStatus; // Also update isActive for consistency
      });

      var response = await offerDataManager!.postOfferUpdate(context, offer.sId!);

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(response.body);
        if (data['status'] == "success") {
          // Update from response data
          if (data['data'] != null) {
            final updatedOffer = data['data'];
            setState(() {
              // Find and update the offer in the list
              final index = offers.indexWhere((o) => o.sId == offer.sId);
              if (index != -1) {
                offers[index].isCurrentlyActive = updatedOffer['isCurrentlyActive'] ?? newStatus;
                offers[index].isActive = updatedOffer['isActive'] ?? newStatus;
              } else {
                // If not found in list, update the passed offer object
                offer.isCurrentlyActive = updatedOffer['isCurrentlyActive'] ?? newStatus;
                offer.isActive = updatedOffer['isActive'] ?? newStatus;
              }
            });
          }
          CommonWidget.successShowSnackBarFor(context, "Offer status updated!");
        } else {
          // Revert on error
          setState(() {
            offer.isCurrentlyActive = !newStatus;
            offer.isActive = !newStatus;
          });
          CommonWidget.errorShowSnackBarFor(context, data['message'] ?? "Failed to update offer status");
        }
      } else {
        // Revert on error
        setState(() {
          offer.isCurrentlyActive = !newStatus;
          offer.isActive = !newStatus;
        });
        CommonWidget.errorShowSnackBarFor(context, "Failed to update offer status");
      }
    } catch (e) {
      // Revert on error
      setState(() {
        offer.isCurrentlyActive = !newStatus;
        offer.isActive = !newStatus;
      });
      CommonWidget.errorShowSnackBarFor(context, "Error updating offer status: $e");
    }
  }

  // Build Full Width Offer Card for Carousel (keeping for compatibility)
  Widget _buildFullWidthOfferCard(OfferListModelData offer) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background Image or Color
            if (offer.image != null && offer.image!.isNotEmpty)
              Image.network(
                offer.image!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorClass.base_color,
                          ColorClass.base_color.withOpacity(0.7),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorClass.base_color,
                      ColorClass.base_color.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            // Content Overlay
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.orange[300],
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            offer.title ?? "Offer",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: "Pop600",
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offer.description ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (offer.discount != null && offer.discount! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${offer.discount}% OFF",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.all_inclusive,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Never expires",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (offer.isActive ?? true) ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (offer.isActive ?? true) ? "Active" : "Inactive",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build Offer Card (keeping for compatibility if needed elsewhere)
  Widget _buildOfferCard(OfferListModelData offer) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    offer.title ?? "Offer",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: "Pop600",
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              offer.description ?? "",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${offer.discount ?? 0}% OFF",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (offer.isActive ?? true) ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (offer.isActive ?? true) ? "Active" : "Inactive",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}