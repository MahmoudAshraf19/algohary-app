import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:algohary_project/core/bloc/location_bloc/location_bloc.dart';
import 'package:algohary_project/core/bloc/location_bloc/location_state.dart';
import 'package:algohary_project/core/services/location_service.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_state.dart';
import 'package:algohary_project/features/dashboard/presentation/pages/provider_profile_screen.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import '../../data/models/map_provider.dart';
import '../../data/services/user_location_resolver.dart';
import '../cubit/providers_map_cubit.dart';
import '../cubit/providers_map_state.dart';
import '../utils/map_marker_factory.dart';
import '../utils/map_palette.dart';
import '../utils/map_styles.dart';
import '../widgets/map_filter_sheet.dart';
import '../widgets/map_overlays.dart';
import '../widgets/map_provider_carousel.dart';
import '../widgets/map_top_bar.dart';

/// "Map" tab: online providers around the user, on a live map.
///
/// [isActive] must be `true` only while the tab is visible. The realtime
/// listener and GPS stream are paused otherwise to save battery and reads.
class ProvidersMapTab extends StatelessWidget {
  final bool isActive;

  const ProvidersMapTab({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final auth = context.read<AuthBloc>().state;
        return ProvidersMapCubit(
          currentUserId: auth is AuthSuccess ? auth.user.id : null,
        );
      },
      child: _ProvidersMapView(isActive: isActive),
    );
  }
}

class _ProvidersMapView extends StatefulWidget {
  final bool isActive;

  const _ProvidersMapView({required this.isActive});

  @override
  State<_ProvidersMapView> createState() => _ProvidersMapViewState();
}

