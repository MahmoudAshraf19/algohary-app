import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_state.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_event.dart';
import 'package:algohary_project/core/bloc/location_bloc/location_bloc.dart';
import 'package:algohary_project/core/bloc/location_bloc/location_state.dart';
import 'package:algohary_project/features/location/presentation/widgets/location_bottom_sheet.dart';
import 'package:algohary_project/features/notifications/data/services/notification_service.dart';
import 'package:algohary_project/features/notifications/presentation/widgets/notification_dropdown_widget.dart';

class ProviderHomeTab extends StatefulWidget {
  const ProviderHomeTab({super.key});

  @override
  State<ProviderHomeTab> createState() => _ProviderHomeTabState();
}

class _ProviderHomeTabState extends State<ProviderHomeTab> {
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
        final isRTL = Directionality.of(context) == TextDirection.rtl;
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
                offset: isRTL ? const Offset(-10, 50) : const Offset(-270, 50),
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
    final isMorning = DateTime.now().hour < 12;
    final greeting = isMorning ? l10n.goodMorning : l10n.goodEvening;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String firstName = 'Provider';
        String imageUrl = '';
        bool isOnline = false;

        if (authState is AuthSuccess) {
          firstName = authState.user.firstName;
          imageUrl = authState.user.imageUrl;
          isOnline = authState.user.isOnline;
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
                                '$greeting، $firstName 👋',
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
                    
                    const SizedBox(height: 20),
                    
                    // Online / Offline Toggle
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: GestureDetector(
                        onTap: () {
                          context.read<AuthBloc>().add(ToggleOnlineStatus(isOnline: !isOnline));
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isOnline ? const Color(0xFF2EBA68) : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: (isOnline ? const Color(0xFF2EBA68) : Colors.grey).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.adjust,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline ? l10n.statusOnline : l10n.statusOffline,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // TODO: Add Provider-specific content here (like Statistics, pending orders, etc)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 100.0),
                        child: Text(
                          'Provider Dashboard Content',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
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
