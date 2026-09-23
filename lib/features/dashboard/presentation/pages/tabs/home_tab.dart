import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_state.dart';
import 'package:algohary_project/core/bloc/location_bloc/location_bloc.dart';
import 'package:algohary_project/core/bloc/location_bloc/location_state.dart';
import 'package:algohary_project/features/location/presentation/widgets/location_bottom_sheet.dart';
import 'package:algohary_project/features/dashboard/presentation/widgets/categories_row.dart';
import 'package:algohary_project/features/dashboard/presentation/widgets/popular_services_section.dart';
import 'package:algohary_project/features/dashboard/presentation/widgets/provider_search_delegate.dart';
import 'package:algohary_project/core/widgets/custom_search_bar.dart';
import 'package:algohary_project/features/notifications/data/services/notification_service.dart';
import 'package:algohary_project/features/notifications/presentation/widgets/notification_dropdown_widget.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final NotificationService _notificationService = NotificationService();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }

  void _toggleDropdown() {
    if (_overlayEntry != null) {
      _closeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showDropdown() {
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
            Positioned(
              width: 320,
              child: CompositedTransformFollower(
                link: _layerLink,
                offset: const Offset(-270, 50),
                child: NotificationDropdownWidget(onClose: _closeDropdown),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String firstName = 'User';
        String imageUrl = '';

        if (authState is AuthSuccess) {
          firstName = authState.user.firstName;
          imageUrl = authState.user.imageUrl;
        }

        return BlocBuilder<LocationBloc, LocationState>(
          builder: (context, locationState) {
            String locationText = l10n.homeLocationError;
            if (locationState is LocationSelected) {
              locationText = locationState.address;
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        // Profile Image
                        ClipOval(
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 48,
                                    height: 48,
                                    color: theme.colorScheme.primaryContainer,
                                    child: const Icon(Icons.person),
                                  ),
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color: theme.colorScheme.primaryContainer,
                                  child: const Icon(Icons.person),
                                ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Welcome & Location
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l10n.homeWelcome} $firstName 👋',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => LocationBottomSheet.show(context),
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        locationText,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Notification Icon with Badge
                        CompositedTransformTarget(
                          link: _layerLink,
                          child: GestureDetector(
                            onTap: _toggleDropdown,
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.notifications_outlined,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: StreamBuilder<int>(
                                    stream: _notificationService.streamUnreadCount(),
                                    builder: (context, snapshot) {
                                      final count = snapshot.data ?? 0;
                                      if (count == 0) return const SizedBox();
                                      return Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          count > 99 ? '99+' : count.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Search Bar
                    GestureDetector(
                      onTap: () {
                        showSearch(
                          context: context,
                          delegate: ProviderSearchDelegate(),
                        );
                      },
                      child: AbsorbPointer(
                        child: CustomSearchBar(
                          hintText: l10n.homeSearchHint,
                          suffixIcon: const Icon(Icons.tune),
                          readOnly: true,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 6), // Increased spacing before banner

                    // Banner Widget
                    AspectRatio(
                      aspectRatio: 2024 / 777,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/banner2.png'),
                            fit: BoxFit.fill,
                            alignment: AlignmentDirectional.centerEnd,
                            matchTextDirection: true,
                          ),
                        ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      l10n.homeBannerTitle,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0D475C),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: Text(
                                      l10n.homeBannerSubtitle,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF1E5B70),
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(flex: 4), // Keeps text away from the worker
                          ],
                        ),
                      ),
                    ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Categories Section
                    const CategoriesRow(),

                    const SizedBox(height: 24),

                    // Popular Services Section
                    const PopularServicesSection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
