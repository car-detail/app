import 'package:car_app/features/resister_vendor_model/ui/registor_vendor_activity_simple.dart';
import 'package:flutter/material.dart';

class RegistorVendorActivity extends StatefulWidget {
  const RegistorVendorActivity({super.key});

  @override
  State<RegistorVendorActivity> createState() => _RegistorVendorActivityState();
}

class _RegistorVendorActivityState extends State<RegistorVendorActivity> {
  @override
  void initState() {
    super.initState();
    // Redirect to simplified version
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RegistorVendorActivitySimple(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}