import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/core/theme/app_colors.dart';
import 'package:algohary_project/core/widgets/custom_search_bar.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' hide LatLng;
import 'package:pointer_interceptor/pointer_interceptor.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;

  LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({Key? key}) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(30.0444, 31.2357), // Cairo as default
    zoom: 14.4746,
  );

  LatLng _currentLocation = const LatLng(30.0444, 31.2357);
  LatLng? _lastGeocodedLocation;
  String _currentAddress = '';
  bool _isLoading = false;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  
  late final FlutterGooglePlacesSdk _places;
  List<AutocompletePrediction> _predictions = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _places = FlutterGooglePlacesSdk('AIzaSyAkJimJx_Vzga5x3eYYMTkgqZT11OySYB8');
    _determinePosition();
  }

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _predictions = [];
        });
      }
      return;
    }
    
    try {
      final response = await _places.findAutocompletePredictions(query);
      if (mounted) {
        setState(() {
          _predictions = response.predictions;
        });
      }
    } catch (e) {
      debugPrint('Places API error: $e');
    }
  }

  void _onPredictionSelected(AutocompletePrediction prediction) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _predictions = [];
      _searchController.text = prediction.fullText;
      _isSearching = true;
    });

    debugPrint('🔍 [LocationPicker] User selected prediction: ${prediction.fullText} (ID: ${prediction.placeId})');
    try {
      final response = await _places.fetchPlace(
        prediction.placeId,
        fields: [PlaceField.Location],
      );

      final location = response.place?.latLng;
      if (location != null) {
        debugPrint('✅ [LocationPicker] Place details fetched successfully. Lat: ${location.lat}, Lng: ${location.lng}');
        _moveToLocation(LatLng(location.lat, location.lng));
      } else {
        debugPrint('⚠️ [LocationPicker] Place details returned null location. Falling back to Geocoding for address: ${prediction.fullText}');
        // Fallback to geocoding if place details fail
        List<geocoding.Location> locations = await geocoding.Geocoding().locationFromAddress(prediction.fullText);
        if (locations.isNotEmpty) {
          debugPrint('✅ [LocationPicker] Fallback Geocoding successful. Lat: ${locations.first.latitude}, Lng: ${locations.first.longitude}');
          _moveToLocation(LatLng(locations.first.latitude, locations.first.longitude));
        } else {
          debugPrint('❌ [LocationPicker] Both Place Details and Fallback Geocoding failed to get coordinates.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not determine location')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [LocationPicker] Fetch Place error: $e');
      try {
        debugPrint('⚠️ [LocationPicker] Attempting Fallback Geocoding after error...');
        // Fallback to geocoding if place details throw an error
        List<geocoding.Location> locations = await geocoding.Geocoding().locationFromAddress(prediction.fullText);
        if (locations.isNotEmpty) {
          debugPrint('✅ [LocationPicker] Fallback Geocoding successful. Lat: ${locations.first.latitude}, Lng: ${locations.first.longitude}');
          _moveToLocation(LatLng(locations.first.latitude, locations.first.longitude));
        } else {
          debugPrint('❌ [LocationPicker] Fallback Geocoding yielded no results.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not determine location')),
            );
          }
        }
      } catch (e2) {
        debugPrint('Geocoding fallback error: $e2');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    } 

    final position = await Geolocator.getCurrentPosition();
    _moveToLocation(LatLng(position.latitude, position.longitude));
  }

  Future<void> _moveToLocation(LatLng target) async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: target, zoom: 16.0),
    ));
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    if (_lastGeocodedLocation != null &&
        _lastGeocodedLocation!.latitude == position.latitude &&
        _lastGeocodedLocation!.longitude == position.longitude) {
      debugPrint('⏭️ [LocationPicker] Skipping redundant reverse geocoding for same coordinates: ${position.latitude}, ${position.longitude}');
      return; // Prevent infinite loop on web
    }
    
    debugPrint('📍 [LocationPicker] Starting reverse geocoding for Lat: ${position.latitude}, Lng: ${position.longitude}');
    _lastGeocodedLocation = position;
    
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      List<geocoding.Placemark> placemarks = await geocoding.Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        setState(() {
          final parts = [place.street, place.subLocality, place.locality, place.administrativeArea]
              .where((e) => e != null && e.toString().trim().isNotEmpty)
              .toList();
          _currentAddress = parts.join(', ');
          if (_currentAddress.isEmpty) {
            _currentAddress = 'Unknown address';
          }
          debugPrint('✅ [LocationPicker] Address resolved successfully: $_currentAddress');
        });
      } else {
        debugPrint('⚠️ [LocationPicker] Reverse geocoding returned empty placemarks list.');
      }
    } catch (e) {
      debugPrint('❌ [LocationPicker] Reverse geocoding error: $e');
      setState(() {
        _currentAddress = 'Could not determine address';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pickLocationFromMap ?? 'Pick Location from Map'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              if (_controller.isCompleted) {
                _controller = Completer<GoogleMapController>();
              }
              _controller.complete(controller);
            },
            onCameraMove: (CameraPosition position) {
              _currentLocation = position.target;
            },
            onCameraIdle: () {
              _getAddressFromLatLng(_currentLocation);
            },
            onTap: (LatLng location) {
              FocusManager.instance.primaryFocus?.unfocus();
              _moveToLocation(location);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          // Center Pin Marker
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35.0), // Adjust for the pin height
              child: Icon(
                Icons.location_on,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          
          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: PointerInterceptor(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                  child: CustomSearchBar(
                    controller: _searchController,
                    hintText: l10n.searchPlace ?? 'Search for a place...',
                    isLoading: _isSearching,
                    onChanged: _onSearchChanged,
                    onSubmitted: (value) {
                      if (_predictions.isNotEmpty) {
                        _onPredictionSelected(_predictions.first);
                      }
                    },
                  ),
                ),
                if (_predictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final prediction = _predictions[index];
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.location_on_outlined, color: theme.colorScheme.primary, size: 20),
                            ),
                            title: Text(prediction.primaryText, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(prediction.secondaryText, maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () => _onPredictionSelected(prediction),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            ),
          ),
          
          // My Location Button
          Positioned(
            right: 16,
            bottom: 160,
            child: PointerInterceptor(
              child: FloatingActionButton(
                elevation: 0,
                backgroundColor: theme.colorScheme.surface,
                onPressed: _determinePosition,
                child: Icon(Icons.my_location, color: theme.colorScheme.primary),
              ),
            ),
          ),
          
          // Bottom Address Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PointerInterceptor(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isLoading
                            ? const Text('Loading address...')
                            : Text(
                                _currentAddress.isNotEmpty ? _currentAddress : 'Move the map to select a location',
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                              final finalAddress = _currentAddress.isNotEmpty && _currentAddress != 'Could not determine address' 
                                  ? _currentAddress 
                                  : 'Selected Location (${_currentLocation.latitude.toStringAsFixed(4)}, ${_currentLocation.longitude.toStringAsFixed(4)})';
                                  
                              debugPrint('🎯 [LocationPicker] Confirming Location -> Lat: ${_currentLocation.latitude}, Lng: ${_currentLocation.longitude}, Address: "$finalAddress"');
                              Navigator.pop(
                                context,
                                LocationPickerResult(
                                  latitude: _currentLocation.latitude,
                                  longitude: _currentLocation.longitude,
                                  formattedAddress: finalAddress,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        l10n.confirmLocation ?? 'Confirm Location',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}