class _ProvidersMapViewState extends State<_ProvidersMapView>
    with WidgetsBindingObserver {
  static const double _defaultZoom = 14;

  final MapMarkerFactory _markerFactory = MapMarkerFactory();
  final Set<String> _requestedIcons = {};

  GoogleMapController? _mapController;
  BitmapDescriptor? _userIcon;
  String? _userIconSignature;
  Timer? _iconRefreshTimer;

  ProvidersMapCubit get _cubit => context.read<ProvidersMapCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isActive) _setActive(true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserIcon();
  }

  @override
  void didUpdateWidget(covariant _ProvidersMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _setActive(widget.isActive);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !widget.isActive) return;
    final status = _cubit.state.locationStatus;
    if (status == UserLocationStatus.deniedForever ||
        status == UserLocationStatus.serviceDisabled) {
      _cubit.refreshLocation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _iconRefreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  LatLng _fallbackOrigin() {
    final location = context.read<LocationBloc>().state;
    if (location is LocationSelected) {
      return LatLng(location.latitude, location.longitude);
    }
    return const LatLng(
      LocationService.defaultCairoLat,
      LocationService.defaultCairoLng,
    );
  }

  void _setActive(bool active) {
    _cubit.setActive(active, fallbackOrigin: _fallbackOrigin());
  }

  Future<void> _loadUserIcon() async {
    final palette = MapPalette.of(context);
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final signature = '${palette.accent}|${palette.highlight}|$dpr';
    if (_userIconSignature == signature) return;
    _userIconSignature = signature;

    final icon = await _markerFactory.userLocationIcon(
      primary: palette.accent,
      accent: palette.highlight,
      devicePixelRatio: dpr,
    );
    if (!mounted || icon == null) return;
    setState(() => _userIcon = icon);
  }

  void _scheduleIconRefresh() {
    if (_iconRefreshTimer?.isActive ?? false) return;
    _iconRefreshTimer = Timer(const Duration(milliseconds: 80), () {
      if (mounted) setState(() {});
    });
  }

  void _ensureIcon(ProviderMarkerSpec spec) {
    if (_markerFactory.peek(spec) != null) return;
    if (!_requestedIcons.add(spec.key)) return;
    _markerFactory.build(spec).whenComplete(() {
      _requestedIcons.remove(spec.key);
      if (mounted) _scheduleIconRefresh();
    });
  }

  Future<void> _animateTo(LatLng target, {double? zoom}) async {
    final controller = _mapController;
    if (controller == null) return;
    try {
      await controller.animateCamera(
        zoom == null
            ? CameraUpdate.newLatLng(target)
            : CameraUpdate.newLatLngZoom(target, zoom),
      );
    } catch (_) {
      // The controller can be unavailable during teardown; ignore.
    }
  }

  Future<void> _fitAll(ProvidersMapState state) async {
    final controller = _mapController;
    if (controller == null) return;

    final points = <LatLng>[
      ...state.providers.map((p) => p.position),
      if (state.userPosition != null) state.userPosition!,
    ];
    if (points.isEmpty) {
      await _animateTo(state.origin, zoom: _defaultZoom);
      return;
    }
    if (points.length == 1) {
      await _animateTo(points.first, zoom: 15);
      return;
    }

    var minLat = points.first.latitude, maxLat = points.first.latitude;
    var minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          72,
        ),
      );
    } catch (_) {
      // Happens if the map has no size yet; the user can simply retry.
    }
  }

  Future<void> _recenter(ProvidersMapState state) async {
    final position = state.userPosition;
    if (position != null) {
      await _animateTo(position, zoom: 15);
    } else {
      await _cubit.refreshLocation();
    }
  }

  void _openProvider(MapProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderProfileScreen(provider: provider.user),
      ),
    );
  }

  Set<Marker> _buildMarkers(ProvidersMapState state, MapPalette palette) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final markers = <Marker>{};

    final userPosition = state.userPosition;
    if (userPosition != null && _userIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('__user__'),
          position: userPosition,
          icon: _userIcon!,
          anchor: const Offset(0.5, 0.5),
          flat: true,
        ),
      );
    }

    ProviderMarkerSpec spec(MapProvider p, bool selected) => ProviderMarkerSpec(
          id: p.id,
          imageUrl: p.user.imageUrl,
          initials: p.initials,
          selected: selected,
          isDark: palette.isDark,
          devicePixelRatio: dpr,
        );

    final ordered = [
      ...state.providers.where((p) => p.id != state.selectedId),
      ...state.providers.where((p) => p.id == state.selectedId),
    ];

    for (final provider in ordered) {
      final isSelected = provider.id == state.selectedId;
      final normal = spec(provider, false);
      _ensureIcon(normal);

      var icon = _markerFactory.peek(normal);
      if (isSelected) {
        final highlighted = spec(provider, true);
        _ensureIcon(highlighted);
        icon = _markerFactory.peek(highlighted) ?? icon;
      }
      if (icon == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId(provider.id),
          position: provider.position,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          onTap: () => _openProvider(provider),
        ),
      );
    }
    return markers;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final palette = MapPalette.of(context);
    final locationState = context.watch<LocationBloc>().state;

    return BlocConsumer<ProvidersMapCubit, ProvidersMapState>(
      listenWhen: (a, b) => a.originVersion != b.originVersion,
      listener: (context, state) =>
          _animateTo(state.origin, zoom: _defaultZoom),
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final hasCarousel =
            state.status == MapStatus.ready && state.providers.isNotEmpty;

        final locationLabel = state.userPosition != null
            ? l10n.mapAroundYou
            : l10n.mapNearPlace(
                locationState is LocationSelected
                    ? locationState.address
                    : LocationService.defaultFallbackAddress,
              );

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Stack(
            children: [
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: state.origin,
                    zoom: _defaultZoom,
                  ),
                  style: palette.isDark ? MapStyles.dark : MapStyles.light,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    final latest = _cubit.state;
                    if (latest.originVersion > 0) {
                      _animateTo(latest.origin, zoom: _defaultZoom);
                    }
                  },
                  markers: _buildMarkers(state, palette),
                  circles: state.filters.radiusKm.isInfinite
                      ? (state.userPosition != null
                          ? {
                              Circle(
                                circleId: const CircleId('user_accuracy'),
                                center: state.userPosition!,
                                radius: 80,
                                fillColor: palette.accent.withValues(alpha: 0.15),
                                strokeColor: palette.accent.withValues(alpha: 0.5),
                                strokeWidth: 2,
                              ),
                            }
                          : const <Circle>{})
                      : {
                          // Search radius zone
                          Circle(
                            circleId: const CircleId('search_radius'),
                            center: state.userPosition ?? state.origin,
                            radius: state.filters.radiusKm * 1000,
                            fillColor: palette.accent.withValues(alpha: 0.12),
                            strokeColor: palette.accent.withValues(alpha: 0.7),
                            strokeWidth: 2,
                          ),
                          // Subtle inner pulse circle at user center
                          Circle(
                            circleId: const CircleId('user_center_pulse'),
                            center: state.userPosition ?? state.origin,
                            radius: (state.filters.radiusKm * 1000 * 0.08).clamp(30.0, 150.0),
                            fillColor: palette.accent.withValues(alpha: 0.25),
                            strokeColor: Colors.transparent,
                            strokeWidth: 0,
                          ),
                        },
                  padding: EdgeInsets.only(
                    bottom: hasCarousel ? kMapCarouselHeight + 12 : 0,
                  ),
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  tiltGesturesEnabled: false,
                  minMaxZoomPreference: const MinMaxZoomPreference(3, 19),
                ),
              ),

              // Top overlay: location pill, filters, categories, notices.
              SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MapTopBar(
                          locationLabel: locationLabel,
                          onlineCount: state.providers.length,
                          isLoading: state.status == MapStatus.loading,
                          activeFilters: state.filters.activeCount,
                          radiusKm: state.filters.radiusKm,
                          onFiltersTap: () =>
                              showMapFilterSheet(context, _cubit),
                          categories: state.categories,
                          categoryCounts: state.categoryCounts,
                          selectedCategoryId: state.filters.categoryId,
                          onCategorySelected: _cubit.toggleCategory,
                        ),
                        if (state.hasLocationIssue)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                            child: _buildLocationBanner(l10n, state),
                          ),
                        if (state.isReconnecting)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: MapStatusPill(label: l10n.mapReconnecting),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom overlay: map controls + carousel / empty / error.
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MapRoundButton(
                              icon: Icons.zoom_out_map_rounded,
                              tooltip: l10n.mapFitAll,
                              onPressed: () => _fitAll(state),
                            ),
                            const SizedBox(height: 10),
                            MapRoundButton(
                              icon: Icons.my_location_rounded,
                              tooltip: l10n.mapRecenter,
                              onPressed: () => _recenter(state),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _buildBottomContent(l10n, state),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomContent(AppLocalizations l10n, ProvidersMapState state) {
    switch (state.status) {
      case MapStatus.loading:
        return const SizedBox(
          key: ValueKey('loading'),
          height: kMapCarouselHeight,
          child: MapProviderCarouselSkeleton(),
        );

      case MapStatus.failure:
        final (icon, message) = switch (state.failure) {
          MapFailureType.network => (
              Icons.wifi_off_rounded,
              l10n.mapErrorNetwork,
            ),
          MapFailureType.permission => (
              Icons.lock_outline_rounded,
              l10n.mapErrorPermission,
            ),
          _ => (Icons.error_outline_rounded, l10n.mapErrorUnknown),
        };
        return Padding(
          key: const ValueKey('failure'),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MapStateCard(
            icon: icon,
            iconColor: Theme.of(context).colorScheme.error,
            title: l10n.mapErrorTitle,
            message: message,
            primaryLabel: l10n.mapRetry,
            onPrimary: _cubit.retry,
          ),
        );

      case MapStatus.ready:
        if (state.providers.isEmpty) {
          final filtered = state.filters.hasCategoryOrServiceFilter;
          return Padding(
            key: ValueKey(filtered ? 'empty-filtered' : 'empty'),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MapStateCard(
              icon: filtered
                  ? Icons.filter_alt_off_rounded
                  : Icons.person_search_rounded,
              title: l10n.mapEmptyTitle,
              message: filtered
                  ? l10n.mapEmptyFilteredSubtitle
                  : l10n.mapEmptySubtitle,
              primaryLabel: filtered ? l10n.mapClearFilters : null,
              onPrimary: filtered ? _cubit.resetFilters : null,
            ),
          );
        }
        return SizedBox(
          key: const ValueKey('carousel'),
          height: kMapCarouselHeight,
          child: MapProviderCarousel(
            providers: state.providers,
            selectedId: state.selectedId,
            categories: state.categories,
            onSwiped: (provider) {
              _cubit.select(provider.id);
              _animateTo(provider.position);
            },
            onOpen: _openProvider,
          ),
        );
    }
  }

  Widget _buildLocationBanner(AppLocalizations l10n, ProvidersMapState state) {
    switch (state.locationStatus) {
      case UserLocationStatus.serviceDisabled:
        return MapLocationBanner(
          message: l10n.mapLocationServiceOff,
          actionLabel: l10n.mapOpenSettings,
          onAction: _cubit.openLocationSettings,
        );
      case UserLocationStatus.denied:
        return MapLocationBanner(
          message: l10n.mapLocationDenied,
          actionLabel: l10n.mapEnableLocation,
          onAction: _cubit.refreshLocation,
        );
      case UserLocationStatus.deniedForever:
        return MapLocationBanner(
          message: l10n.mapLocationDeniedForever,
          actionLabel: l10n.mapOpenSettings,
          onAction: _cubit.openLocationSettings,
        );
      case UserLocationStatus.unavailable:
        return MapLocationBanner(
          message: l10n.mapLocationUnavailable,
          actionLabel: l10n.mapRetry,
          onAction: _cubit.refreshLocation,
        );
      case UserLocationStatus.granted:
        return const SizedBox.shrink();
    }
  }
}
