import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:algohary_project/core/services/location_service.dart';
import 'package:algohary_project/features/dashboard/data/repositories/category_repository.dart';
import 'package:algohary_project/features/dashboard/data/repositories/service_repository.dart';
import '../../data/models/map_provider.dart';
import '../../data/repositories/map_providers_repository.dart';
import '../../data/services/user_location_resolver.dart';
import 'providers_map_state.dart';

/// Drives the "online providers around me" map.
///
/// Cost control: the realtime listener and GPS stream only run while the map
/// tab is visible ([setActive]), and stream-driven recomputation is throttled.
class ProvidersMapCubit extends Cubit<ProvidersMapState> {
  ProvidersMapCubit({
    this._currentUserId,
    MapProvidersRepository? repository,
    CategoryRepository? categoryRepository,
    ServiceRepository? serviceRepository,
    UserLocationResolver? locationResolver,
  })  : _repo = repository ?? MapProvidersRepository(),
        _categoryRepo = categoryRepository ?? CategoryRepository(),
        _serviceRepo = serviceRepository ?? ServiceRepository(),
        _location = locationResolver ?? UserLocationResolver(),
        super(const ProvidersMapState(
          origin: LatLng(
            LocationService.defaultCairoLat,
            LocationService.defaultCairoLng,
          ),
        ));

  /// Hard cap on markers rendered at once (nearest first).
  static const int maxVisibleProviders = 60;

  static const Duration _throttle = Duration(seconds: 1);
  static const Duration _reconnectDelay = Duration(seconds: 5);

  final String? _currentUserId;
  final MapProvidersRepository _repo;
  final CategoryRepository _categoryRepo;
  final ServiceRepository _serviceRepo;
  final UserLocationResolver _location;

  StreamSubscription<List<MapProvider>>? _providersSub;
  StreamSubscription<LatLng>? _locationSub;
  Timer? _throttleTimer;
  Timer? _reconnectTimer;

  List<MapProvider> _raw = const [];
  Map<String, String> _serviceToCategory = const {};
  LatLng _fallbackOrigin = const LatLng(
    LocationService.defaultCairoLat,
    LocationService.defaultCairoLng,
  );
  LatLng _origin = const LatLng(
    LocationService.defaultCairoLat,
    LocationService.defaultCairoLng,
  );

  bool _active = false;
  bool _hasLoadedOnce = false;
  bool _pendingRecompute = false;
  bool _filterDataRequested = false;
  bool _resolvingLocation = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Called by the UI whenever the map tab becomes visible / hidden.
  void setActive(bool active, {LatLng? fallbackOrigin}) {
    if (isClosed) return;
    if (fallbackOrigin != null) _fallbackOrigin = fallbackOrigin;
    if (active == _active) return;
    _active = active;
    if (active) {
      _activate();
    } else {
      _deactivate();
    }
  }

  void _activate() {
    _subscribeToProviders();
    _loadFilterData();
    if (state.locationStatus == UserLocationStatus.granted &&
        state.userPosition != null) {
      _startLocationWatch();
    }
    // Always refresh: the user may have moved while the tab was hidden.
    refreshLocation();
  }

  void _deactivate() {
    _providersSub?.cancel();
    _providersSub = null;
    _locationSub?.cancel();
    _locationSub = null;
    _throttleTimer?.cancel();
    _reconnectTimer?.cancel();
    _pendingRecompute = false;
  }

  // ---------------------------------------------------------------------------
  // Providers stream
  // ---------------------------------------------------------------------------

  void _subscribeToProviders() {
    _providersSub?.cancel();
    _reconnectTimer?.cancel();

    if (!_hasLoadedOnce) {
      emit(state.copyWith(status: MapStatus.loading, failure: null));
    }

    _providersSub = _repo
        .watchOnlineProviders(excludeUserId: _currentUserId)
        .listen(_onProviders, onError: _onProvidersError);
  }

  void _onProviders(List<MapProvider> providers) {
    _raw = providers;
    _hasLoadedOnce = true;
    if (state.status != MapStatus.ready || state.isReconnecting) {
      // First data (or recovery): show it immediately.
      _recompute();
    } else {
      _scheduleRecompute();
    }
  }

