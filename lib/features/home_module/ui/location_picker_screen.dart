import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_places_autocomplete_widgets/widgets/address_autocomplete_textfield.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';

class LocationPickerScreen extends StatefulWidget {
  final String? currentLocation;

  const LocationPickerScreen({super.key, this.currentLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _locationController = TextEditingController();
  SharedPreferences? _sharedPreferences;
  bool _isLoading = false;
  double? _selectedLat;
  double? _selectedLng;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    _locationController.text = widget.currentLocation ?? "";
  }

  Future<void> _initSharedPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          CommonWidget.errorShowSnackBarFor(
              context, 'Location services are disabled. Please enable them.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            CommonWidget.errorShowSnackBarFor(
                context, 'Location permissions are denied');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          CommonWidget.errorShowSnackBarFor(
              context, 'Location permissions are permanently denied');
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      String address = placemarks[0].locality ??
          placemarks[0].subAdministrativeArea ??
          placemarks[0].administrativeArea ??
          "Current Location";

      setState(() {
        _locationController.text = address;
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
        _selectedAddress = address;
        _isLoading = false;
      });

      if (mounted) {
        CommonWidget.successShowSnackBarFor(
            context, 'Location detected successfully!');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CommonWidget.errorShowSnackBarFor(
            context, 'Error getting location: ${e.toString()}');
      }
    }
  }

  void _saveLocation() {
    if (_selectedAddress == null || _selectedAddress!.isEmpty) {
      CommonWidget.errorShowSnackBarFor(
          context, 'Please select a location');
      return;
    }

    if (_selectedLat == null || _selectedLng == null) {
      CommonWidget.errorShowSnackBarFor(
          context, 'Location coordinates are missing');
      return;
    }

    _sharedPreferences?.setString(Constant.location, _selectedAddress!);
    _sharedPreferences?.setString(Constant.lat, _selectedLat!.toString());
    _sharedPreferences?.setString(Constant.long, _selectedLng!.toString());

    Navigator.pop(context, {
      'location': _selectedAddress,
      'lat': _selectedLat,
      'lng': _selectedLng,
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Location',
          style: TextStyle(
            fontFamily: "Pop600",
            fontSize: 18,
          ),
        ),
        backgroundColor: ColorClass.base_color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: ColorClass.base_color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select your location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: "Pop400",
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search for an address or use your current location',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontFamily: "Pop300",
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Google Places Autocomplete
                  AddressAutocompleteTextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: ColorClass.base_color),
                      hintText: "Search for an address...",
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
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    mapsApiKey: 'AIzaSyBFtrosISezP-8z2NwTWKhD_5pNHoi0wRw',
                    controller: _locationController,
                    onSuggestionClick: (place) {
                      setState(() {
                        final address = place.formattedAddress ?? place.name ?? '';
                        _locationController.text = address;
                        _selectedLat = place.lat ?? 0.0;
                        _selectedLng = place.lng ?? 0.0;
                        _selectedAddress = address;
                      });
                    },
                    language: 'en-US',
                  ),
                  const SizedBox(height: 20),
                  // Divider with "OR"
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontFamily: "Pop500",
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Use Current Location Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getCurrentLocation,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.my_location, size: 20),
                      label: Text(
                        _isLoading ? 'Getting location...' : 'Use Current Location',
                        style: const TextStyle(
                          fontFamily: "Pop500",
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorClass.base_color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Selected Location Display
                  if (_selectedAddress != null && _selectedAddress!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorClass.base_color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ColorClass.base_color.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: ColorClass.base_color,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected Location',
                                  style: TextStyle(
                                    fontFamily: "Pop500",
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedAddress!,
                                  style: const TextStyle(
                                    fontFamily: "Pop500",
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorClass.base_color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Save Location',
                        style: TextStyle(
                          fontFamily: "Pop600",
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

