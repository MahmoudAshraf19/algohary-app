import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static const String defaultFallbackAddress = 'Cairo, Egypt';
  static const double defaultCairoLat = 30.0444;
  static const double defaultCairoLng = 31.2357;

  /// Request location permissions and fetch the current readable address (e.g., Cairo, Egypt)
  Future<String?> getCurrentAddress() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // On Web, Geolocator.isLocationServiceEnabled() can be true, but openLocationSettings() doesn't exist
      if (!kIsWeb) {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          try {
            await Geolocator.openLocationSettings();
          } catch (_) {}
          // Return default location if service is disabled
          return defaultFallbackAddress;
        }
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return defaultFallbackAddress;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (!kIsWeb) {
          try {
            await Geolocator.openAppSettings();
          } catch (_) {}
        }
        return defaultFallbackAddress;
      } 

      // Attempt to get the position of the device
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // On Web, the geocoding plugin does not support web reverse geocoding via placemarkFromCoordinates
      if (!kIsWeb) {
        try {
          final placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            final city = placemark.locality ?? placemark.administrativeArea ?? '';
            final country = placemark.country ?? '';
            
            if (city.isNotEmpty && country.isNotEmpty) {
              return '$city, $country';
            } else if (city.isNotEmpty) {
              return city;
            } else if (country.isNotEmpty) {
              return country;
            }
          }
        } catch (e) {
          debugPrint('Reverse geocoding error on mobile: $e');
        }
      }

      // If geocoding failed or on web, return Cairo, Egypt fallback
      return defaultFallbackAddress;
    } catch (e) {
      debugPrint('LocationService getCurrentAddress exception: $e');
      // If anything fails on web/mobile, return Cairo, Egypt as requested
      return defaultFallbackAddress;
    }
  }

  /// Reverse geocode given coordinates into a concise readable address (City, Country or Area)
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    if (!kIsWeb) {
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final street = placemark.street ?? '';
          final subLocality = placemark.subLocality ?? '';
          final locality = placemark.locality ?? placemark.administrativeArea ?? '';
          final country = placemark.country ?? '';

          if (subLocality.isNotEmpty && locality.isNotEmpty) {
            return '$subLocality, $locality';
          } else if (locality.isNotEmpty && country.isNotEmpty) {
            return '$locality, $country';
          } else if (street.isNotEmpty && locality.isNotEmpty) {
            return '$street, $locality';
          } else if (locality.isNotEmpty) {
            return locality;
          } else if (country.isNotEmpty) {
            return country;
          }
        }
      } catch (e) {
        debugPrint('LocationService getAddressFromCoordinates error: $e');
      }
    }
    return defaultFallbackAddress;
  }
}
