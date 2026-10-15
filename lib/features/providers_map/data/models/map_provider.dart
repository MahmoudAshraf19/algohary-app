import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:algohary_project/features/auth/data/models/user_model.dart';

/// A provider that is currently online and has a valid, fresh location.
///
/// Wraps the existing [UserModel] so the already-built provider details screen
/// can be opened without any extra mapping.
class MapProvider extends Equatable {
  final UserModel user;
  final LatLng position;
  final DateTime? lastSeen;

  /// Distance from the search origin, in meters. `null` until computed.
  final double? distanceMeters;

  const MapProvider({
    required this.user,
    required this.position,
    this.lastSeen,
    this.distanceMeters,
  });

  /// Providers whose last heartbeat is older than this are treated as offline,
  /// even if `is_online` is still `true` (e.g. the app was killed).
  static const Duration staleAfter = Duration(minutes: 15);

  String get id => user.id;

  String get fullName => '${user.firstName} ${user.lastName}'.trim();

  /// One or two letters used when the provider has no profile picture.
  String get initials {
    final first = user.firstName.trim();
    final last = user.lastName.trim();
    final a = first.isNotEmpty ? String.fromCharCode(first.runes.first) : '';
    final b = last.isNotEmpty ? String.fromCharCode(last.runes.first) : '';
    final result = '$a$b'.trim();
    return result.isEmpty ? '?' : result.toUpperCase();
  }

  MapProvider withDistance(double meters) => MapProvider(
        user: user,
        position: position,
        lastSeen: lastSeen,
        distanceMeters: meters,
      );

  /// Parses a `users/{id}` document. Returns `null` for anything that should
  /// not appear on the map, or for malformed documents.
  static MapProvider? tryParse(String docId, Map<String, dynamic> data) {
    try {
      if (data['user_type'] != 'provider') return null;
      if (data['is_online'] != true) return null;
      if (data['is_blocked'] == true) return null;
      if (data['is_active'] == false) return null;

      final location = data['location'];
      if (location is! Map) return null;
      final lat = (location['latitude'] as num?)?.toDouble();
      final lng = (location['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      if (lat.abs() > 90 || lng.abs() > 180) return null;
      if (lat == 0 && lng == 0) return null;

      final updatedAt = data['updated_at'];
      DateTime? lastSeen;
      if (updatedAt is Timestamp) {
        lastSeen = updatedAt.toDate();
        if (DateTime.now().difference(lastSeen) > staleAfter) return null;
      }

      final json = Map<String, dynamic>.from(data)..['id'] = docId;
      return MapProvider(
        user: UserModel.fromJson(json),
        position: LatLng(lat, lng),
        lastSeen: lastSeen,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        user.id,
        user.firstName,
        user.lastName,
        user.imageUrl,
        user.categoryId,
        user.services,
        position,
        distanceMeters,
      ];
}
