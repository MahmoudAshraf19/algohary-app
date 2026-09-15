import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/core/bloc/location_bloc/location_bloc.dart';
import 'package:algohary_project/core/bloc/location_bloc/location_event.dart';
import 'package:algohary_project/features/dashboard/presentation/pages/dashboard_screen.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  
  // Default to Cairo
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(30.0444, 31.2357),
    zoom: 14.4746,
  );

  LatLng _currentCenter = _initialPosition.target;
  bool _isLoading = false;

  void _onCameraMove(CameraPosition position) {
    _currentCenter = position.target;
  }

  Future<void> _confirmLocation() async {
    setState(() => _isLoading = true);
    
    String finalAddress = "Unknown Location";
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(_currentCenter.latitude, _currentCenter.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final city = placemark.locality ?? placemark.administrativeArea ?? '';
        final country = placemark.country ?? '';
        
        if (city.isNotEmpty && country.isNotEmpty) {
          finalAddress = '$city, $country';
        } else if (city.isNotEmpty) {
          finalAddress = city;
        } else if (country.isNotEmpty) {
          finalAddress = country;
        } else {
          finalAddress = placemark.street ?? "Selected Location";
        }
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
    }

    if (!mounted) return;

    context.read<LocationBloc>().add(
      SetLocation(
        latitude: _currentCenter.latitude,
        longitude: _currentCenter.longitude,
        address: finalAddress,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.locationAccessMapBtn),
      ),
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onCameraMove: _onCameraMove,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
            ),
          ),
          
          // Center Pin Marker
          const Padding(
            padding: EdgeInsets.only(bottom: 35.0),
            child: Icon(
              Icons.location_on,
              size: 50,
              color: Colors.red,
            ),
          ),
          
          // Search Bar Placeholder
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.mapSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onSubmitted: (value) {
                  // In a full implementation, you would call Places API here
                  // and animate the camera to the selected place.
                },
              ),
            ),
          ),
          
          // Confirm Button
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: SafeArea(
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(l10n.mapConfirmBtn),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
