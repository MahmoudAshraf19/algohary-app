import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum UserLocationStatus {
  granted,
  serviceDisabled,
  denied,
  deniedForever,
  unavailable,
}

class UserLocationResult {
  final UserLocationStatus status;
  final LatLng? position;

  const UserLocationResult(this.status, [this.position]);

  bool get isGranted => status == UserLocationStatus.granted;
}

/// Resolves the user's GPS position with explicit, typed failure reasons so the
/// UI can explain exactly what is wrong and how to fix it.
class UserLocationResolver {
  Future<UserLocationResult> resolve() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const UserLocationResult(UserLocationStatus.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const UserLocationResult(UserLocationStatus.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        return const UserLocationResult(UserLocationStatus.denied);
      }

      // Use the last known fix as a fallback if a fresh one times out.
      LatLng? best;
      if (!kIsWeb) {
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) {
            best = LatLng(
              (last.latitude as num).toDouble(),
              (last.longitude as num).toDouble(),
            );
          }
        } catch (_) {}
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        best = LatLng(
          (position.latitude as num).toDouble(),
          (position.longitude as num).toDouble(),
        );
      } on TimeoutException {
        // Keep the last known fix if we have one.
      } catch (e) {
        debugPrint('UserLocationResolver: getCurrentPosition failed: $e');
      }

      if (best == null) {
        return const UserLocationResult(UserLocationStatus.unavailable);
      }
      return UserLocationResult(UserLocationStatus.granted, best);
    } catch (e) {
      debugPrint('UserLocationResolver: unexpected error: $e');
      return const UserLocationResult(UserLocationStatus.unavailable);
    }
  }

  /// Live position updates (only active while watching).
  Stream<LatLng> watch({int distanceFilterMeters = 30}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    ).map((p) => LatLng(p.latitude, p.longitude));
  }

  Future<void> openSettings(UserLocationStatus status) async {
    if (kIsWeb) return;
    try {
      if (status == UserLocationStatus.serviceDisabled) {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (e) {
      debugPrint('UserLocationResolver: cannot open settings: $e');
    }
  }
}
