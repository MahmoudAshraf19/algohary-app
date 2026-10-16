import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/firebase_config.dart';

/// Enterprise-grade, battery-efficient background & foreground location tracker for providers.
class ProviderLocationTracker {
  // Singleton pattern
  static final ProviderLocationTracker _instance = ProviderLocationTracker._internal();
  factory ProviderLocationTracker() => _instance;
  ProviderLocationTracker._internal();

  final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  
  StreamSubscription<Position>? _positionSubscription;
  Timer? _heartbeatTimer;
  String? _activeProviderId;
  DateTime? _lastSavedTime;
  bool _starting = false;

  /// Default distance filter in meters (50m as standard for delivery/providers)
  static const int defaultDistanceFilterMeters = 50;

  /// Fallback heartbeat duration in minutes (pings every 2 minutes even if stationary)
  static const Duration heartbeatInterval = Duration(minutes: 2);

  bool get isTracking => _positionSubscription != null;

  /// Start tracking location when provider goes ONLINE
  Future<void> startTracking(String providerId, {int distanceFilter = defaultDistanceFilterMeters}) async {
    // Calls can overlap (e.g. session restore + login): only one may run.
    if (_starting) return;
    _starting = true;
    try {
      await _startTracking(providerId, distanceFilter: distanceFilter);
    } finally {
      _starting = false;
    }
  }

  Future<void> _startTracking(String providerId, {required int distanceFilter}) async {
    // Avoid duplicate subscriptions. This must happen BEFORE the provider id is
    // assigned: stopTracking() clears it, so restarting used to leave tracking
    // running with no provider id and every location write silently skipped.
    if (_positionSubscription != null) {
      await stopTracking(updateStatus: false);
    }
    _activeProviderId = providerId;

    try {
      // 1. Check & request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        debugPrint('ProviderLocationTracker: Permission denied.');
        _activeProviderId = null;
        return;
      }

      // 2. Immediate one-shot position fetch and direct Firestore update
      try {
        final initialPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        await _saveLocationToFirestore(initialPosition);
      } catch (e) {
        debugPrint('ProviderLocationTracker initial fetch warning: $e');
      }

      // 3. Configure location stream settings with distance filter
      LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
          forceLocationManager: false,
          intervalDuration: const Duration(seconds: 15),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText: "Al Gohary is tracking your location for nearby service requests",
            notificationTitle: "Provider Active (Online)",
            enableWakeLock: true,
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
          pauseLocationUpdatesAutomatically: true,
          showBackgroundLocationIndicator: true,
        );
      } else {
        // Web and other platforms
        locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
        );
      }

      // 4. Start listening to position changes
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) async {
          await _saveLocationToFirestore(position);
        },
        onError: (e) {
          debugPrint('ProviderLocationTracker stream error: $e');
        },
      );

      // 5. Stationary Heartbeat Timer (Ensures online presence even when stationary)
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(heartbeatInterval, (timer) async {
        if (_activeProviderId == null || !isTracking) {
          timer.cancel();
          return;
        }

        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 8),
            ),
          );
          await _saveLocationToFirestore(position);
        } catch (_) {}
      });

      debugPrint('ProviderLocationTracker: Tracking started for provider $providerId');
    } catch (e) {
      debugPrint('ProviderLocationTracker: Failed to start tracking: $e');
    }
  }

  /// Stop tracking location when provider goes OFFLINE or logs out
  Future<void> stopTracking({bool updateStatus = true}) async {
    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;

      if (updateStatus && _activeProviderId != null) {
        await _firestore.collection('users').doc(_activeProviderId).update({
          'is_online': false,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('ProviderLocationTracker: Tracking stopped for provider $_activeProviderId');
      _activeProviderId = null;
      _lastSavedTime = null;
    } catch (e) {
      debugPrint('ProviderLocationTracker stopTracking error: $e');
    }
  }

  /// Direct and optimized field update in Firestore (No redundant document reads!)
  Future<void> _saveLocationToFirestore(Position position) async {
    if (_activeProviderId == null) return;

    // Throttling: avoid multiple writes within 5 seconds if distance didn't change significantly
    final now = DateTime.now();
    if (_lastSavedTime != null && now.difference(_lastSavedTime!).inSeconds < 5) {
      return;
    }

    try {
      _lastSavedTime = now;

      await _firestore.collection('users').doc(_activeProviderId).update({
        'is_online': true,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'rotation': position.heading, // Vehicle or moving heading (0.0 to 360.0)
        'speed': position.speed,       // Moving speed
        'updated_at': FieldValue.serverTimestamp(),
      });
      debugPrint('📍 Updated location for provider: ${position.latitude}, ${position.longitude} (Heading: ${position.heading})');
    } catch (e) {
      debugPrint('ProviderLocationTracker Firestore write error: $e');
    }
  }
}
