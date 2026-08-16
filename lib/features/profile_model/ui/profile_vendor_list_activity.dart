import 'dart:convert';
import 'dart:io';

import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/ModernDesignSystem.dart';
import 'package:car_app/Common/CommonBean.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/ContainerDecoration.dart';
import 'package:car_app/features/log_in/ui/new_login_activity.dart';
import 'package:car_app/features/resister_vendor_model/ui/edit_vendor_activity.dart';
import 'package:car_app/features/log_in/ui/profile_activity.dart';
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
import '../../packages_model/ui/add_package_activity.dart';
import '../../offer_model/ui/enhanced_offer_screen.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------
// Design tokens using global ColorClass
final _kBgColor       = Colors.white;
final _kGreen         = ColorClass.base_color;
final _kDark          = ColorClass.base_color;
final _kAccent        = ColorClass.base_color;

class ProfileVendorListActivity extends StatefulWidget {
  final bool isActive;
  const ProfileVendorListActivity({this.isActive = false, super.key});

  @override
  State<ProfileVendorListActivity> createState() =>
      _ProfileVendorListActivityState();
}

class _ProfileVendorListActivityState
    extends State<ProfileVendorListActivity>
    with SingleTickerProviderStateMixin {
  // ── data / managers ────────────────────────────────────────────────────────
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

  // ── lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    offerPageController = PageController();
    packagePageController = PageController();
    _tabController = TabController(length: 3, vsync: this);
    _tabListener = () {
      if (mounted && _tabController != null) {
        setState(() {});
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
            if (mounted) {
              await sharedPreferences!.setString(Constant.vendorId, recoveredId);
              setState(() {
                venderId = recoveredId;
              });
              debugPrint('=== Profile: vendorId recovered and stored: $venderId ===');
            }
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
    if (venderId.isNotEmpty &&
        packages.isEmpty &&
        offers.isEmpty &&
        services.isEmpty &&
        !isLoadingPackages &&
        !isLoadingOffers &&
        !isLoadingServices) {
      getPackages(context);
      getOffers(context);
      getServices(context);
    }
  }

  @override
  void didUpdateWidget(covariant ProfileVendorListActivity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      debugPrint('Profile tab became active - triggering refresh');
      init();
    }
  }

  void init() async {
    start();
  }

  start() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      if (sharedPreferences == null) return;

      dataManager        = ProfileListDataManager(sharedPreferences!);
      packageDataManager = PackageDataManager(sharedPreferences!);
      offerDataManager   = OfferDataManager(sharedPreferences!);
      servicesDataManager = ServicesDataManager(sharedPreferences!);
      loginDataManager   = LoginDataManager(sharedPreferences!);

      venderId = (sharedPreferences!.getString(Constant.vendorId) ?? "").trim();
      debugPrint('=== Profile Screen: Current vendorId: $venderId ===');

      await getUser(context);

      venderId = (sharedPreferences!.getString(Constant.vendorId) ?? "").trim();

      if (venderId.isEmpty) {
        await _recoverVendorId();
      }

      if (venderId.isNotEmpty) {
        debugPrint('=== Profile: Starting data fetch for vendor: $venderId ===');
        getPackages(context);
        getOffers(context);
        getServices(context);
      } else {
        debugPrint('=== Profile: No valid vendorId found even after recovery attempt ===');
      }
    } catch (e) {}
  }

  // ── build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Gen-Z gradient header ──────────────────────────────────────
            _buildHeader(),
            // ── scrollable body ───────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: _kGreen,
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    children: [
                      // vendor / shop card
                      if (dataNew != null &&
                          dataNew!.vendorDetails!.isNotEmpty &&
                          dataNew!.vendorDetails![0].sId != "")
                        _buildShopDetailsCard()
                      else
                        _buildAddShopCard(),

                      const SizedBox(height: 20),

                      // stats pills
                      if (venderId.isNotEmpty) _buildStatsPills(),

                      if (venderId.isNotEmpty) const SizedBox(height: 20),

                      // tabs
                      if (venderId.isNotEmpty) _buildTabsSection(),

                      const SizedBox(height: 20),

                      // settings / account card
                      _buildSettingsCard(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final firstName = dataNew?.firstName ?? "";
    final lastName  = dataNew?.lastName  ?? "";
    final phone     = dataNew?.mobile    ?? "";
    final email     = dataNew?.email     ?? "";
    final avatarUrl = dataNew?.vendorDetails != null &&
            dataNew!.vendorDetails!.isNotEmpty
        ? (dataNew!.vendorDetails![0].displayPicture ?? "")
        : "";

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff192028), Color(0xff2A3542), Color(0xff0D1116)],
            stops: [0.0, 0.55, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // decorative artistic blobs
            Positioned(
              top: -30,
              right: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 60,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
      Column(
        children: [
          // top row: back + logout
          Row(
            children: [
              _glassButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    CommonWidget.safePop(context);
                  } else {
                    CommonWidget.navigateToKillAllScreen(
                        context, const DashboardActivity());
                  }
                },
              ),
              const Spacer(),
              _glassButton(
                icon: Icons.logout_rounded,
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // avatar + name row
          Row(
            children: [
              // avatar
              InkWell(
                onTap: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (_) => const ProfileActivity()))
                      .then((v) {
                    if (v == true) getUser(context);
                  });
                },
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: _kDark,
                    child: avatarUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              avatarUrl,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _avatarFallback(),
                            ),
                          )
                        : _avatarFallback(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // name / subtitle
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) => const ProfileActivity()))
                        .then((v) {
                      if (v == true) getUser(context);
                    });
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      firstName.isNotEmpty
                          ? "$firstName $lastName".trim()
                          : "Your Profile",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded,
                              size: 13, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.email_rounded,
                              size: 13, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.white70),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // edit button
              InkWell(
                onTap: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (_) => const EditVendorActivity()))
                      .then((v) {
                    if (v == true) getUser(context);
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 15, color: _kDark),
                      const SizedBox(width: 4),
                      Text(
                        "Edit",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
            ],
          ),
        ),
      );
  }

  Widget _avatarFallback() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_kGreen, _kAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 38),
    );
  }

  Widget _glassButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // ── stats pills ─────────────────────────────────────────────────────────────
  Widget _buildStatsPills() {
    return Row(
      children: [
        _statPill(
          icon: Icons.build_circle_rounded,
          count: services.length,
          label: "Services",
          accent: ModernDesignSystem.accentFor(1),
        ),
        const SizedBox(width: 10),
        _statPill(
          icon: Icons.card_giftcard_rounded,
          count: packages.length,
          label: "Packages",
          accent: ModernDesignSystem.accentFor(4),
        ),
        const SizedBox(width: 10),
        _statPill(
          icon: Icons.local_offer_rounded,
          count: offers.length,
          label: "Offers",
          accent: ModernDesignSystem.accentFor(2),
        ),
      ],
    );
  }

  Widget _statPill({
    required IconData icon,
    required int count,
    required String label,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            ModernDesignSystem.iconTile(icon, color: accent, size: 38, iconSize: 20),
            const SizedBox(height: 6),
            Text(
              "$count",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── shop details card ────────────────────────────────────────────────────────
  Widget _buildShopDetailsCard() {
    final shopAccent = ModernDesignSystem.accentFor(1); // indigo, contrasts the green page header
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusXL),
        boxShadow: ModernDesignSystem.shadowLarge,
      ),
      child: Column(
        children: [
          // card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [shopAccent.withOpacity(0.12), shopAccent.withOpacity(0.03)],
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
                ModernDesignSystem.iconTile(
                  Icons.store_rounded,
                  color: shopAccent,
                  size: 38,
                  iconSize: 20,
                  circle: false,
                ),
                const SizedBox(width: 12),
                Text(
                  "Shop Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kDark,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) => const EditVendorActivity()))
                        .then((v) {
                      if (v == true) getUser(context);
                    });
                  },
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusRound),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: shopAccent,
                      borderRadius: BorderRadius.circular(ModernDesignSystem.radiusRound),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          "Edit",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // card body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // shop avatar
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [shopAccent, ModernDesignSystem.accentFor(4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: ModernDesignSystem.getColoredShadow(shopAccent, opacity: 0.25),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: shopAccent.withOpacity(0.1),
                        child: ClipOval(
                          child: Image.network(
                            dataNew?.vendorDetails![0].displayPicture ?? "",
                            height: 92,
                            width: 92,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.store_rounded,
                              size: 44,
                              color: shopAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow(Icons.storefront_rounded, "Shop Name",
                    dataNew?.vendorDetails![0].displayName ?? "", ModernDesignSystem.accentFor(1)),
                _buildDetailRow(Icons.email_rounded, "Email",
                    dataNew?.vendorDetails![0].officialEmail ?? "N/A", ModernDesignSystem.accentFor(2)),
                _buildDetailRow(Icons.phone_rounded,
                    "Mobile", dataNew?.vendorDetails![0].mobile ?? "", ModernDesignSystem.accentFor(3)),
                _buildDetailRow(
                  Icons.access_time_filled_rounded,
                  "Shop Hours",
                  "${CommonWidget.convertToLocalTimeWithAMPM(dataNew?.vendorDetails![0].openTime ?? "")} - ${CommonWidget.convertToLocalTimeWithAMPM(dataNew?.vendorDetails![0].closeTime ?? "")}",
                  ModernDesignSystem.accentFor(4),
                ),
                if (dataNew?.vendorDetails![0].daysAvailable != null &&
                    dataNew!.vendorDetails![0].daysAvailable!.isNotEmpty)
                  _buildDetailRow(
                    Icons.event_available_rounded,
                    "Days",
                    dataNew!.vendorDetails![0].daysAvailable!.join(", "),
                    ModernDesignSystem.accentFor(5),
                  ),
                _buildDetailRow(Icons.location_on_rounded, "Location",
                    dataNew?.vendorDetails![0].location!.name ?? "", ModernDesignSystem.accentFor(0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── add shop card ────────────────────────────────────────────────────────────
  Widget _buildAddShopCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.12),
                  Colors.orange.withOpacity(0.04),
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
                Icon(Icons.add_business_rounded,
                    color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Text(
                  "Add Your Shop",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.store_rounded,
                      size: 48, color: Colors.orange),
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
                        .push(MaterialPageRoute(
                            builder: (_) =>
                                const RegistorVendorActivitySimple()))
                        .then((v) {
                      if (v == true) getUser(context);
                    });
                  },
                  icon: const Icon(Icons.add_business_rounded),
                  label: const Text("Add Shop"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── settings card ────────────────────────────────────────────────────────────
  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusXL),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Icon(Icons.settings_outlined, color: Colors.grey[500], size: 20),
                const SizedBox(width: 10),
                const Text(
                  "Account Settings",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _settingsItem(
            icon: Icons.person_outline_rounded,
            label: "Edit Profile",
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => const ProfileActivity()))
                  .then((v) {
                if (v == true) getUser(context);
              });
            },
          ),
          Divider(height: 1, indent: 20, color: Colors.grey[100]),
          _settingsItem(
            icon: Icons.logout_rounded,
            label: "Logout",
            onTap: () => _showLogoutDialog(context),
          ),
          Divider(height: 1, indent: 20, color: Colors.grey[100]),
          _settingsItem(
            icon: Icons.delete_outline_rounded,
            label: "Delete Account",
            textColor: Colors.red[400],
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final color = textColor ?? Colors.grey[800]!;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[350], size: 18),
          ],
        ),
      ),
    );
  }

  // ── detail row ───────────────────────────────────────────────────────────────
  Widget _buildDetailRow(IconData icon, String label, String value, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ModernDesignSystem.iconTile(icon, color: accent, size: 34, iconSize: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
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
          ),
        ],
      ),
    );
  }

  // ── dialogs ──────────────────────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Logout",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content:
              const Text("Are you sure you want to logout?"),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Delete Account",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
              "Are you sure you want to delete your account? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => CommonWidget.safePop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                textStyle:
                    const TextStyle(fontWeight: FontWeight.bold),
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
        CommonWidget.getTextWidget400(value, 14),
      ],
    );
  }

  // ── data methods ─────────────────────────────────────────────────────────────
  deleteAccount() async {
    var response = await dataManager!.deleteAccount(context);
    var data = CommonBean.fromJson(jsonDecode(response.body));
    if (mounted && data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      CommonWidget.navigateToKillAllScreen(
          context, const NewLoginActivity());
    } else if (mounted) {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  getUser(BuildContext context) async {
    var response = await dataManager!.getUserDetails(context);
    var data = VendorDetailBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      if (mounted && data.data!.isNotEmpty) {
        setState(() {
          dataNew = data.data![0];
        });
        sharedPreferences!
            .setString(Constant.firstName, data.data?[0].firstName ?? "");
        sharedPreferences!
            .setString(Constant.lastName, data.data?[0].lastName ?? "");
        sharedPreferences!
            .setString(Constant.email, data.data?[0].email ?? "");
        sharedPreferences!
            .setString(Constant.mobile, data.data?[0].mobile ?? "");
        sharedPreferences!.setString(
            Constant.isNewUser, data.data?[0].isNewUser.toString() ?? "");
        sharedPreferences!
            .setString(Constant.roleName, data.data?[0].roleName ?? "");
        sharedPreferences!
            .setString(Constant.id, data.data?[0].sId.toString() ?? "");
        sharedPreferences!
            .setString(Constant.image, data.data?[0].image ?? "");
        if (data.data![0].vendorDetails!.isNotEmpty) {
          String newVendorId = (data.data?[0].vendorDetails![0].sId.toString() ?? "").trim();
          sharedPreferences!.setString(Constant.vendorId, newVendorId);
          if (mounted) {
            setState(() {
              venderId = newVendorId;
            });
          }
          if (venderId.isNotEmpty && mounted) {
            getPackages(context);
            getOffers(context);
            getServices(context);
          }
        }
      }
    } else if (mounted) {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  Future<void> getPackages(BuildContext context) async {
    if (packageDataManager == null) return;
    if (!mounted) return;
    setState(() => isLoadingPackages = true);
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
                packages = data.data!;
                isLoadingPackages = false;
              });
              debugPrint('📦 [Profile] Successfully loaded ${packages.length} packages.');
            }
          } else {
            debugPrint('⚠️ [Profile] Packages API success status but data issues: ${data.message}');
            if (mounted) {
              setState(() {
                if (data.status == "success") packages = [];
                isLoadingPackages = false;
              });
            }
          }
        } catch (parseError) {
          debugPrint('❌ [Profile] Failed to parse packages JSON: $parseError');
          if (mounted) setState(() => isLoadingPackages = false);
        }
      } else {
        debugPrint('❌ [Profile] Packages API Error Status: ${response.statusCode}');
        if (mounted) setState(() => isLoadingPackages = false);
      }
    } catch (e) {
      debugPrint('❌ [Profile] Exception during getPackages: $e');
      if (mounted) setState(() => isLoadingPackages = false);
    }
  }

  Future<void> getServices(BuildContext context) async {
    if (servicesDataManager == null) return;
    if (!mounted) return;
    setState(() => isLoadingServices = true);
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
          if (mounted) setState(() => isLoadingServices = false);
        }
      } else {
        debugPrint('❌ [Profile] Services API Error: ${response.statusCode}');
        if (mounted) setState(() => isLoadingServices = false);
      }
    } catch (e) {
      debugPrint('❌ [Profile] Exception during getServices: $e');
      if (mounted) setState(() => isLoadingServices = false);
    }
  }

  Future<void> getOffers(BuildContext context) async {
    if (offerDataManager == null) return;
    if (!mounted) return;
    setState(() => isLoadingOffers = true);
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
          if (mounted) setState(() => isLoadingOffers = false);
        }
      } else {
        debugPrint('❌ [Profile] Offers API Error: ${response.statusCode}');
        if (mounted) setState(() => isLoadingOffers = false);
      }
    } catch (e) {
      debugPrint('❌ [Profile] Exception during getOffers: $e');
      if (mounted) setState(() => isLoadingOffers = false);
    }
  }

  // ── tabs section ─────────────────────────────────────────────────────────────
  Widget _buildTabsSection() {
    if (_tabController == null) {
      _tabController = TabController(length: 3, vsync: this);
      if (_tabListener != null) {
        _tabController!.addListener(_tabListener!);
      }
    }

    return AnimatedBuilder(
      animation: _tabController!,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // tab bar
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    _buildCustomTabButton(
                        icon: Icons.build_circle_rounded,
                        label: "Services",
                        index: 0,
                        accent: ModernDesignSystem.accentFor(1)),
                    _buildCustomTabButton(
                        icon: Icons.card_giftcard_rounded,
                        label: "Packages",
                        index: 1,
                        accent: ModernDesignSystem.accentFor(4)),
                    _buildCustomTabButton(
                        icon: Icons.local_offer_rounded,
                        label: "Offers",
                        index: 2,
                        accent: ModernDesignSystem.accentFor(2)),
                  ],
                ),
              ),
              // tab content
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
    required Color accent,
  }) {
    final currentIndex = _tabController?.index ?? 0;
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_tabController != null) {
            _tabController!.animateTo(index);
            setState(() {});
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          padding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isSelected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child)),
                child: Icon(
                  icon,
                  key: ValueKey<bool>(isSelected),
                  color: isSelected ? Colors.white : Colors.grey[500],
                  size: 20,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: isSelected ? 12 : 11,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[500],
                ),
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

  // ── services tab ─────────────────────────────────────────────────────────────
  Widget _buildServicesTabContent() {
    if (isLoadingServices) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
            child: CircularProgressIndicator(
                color: _kGreen, strokeWidth: 2.5)),
      );
    }
    if (services.isEmpty) {
      return _emptyState(
          icon: Icons.build_circle_rounded,
          title: "No services yet",
          sub: "Add services to showcase your offerings",
          accent: ModernDesignSystem.accentFor(1),
          ctaLabel: "Add Service",
          onCta: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ModernAddServiceActivity()),
            );
            if (result == true && mounted && venderId.isNotEmpty) {
              await getServices(context);
            }
          });
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildFullServiceCard(services[index]),
      ),
    );
  }

  // ── packages tab ─────────────────────────────────────────────────────────────
  Widget _buildPackagesTabContent() {
    if (isLoadingPackages) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
            child: CircularProgressIndicator(
                color: _kGreen, strokeWidth: 2.5)),
      );
    }
    if (packages.isEmpty) {
      return _emptyState(
          icon: Icons.card_giftcard_rounded,
          title: "No packages yet",
          sub: "Create packages to offer bundled services",
          accent: ModernDesignSystem.accentFor(4),
          ctaLabel: "Create Package",
          onCta: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPackageActivity()),
            );
            if (result == true && mounted && venderId.isNotEmpty) {
              await getPackages(context);
            }
          });
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: packages.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildCompactPackageCard(packages[index]),
      ),
    );
  }

  // ── offers tab ───────────────────────────────────────────────────────────────
  Widget _buildOffersTabContent() {
    if (isLoadingOffers) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
            child: CircularProgressIndicator(
                color: _kGreen, strokeWidth: 2.5)),
      );
    }
    if (offers.isEmpty) {
      return _emptyState(
          icon: Icons.local_offer_rounded,
          title: "No offers yet",
          sub: "Create special offers to attract customers",
          accent: ModernDesignSystem.accentFor(2),
          ctaLabel: "Create Offer",
          onCta: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EnhancedOfferScreen()),
            );
            if (result == true && mounted && venderId.isNotEmpty) {
              await getOffers(context);
            }
          });
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: offers.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildCompactOfferCard(offers[index]),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String sub,
    required Color accent,
    required String ctaLabel,
    required VoidCallback onCta,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 40),
          ),
          const SizedBox(height: 18),
          Text(title,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.4)),
          const SizedBox(height: 20),
          InkWell(
            onTap: onCta,
            borderRadius: BorderRadius.circular(ModernDesignSystem.radiusRound),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusRound),
                boxShadow: ModernDesignSystem.getColoredShadow(accent, opacity: 0.3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(ctaLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── service card ─────────────────────────────────────────────────────────────
  Widget _buildFullServiceCard(ServicesListData service) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  ModernAddServiceActivity(serviceToEdit: service)),
        );
        if (result == true && mounted && venderId.isNotEmpty) {
          await getServices(context);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(top: 22), // room for the badge to float above the card
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: ModernDesignSystem.shadowLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // cover image / gradient header
            Container(
              height: 170,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: service.coverImage != null &&
                            service.coverImage!.isNotEmpty
                        ? Image.network(
                            service.coverImage!,
                            width: double.infinity,
                            height: 170,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _serviceGradientBg(),
                          )
                        : _serviceGradientBg(),
                  ),
                  // dark overlay
                  Container(
                    width: double.infinity,
                    height: 170,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
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
                  // status badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _statusBadge(
                        active: service.isActive ?? true),
                  ),
                  // floating category icon badge, overlaps the card edge below
                  Positioned(
                    left: 16,
                    bottom: -22,
                    child: Container(
                      width: 52,
                      height: 52,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: ModernDesignSystem.shadowMedium,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [_kGreen, ModernDesignSystem.accentFor(1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.build_circle_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.categoryName ??
                        service.serviceTitle ??
                        "Service",
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (service.serviceTitle != null &&
                      service.serviceTitle != service.categoryName) ...[
                    const SizedBox(height: 3),
                    Text(
                      service.serviceTitle!,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (service.about != null &&
                      service.about!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      service.about!,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 18),
                  // one clean price + meta row instead of a row of pills
                  Row(
                    children: [
                      Text(
                        "\$${service.price ?? 0}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: ModernDesignSystem.accentFor(0),
                        ),
                      ),
                      if (service.serviceDuration != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 3,
                          height: 3,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          service.serviceDuration!,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600]),
                        ),
                      ],
                      if (service.timeSlotCapacity != null &&
                          service.timeSlotCapacity!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 3,
                          height: 3,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          service.timeSlotCapacity!,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                  if (service.mobile != null &&
                      service.mobile!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.phone_rounded,
                            size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          service.mobile!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceGradientBg() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kDark, _kGreen],
        ),
      ),
      child: Icon(
        Icons.build_circle_rounded,
        color: Colors.white.withOpacity(0.25),
        size: 64,
      ),
    );
  }

  // Keep old method name for backward compatibility
  Widget _buildServiceCard(ServicesListData service) {
    return _buildFullServiceCard(service);
  }

  // ── compact package card ──────────────────────────────────────────────────────
  Widget _buildCompactPackageCard(PackageData package) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EditPackageActivity(packageData: package)),
        ).then((result) {
          if (result == true) getPackages(context);
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: _kGreen, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // gradient header
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kDark, _kGreen],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      size: 64,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _statusBadge(
                        active: package.isActive ?? true),
                  ),
                  if (package.isBestSeller == true)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              "Best Seller",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.packageName ?? "Package",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (package.packageDescription != null &&
                      package.packageDescription!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      package.packageDescription!,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
                  // price block
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money_rounded,
                            color: _kGreen, size: 22),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (package.smallVehiclePrice != null &&
                                package.smallVehiclePrice!.isNotEmpty)
                              Text(
                                "Small Vehicle: \$${package.smallVehiclePrice}",
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kGreen),
                              ),
                            if (package.largeVehiclePrice != null &&
                                package.largeVehiclePrice!.isNotEmpty)
                              Text(
                                "Large Vehicle: \$${package.largeVehiclePrice}",
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kGreen),
                              ),
                            if ((package.smallVehiclePrice == null ||
                                    package.smallVehiclePrice!.isEmpty) &&
                                (package.largeVehiclePrice == null ||
                                    package.largeVehiclePrice!.isEmpty) &&
                                package.packagePrice != null &&
                                package.packagePrice!.isNotEmpty)
                              Text(
                                "\$${package.packagePrice}",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _kGreen),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 14,
                    runSpacing: 10,
                    children: [
                      if (package.packageDuration != null &&
                          package.packageDuration!.isNotEmpty)
                        _infoChip(
                            icon: Icons.access_time_rounded,
                            label: package.packageDuration!,
                            color: Colors.blue[700]!),
                      if (package.servicesIncluded != null &&
                          package.servicesIncluded!.isNotEmpty)
                        _infoChip(
                            icon: Icons.build_circle_rounded,
                            label:
                                "${package.servicesIncluded!.length} services",
                            color: Colors.orange[700]!),
                      if (package.packageTier != null &&
                          package.packageTier!.isNotEmpty)
                        _infoChip(
                            icon: Icons.star_rounded,
                            label: package.packageTier!,
                            color: Colors.amber[700]!),
                    ],
                  ),
                  // services tags
                  if (package.servicesIncluded != null &&
                      package.servicesIncluded!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      "Services Included:",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _getServiceCategoryTags(package),
                    ),
                  ],
                  // visibility toggle
                  const SizedBox(height: 14),
                  _visibilityToggle(
                    isActive: package.isActive ?? true,
                    onChanged: (v) =>
                        _togglePackageStatus(package, v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── helper widgets ────────────────────────────────────────────────────────────
  Widget _statusBadge({required bool active}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? _kGreen : Colors.grey[600]!,
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusRound),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            active ? "Active" : "Inactive",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }


  Widget _infoChip(
      {required IconData icon,
      required String label,
      required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }

  Widget _visibilityToggle(
      {required bool isActive,
      required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: isActive ? _kGreen : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "Visible to Users",
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
            ],
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeColor: _kGreen,
          ),
        ],
      ),
    );
  }

  // ── service category tags ─────────────────────────────────────────────────────
  List<Widget> _getServiceCategoryTags(PackageData package) {
    if (package.servicesIncluded == null ||
        package.servicesIncluded!.isEmpty) return [];

    Set<String> categoryNames = {};
    for (String serviceId in package.servicesIncluded!) {
      try {
        var service =
            services.firstWhere((s) => s.sId == serviceId);
        if (service.categoryName != null &&
            service.categoryName!.isNotEmpty) {
          categoryNames.add(service.categoryName!);
        }
      } catch (e) {
        // not found
      }
    }

    if (categoryNames.isEmpty) {
      return [
        Chip(
          label: Text(
            "${package.servicesIncluded!.length} service${package.servicesIncluded!.length > 1 ? 's' : ''}",
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.blue[50],
          labelStyle: TextStyle(color: Colors.blue[700]),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ];
    }

    return categoryNames.map((name) {
      return Chip(
        label: Text(name,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500)),
        backgroundColor: _kGreen.withOpacity(0.10),
        labelStyle: TextStyle(color: _kGreen),
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        avatar: Icon(Icons.check_circle_rounded,
            size: 15, color: _kGreen),
      );
    }).toList();
  }

  // ── offer card ────────────────────────────────────────────────────────────────
  Widget _buildCompactOfferCard(OfferListModelData offer) {
    final offerTitle  = offer.title ?? "Special Offer";
    final description = offer.description ?? '';
    final imageUrl    = offer.image;
    final discount    = offer.discount;
    final validUntil  = offer.validUntil;
    final validFrom   = offer.validFrom;
    final categoryName = offer.service?.categoryName;

    String? formattedValidUntil;
    if (validUntil != null && validUntil.isNotEmpty) {
      formattedValidUntil = _formatDate(validUntil);
    }
    String? formattedValidFrom;
    if (validFrom != null && validFrom.isNotEmpty) {
      formattedValidFrom = _formatDate(validFrom);
    }


    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedOfferScreen(offerToEdit: offer),
          ),
        ).then((_) {
          String? vendorId = sharedPreferences!.getString(Constant.vendorId);
          if (vendorId != null && vendorId.isNotEmpty) {
            getOffers(context);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _kGreen, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // image header
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kDark, _kGreen],
                  ),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.local_offer_rounded,
                            color: Colors.white.withOpacity(0.2),
                            size: 48,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.local_offer_rounded,
                        color: Colors.white.withOpacity(0.2),
                        size: 48,
                      ),
              ),
              // gradient overlay
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
              ),
              // status badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: offer.isCurrentlyActive
                        ? _kGreen
                        : Colors.grey[600]!,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        offer.isCurrentlyActive
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        offer.isCurrentlyActive
                            ? "Active"
                            : "Inactive",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              // discount badge
              if (discount != null && discount > 0)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.percent_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "$discount% OFF",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              // title overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offerTitle,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (categoryName != null &&
                          categoryName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            categoryName,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          // body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (description.isNotEmpty)
                  const SizedBox(height: 14),
                // validity row
                if (formattedValidFrom != null ||
                    formattedValidUntil != null) ...[
                  Row(
                    children: [
                      if (formattedValidFrom != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.09),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 14,
                                    color: Colors.blue[700]),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("From",
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue[600],
                                              fontWeight:
                                                  FontWeight.w500)),
                                      Text(formattedValidFrom,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[700],
                                              fontWeight:
                                                  FontWeight.w700),
                                          overflow:
                                              TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (formattedValidFrom != null &&
                          formattedValidUntil != null)
                        const SizedBox(width: 10),
                      if (formattedValidUntil != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  Colors.orange.withOpacity(0.09),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_busy_rounded,
                                    size: 14,
                                    color: Colors.orange[700]),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Until",
                                          style: TextStyle(
                                              fontSize: 10,
                                              color:
                                                  Colors.orange[600],
                                              fontWeight:
                                                  FontWeight.w500)),
                                      Text(formattedValidUntil,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Colors.orange[700],
                                              fontWeight:
                                                  FontWeight.w700),
                                          overflow:
                                              TextOverflow.ellipsis),
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
                // visibility toggle
                _visibilityToggle(
                  isActive: offer.isCurrentlyActive ?? false,
                  onChanged: (v) => _toggleOfferStatus(offer, v),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  // ── carousel cards (kept for backward compat) ─────────────────────────────────
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
                Row(
                  children: [
                    Icon(Icons.card_giftcard_rounded,
                        color: _kGreen, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      "Packages",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _kDark),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const PackageListActivity()),
                    ).then((_) {
                      if (venderId.isNotEmpty) getPackages(context);
                    });
                  },
                  child: Text("See All",
                      style: TextStyle(
                          color: _kGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ],
            ),
          ),
          if (isLoadingPackages)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(color: _kGreen)),
            )
          else if (packages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.card_giftcard_rounded,
                        color: Colors.grey[300], size: 48),
                    const SizedBox(height: 8),
                    Text("No packages yet",
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 14)),
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
                    onPageChanged: (index) =>
                        setState(() => currentPackagePage = index),
                    itemCount: packages.length,
                    itemBuilder: (context, index) => Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildFullWidthPackageCard(
                          packages[index]),
                    ),
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
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentPackagePage == index
                                ? _kGreen
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

  Widget _buildFullWidthPackageCard(PackageData package) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditPackageActivity(packageData: package),
          ),
        ).then((_) {
          String? vendorId = sharedPreferences!.getString(Constant.vendorId);
          if (vendorId != null && vendorId.isNotEmpty) {
            getPackages(context);
          }
        });
      },
      child: Container(
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
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kDark, _kGreen],
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
                        const Icon(Icons.card_giftcard_rounded,
                            color: Colors.white70, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            package.packageName ?? "Package",
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      package.packageDescription ?? "",
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: _kGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "\$${package.packagePrice ?? "0"}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        const Spacer(),
                        _statusBadge(
                            active: package.isActive ?? true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildPackageCard(PackageData package) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditPackageActivity(packageData: package),
          ),
        ).then((_) {
          String? vendorId = sharedPreferences!.getString(Constant.vendorId);
          if (vendorId != null && vendorId.isNotEmpty) {
            getPackages(context);
          }
        });
      },
      child: Container(
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
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              package.packageDescription ?? "",
              style:
                  TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _kGreen),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (package.isActive ?? true)
                        ? _kGreen
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (package.isActive ?? true)
                        ? "Active"
                        : "Inactive",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

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
                Row(
                  children: const [
                    Icon(Icons.local_offer_rounded,
                        color: Colors.orange, size: 24),
                    SizedBox(width: 12),
                    Text(
                      "Offers",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const EnhancedOfferListScreen()),
                    ).then((_) {
                      if (venderId.isNotEmpty) getOffers(context);
                    });
                  },
                  child: Text("See All",
                      style: TextStyle(
                          color: _kGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ],
            ),
          ),
          if (isLoadingOffers)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(color: _kGreen)),
            )
          else if (offers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.local_offer_rounded,
                        color: Colors.grey[300], size: 48),
                    const SizedBox(height: 8),
                    Text("No offers yet",
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 14)),
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
                    onPageChanged: (index) =>
                        setState(() => currentOfferPage = index),
                    itemCount: offers.length,
                    itemBuilder: (context, index) => Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child:
                          _buildFullWidthOfferCard(offers[index]),
                    ),
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
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentOfferPage == index
                                ? _kGreen
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

  Widget _buildFullWidthOfferCard(OfferListModelData offer) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedOfferScreen(offerToEdit: offer),
          ),
        ).then((_) {
          String? vendorId = sharedPreferences!.getString(Constant.vendorId);
          if (vendorId != null && vendorId.isNotEmpty) {
            getOffers(context);
          }
        });
      },
      child: Container(
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
            if (offer.image != null && offer.image!.isNotEmpty)
              Image.network(
                offer.image!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_kDark, _kGreen],
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kDark, _kGreen],
                  ),
                ),
              ),
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
                        Icon(Icons.local_fire_department_rounded,
                            color: Colors.orange[300], size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            offer.title ?? "Offer",
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
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
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  // ── date helpers ──────────────────────────────────────────────────────────────
  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return "${date.day} ${_getMonthName(date.month)} ${date.year}";
    } catch (e) {
      if (dateString.contains(' ')) return dateString.split(' ')[0];
      return dateString;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  // ── toggle handlers ───────────────────────────────────────────────────────────
  Future<void> _togglePackageStatus(
      PackageData package, bool newStatus) async {
    if (packageDataManager == null || package.sId == null) {
      CommonWidget.errorShowSnackBarFor(
          context, "Unable to update package status");
      return;
    }
    try {
      setState(() => package.isActive = newStatus);
      var response = await packageDataManager!
          .togglePackageStatus(context, package.sId!, newStatus);
      
      if (!mounted) return;
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(response.body);
        if (data['status'] == "success") {
          if (data['data'] != null) {
            final updatedPackage = data['data'];
            setState(() {
              final index =
                  packages.indexWhere((p) => p.sId == package.sId);
              if (index != -1) {
                packages[index].isActive =
                    updatedPackage['isActive'] ?? newStatus;
              } else {
                package.isActive =
                    updatedPackage['isActive'] ?? newStatus;
              }
            });
          }
          if (context.mounted) {
            CommonWidget.successShowSnackBarFor(
                context, "Package status updated!");
          }
        } else {
          setState(() => package.isActive = !newStatus);
          if (context.mounted) {
            CommonWidget.errorShowSnackBarFor(context,
                data['message'] ?? "Failed to update package status");
          }
        }
      } else {
        setState(() => package.isActive = !newStatus);
        if (context.mounted) {
          CommonWidget.errorShowSnackBarFor(
              context, "Failed to update package status");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => package.isActive = !newStatus);
      }
      if (context.mounted) {
        CommonWidget.errorShowSnackBarFor(
            context, "Error updating package status: $e");
      }
    }
  }

  Future<void> _toggleOfferStatus(
      OfferListModelData offer, bool newStatus) async {
    if (offerDataManager == null || offer.sId == null) {
      CommonWidget.errorShowSnackBarFor(
          context, "Unable to update offer status");
      return;
    }
    try {
      setState(() {
        offer.isCurrentlyActive = newStatus;
        offer.isActive = newStatus;
      });
      var response =
          await offerDataManager!.postOfferUpdate(context, offer.sId!);
      
      if (!mounted) return;
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(response.body);
        if (data['status'] == "success") {
          if (data['data'] != null) {
            final updatedOffer = data['data'];
            setState(() {
              final index =
                  offers.indexWhere((o) => o.sId == offer.sId);
              if (index != -1) {
                offers[index].isCurrentlyActive =
                    updatedOffer['isCurrentlyActive'] ?? newStatus;
                offers[index].isActive =
                    updatedOffer['isActive'] ?? newStatus;
              } else {
                offer.isCurrentlyActive =
                    updatedOffer['isCurrentlyActive'] ?? newStatus;
                offer.isActive =
                    updatedOffer['isActive'] ?? newStatus;
              }
            });
          }
          if (context.mounted) {
            CommonWidget.successShowSnackBarFor(
                context, "Offer status updated!");
          }
        } else {
          setState(() {
            offer.isCurrentlyActive = !newStatus;
            offer.isActive = !newStatus;
          });
          if (context.mounted) {
            CommonWidget.errorShowSnackBarFor(context,
                data['message'] ?? "Failed to update offer status");
          }
        }
      } else {
        setState(() {
          offer.isCurrentlyActive = !newStatus;
          offer.isActive = !newStatus;
        });
        if (context.mounted) {
          CommonWidget.errorShowSnackBarFor(
              context, "Failed to update offer status");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          offer.isCurrentlyActive = !newStatus;
          offer.isActive = !newStatus;
        });
      }
      if (context.mounted) {
        CommonWidget.errorShowSnackBarFor(
            context, "Error updating offer status: $e");
      }
    }
  }
}
