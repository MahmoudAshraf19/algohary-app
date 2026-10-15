import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:algohary_project/features/dashboard/data/models/category_model.dart';
import 'package:algohary_project/features/dashboard/data/models/service_model.dart';
import '../../data/models/map_provider.dart';
import '../../data/services/user_location_resolver.dart';

enum MapStatus { loading, ready, failure }

enum MapFailureType { network, permission, unknown }

/// User-selectable filters. Immutable and cheap to compare.
class MapFilters extends Equatable {
  static const double defaultRadiusKm = 10;
  static const List<double> radiusOptionsKm = [5, 10, 25, 40, 75, double.infinity];

  final String? categoryId;
  final Set<String> serviceIds;
  final double radiusKm;

  const MapFilters({
    this.categoryId,
    this.serviceIds = const <String>{},
    this.radiusKm = defaultRadiusKm,
  });

  bool get isAnywhere => radiusKm.isInfinite;

  /// Number of filters that differ from the defaults (used for the badge).
  int get activeCount =>
      (categoryId != null ? 1 : 0) +
      (serviceIds.isNotEmpty ? 1 : 0) +
      (radiusKm != defaultRadiusKm ? 1 : 0);

  bool get isDefault => activeCount == 0;

  /// `true` when the filters narrow results by category or service.
  bool get hasCategoryOrServiceFilter =>
      categoryId != null || serviceIds.isNotEmpty;

  MapFilters copyWith({
    String? categoryId,
    bool clearCategory = false,
    Set<String>? serviceIds,
    double? radiusKm,
  }) {
    return MapFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      serviceIds: serviceIds ?? this.serviceIds,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }

  @override
  List<Object?> get props => [categoryId, serviceIds, radiusKm];
}

const Object _unset = Object();

class ProvidersMapState extends Equatable {
  final MapStatus status;
  final MapFailureType? failure;

  /// Providers to display (filtered, sorted by distance, capped).
  final List<MapProvider> providers;

  /// Online providers inside the radius per category id (ignores filters), used
  /// for the counters on the category chips.
  final Map<String, int> categoryCounts;

  final List<CategoryModel> categories;
  final List<ServiceModel> services;
  final MapFilters filters;

  /// Center of the search: the user's GPS position, or a fallback.
  final LatLng origin;

  /// The user's real GPS position (null when unavailable).
  final LatLng? userPosition;
  final UserLocationStatus locationStatus;

  /// Increments every time the origin was (re)resolved, so the UI knows when
  /// to move the camera. Live GPS updates do not change it.
  final int originVersion;

  final String? selectedId;

  /// `true` while the realtime listener dropped and is being re-established.
  final bool isReconnecting;

  const ProvidersMapState({
    this.status = MapStatus.loading,
    this.failure,
    this.providers = const [],
    this.categoryCounts = const {},
    this.categories = const [],
    this.services = const [],
    this.filters = const MapFilters(),
    required this.origin,
    this.userPosition,
    this.locationStatus = UserLocationStatus.unavailable,
    this.originVersion = 0,
    this.selectedId,
    this.isReconnecting = false,
  });

  bool get isUsingFallbackOrigin => userPosition == null;

  bool get hasLocationIssue =>
      locationStatus != UserLocationStatus.granted && originVersion > 0;

  ProvidersMapState copyWith({
    MapStatus? status,
    Object? failure = _unset,
    List<MapProvider>? providers,
    Map<String, int>? categoryCounts,
    List<CategoryModel>? categories,
    List<ServiceModel>? services,
    MapFilters? filters,
    LatLng? origin,
    Object? userPosition = _unset,
    UserLocationStatus? locationStatus,
    int? originVersion,
    Object? selectedId = _unset,
    bool? isReconnecting,
  }) {
    return ProvidersMapState(
      status: status ?? this.status,
      failure: identical(failure, _unset)
          ? this.failure
          : failure as MapFailureType?,
      providers: providers ?? this.providers,
      categoryCounts: categoryCounts ?? this.categoryCounts,
      categories: categories ?? this.categories,
      services: services ?? this.services,
      filters: filters ?? this.filters,
      origin: origin ?? this.origin,
      userPosition: identical(userPosition, _unset)
          ? this.userPosition
          : userPosition as LatLng?,
      locationStatus: locationStatus ?? this.locationStatus,
      originVersion: originVersion ?? this.originVersion,
      selectedId: identical(selectedId, _unset)
          ? this.selectedId
          : selectedId as String?,
      isReconnecting: isReconnecting ?? this.isReconnecting,
    );
  }

  @override
  List<Object?> get props => [
        status,
        failure,
        providers,
        categoryCounts,
        categories,
        services,
        filters,
        origin,
        userPosition,
        locationStatus,
        originVersion,
        selectedId,
        isReconnecting,
      ];
}