  void _onProvidersError(Object error, StackTrace stackTrace) {
    debugPrint('ProvidersMapCubit: providers stream error: $error');
    _providersSub?.cancel();
    _providersSub = null;
    if (isClosed) return;

    if (_hasLoadedOnce) {
      // Keep showing what we have and silently try to reconnect.
      emit(state.copyWith(isReconnecting: true));
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(_reconnectDelay, () {
        if (_active && !isClosed) _subscribeToProviders();
      });
    } else {
      emit(state.copyWith(
        status: MapStatus.failure,
        failure: _classify(error),
      ));
    }
  }

  MapFailureType _classify(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
        case 'unauthenticated':
          return MapFailureType.permission;
        case 'unavailable':
        case 'deadline-exceeded':
        case 'network-request-failed':
          return MapFailureType.network;
      }
    }
    return MapFailureType.unknown;
  }

  /// Retry after a failure screen.
  void retry() {
    if (isClosed) return;
    _hasLoadedOnce = false;
    _subscribeToProviders();
    _loadFilterData();
    if (state.locationStatus != UserLocationStatus.granted) {
      refreshLocation();
    }
  }

  // ---------------------------------------------------------------------------
  // Location
  // ---------------------------------------------------------------------------

  Future<void> refreshLocation() async {
    if (_resolvingLocation || isClosed) return;
    _resolvingLocation = true;
    try {
      final result = await _location.resolve();
      if (isClosed || !_active) return;

      final position = result.position;
      if (result.isGranted && position != null) {
        // Only ask the UI to move the camera when the origin really changed,
        // so returning to the tab never yanks a map the user has panned.
        final moved = state.originVersion == 0 ||
            state.locationStatus != UserLocationStatus.granted ||
            Geolocator.distanceBetween(
                  _origin.latitude,
                  _origin.longitude,
                  position.latitude,
                  position.longitude,
                ) >
                150;
        _origin = position;
        emit(state.copyWith(
          origin: position,
          userPosition: position,
          locationStatus: UserLocationStatus.granted,
          originVersion: moved ? state.originVersion + 1 : state.originVersion,
        ));
        _startLocationWatch();
      } else {
        _locationSub?.cancel();
        _locationSub = null;
        final changed = state.originVersion == 0 ||
            state.locationStatus != result.status ||
            state.origin != _fallbackOrigin;
        _origin = _fallbackOrigin;
        emit(state.copyWith(
          origin: _fallbackOrigin,
          userPosition: null,
          locationStatus: result.status,
          originVersion:
              changed ? state.originVersion + 1 : state.originVersion,
        ));
      }
      _recompute();
    } finally {
      _resolvingLocation = false;
    }
  }

  void _startLocationWatch() {
    _locationSub?.cancel();
    _locationSub = _location.watch().listen(
      (position) {
        if (isClosed || !_active) return;
        _origin = position;
        emit(state.copyWith(origin: position, userPosition: position));
        _scheduleRecompute();
      },
      onError: (Object e) {
        debugPrint('ProvidersMapCubit: location stream error: $e');
      },
    );
  }

  Future<void> openLocationSettings() =>
      _location.openSettings(state.locationStatus);

  // ---------------------------------------------------------------------------
  // Filter data (categories & services)
  // ---------------------------------------------------------------------------

  Future<void> _loadFilterData() async {
    if (_filterDataRequested) return;
    _filterDataRequested = true;
    try {
      final categoriesFuture = _categoryRepo.getCategories();
      final servicesFuture = _serviceRepo.getServicesByCategory('all');
      final categories = await categoriesFuture;
      final services = await servicesFuture;
      if (isClosed) return;

      if (categories.isEmpty && services.isEmpty) {
        _filterDataRequested = false;
        return;
      }

      _serviceToCategory = {for (final s in services) s.id: s.categoryId};
      emit(state.copyWith(categories: categories, services: services));
      _recompute();
    } catch (e) {
      _filterDataRequested = false;
      debugPrint('ProvidersMapCubit: filter data failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Filtering
  // ---------------------------------------------------------------------------

  void applyFilters(MapFilters filters) {
    if (filters == state.filters) return;
    emit(state.copyWith(filters: filters));
    _recompute();
  }

  /// Quick toggle used by the category chips on the map.
  void toggleCategory(String? categoryId) {
    final current = state.filters;
    final next = (categoryId == null || categoryId == current.categoryId)
        ? current.copyWith(clearCategory: true, serviceIds: const <String>{})
        : current.copyWith(
            categoryId: categoryId,
            serviceIds: const <String>{},
          );
    applyFilters(next);
  }

  void resetFilters() => applyFilters(const MapFilters());

  void select(String? providerId) {
    if (providerId == state.selectedId) return;
    emit(state.copyWith(selectedId: providerId));
  }

  /// How many providers would be shown with [filters] (for the sheet's CTA).
  int countFor(MapFilters filters) {
    final isInfinite = filters.radiusKm.isInfinite;
    final radiusM = isInfinite ? double.infinity : filters.radiusKm * 1000;
    var count = 0;
    for (final p in _raw) {
      if (!isInfinite && _distanceTo(p) > radiusM) continue;
      if (_matches(p, filters)) count++;
    }
    return count;
  }

  // ---------------------------------------------------------------------------
  // Computation
  // ---------------------------------------------------------------------------

  double _distanceTo(MapProvider p) => Geolocator.distanceBetween(
        _origin.latitude,
        _origin.longitude,
        p.position.latitude,
        p.position.longitude,
      );

  Set<String> _categoriesOf(MapProvider p) {
    final result = <String>{};
    final main = p.user.categoryId;
    if (main != null && main.isNotEmpty) result.add(main);
    for (final serviceId in p.user.services ?? const <String>[]) {
      final c = _serviceToCategory[serviceId];
      if (c != null && c.isNotEmpty) result.add(c);
    }
    return result;
  }

  bool _matches(MapProvider p, MapFilters filters) {
    final categoryId = filters.categoryId;
    if (categoryId != null && !_categoriesOf(p).contains(categoryId)) {
      return false;
    }
    if (filters.serviceIds.isNotEmpty) {
      final services = p.user.services ?? const <String>[];
      if (!services.any(filters.serviceIds.contains)) return false;
    }
    return true;
  }

  /// Leading + trailing throttle for stream-driven updates.
  void _scheduleRecompute() {
    if (_throttleTimer?.isActive ?? false) {
      _pendingRecompute = true;
      return;
    }
    _recompute();
    _throttleTimer = Timer(_throttle, () {
      if (_pendingRecompute) {
        _pendingRecompute = false;
        _recompute();
      }
    });
  }

  void _recompute() {
    if (isClosed) return;
    final filters = state.filters;
    final isInfinite = filters.radiusKm.isInfinite;
    final radiusM = isInfinite ? double.infinity : filters.radiusKm * 1000;

    final counts = <String, int>{};
    final visible = <MapProvider>[];

    for (final provider in _raw) {
      final distance = _distanceTo(provider);
      if (!isInfinite && distance > radiusM) continue;
      final withDistance = provider.withDistance(distance);
      for (final c in _categoriesOf(withDistance)) {
        counts[c] = (counts[c] ?? 0) + 1;
      }
      if (_matches(withDistance, filters)) visible.add(withDistance);
    }

    visible.sort((a, b) => a.distanceMeters!.compareTo(b.distanceMeters!));
    final capped = visible.length > maxVisibleProviders
        ? visible.sublist(0, maxVisibleProviders)
        : visible;

    String? selected = state.selectedId;
    if (selected == null || !capped.any((p) => p.id == selected)) {
      selected = capped.isEmpty ? null : capped.first.id;
    }

    emit(state.copyWith(
      status: MapStatus.ready,
      failure: null,
      providers: capped,
      categoryCounts: counts,
      selectedId: selected,
      isReconnecting: false,
    ));
  }

  @override
  Future<void> close() {
    _providersSub?.cancel();
    _locationSub?.cancel();
    _throttleTimer?.cancel();
    _reconnectTimer?.cancel();
    return super.close();
  }
}
