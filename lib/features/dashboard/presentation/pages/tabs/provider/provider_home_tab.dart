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
import '../../../../../bookings/data/models/booking_models.dart';
import '../../../../../bookings/data/repositories/bookings_repository.dart';
import '../../provider_dashboard_screen.dart';
import 'provider_order_details_screen.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class ProviderHomeTab extends StatefulWidget {
  const ProviderHomeTab({super.key});

  @override
  State<ProviderHomeTab> createState() => _ProviderHomeTabState();
}

class _ProviderHomeTabState extends State<ProviderHomeTab> {
  final NotificationService _notificationService = NotificationService();
  final LayerLink _layerLink = LayerLink();
  final BookingsRepository _bookingsRepository = BookingsRepository();
  Stream<List<ServiceRequestModel>>? _ordersStream;
  String? _currentProviderId;
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
        final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
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
          if (_currentProviderId != authState.user.id || _ordersStream == null) {
            _currentProviderId = authState.user.id;
            _ordersStream = _bookingsRepository.streamUserRequests(authState.user.id, isProvider: true);
          }
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
                    
                    // Provider Dashboard Content
                    _buildDashboardContent(context, theme, theme.colorScheme),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    if (_ordersStream == null) return const SizedBox.shrink();

    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    return StreamBuilder<List<ServiceRequestModel>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }
        
        final orders = snapshot.data!;
        
        // 1. Oldest pending order
        final pendingOrders = orders.where((o) => o.status == ServiceRequestStatus.pendingProviderApproval).toList();
        pendingOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Sort by creation time to get oldest
        final oldestPending = pendingOrders.isNotEmpty ? pendingOrders.first : null;

        // 2. Today's orders
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final todaysOrdersCount = orders.where((o) {
           return o.appointment.date == todayStr && o.status != ServiceRequestStatus.cancelledByUser && o.status != ServiceRequestStatus.cancelledByProvider && o.status != ServiceRequestStatus.rejected;
        }).length;

        // 3. Completed orders
        final completedCount = orders.where((o) => o.status == ServiceRequestStatus.completed).length;

        // 4. Recent orders
        final recentOrdersList = List<ServiceRequestModel>.from(orders);
        recentOrdersList.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
        final recentOrders = recentOrdersList.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (oldestPending != null) ...[
              _buildNewOrderCard(context, oldestPending, theme, colorScheme),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    title: isRTL ? 'طلبات اليوم' : "Today's Orders",
                    count: todaysOrdersCount,
                    icon: Icons.calendar_today,
                    iconBgColor: const Color(0xFFE0F2F1),
                    iconColor: const Color(0xFF00695C),
                    onTap: () {
                       ProviderDashboardScreen.switchTab(context, 1);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    title: AppLocalizations.of(context)?.tabCompleted ?? "Completed",
                    count: completedCount,
                    icon: Icons.check_circle_outline,
                    iconBgColor: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFE65100),
                    onTap: () {
                       ProviderDashboardScreen.switchTab(context, 1);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (recentOrders.isNotEmpty) _buildRecentOrders(context, recentOrders, theme, colorScheme),
          ],
        );
      },
    );
  }

  Widget _buildNewOrderCard(BuildContext context, ServiceRequestModel order, ThemeData theme, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Light yellow background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFECB3), // Slightly darker yellow circle
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment, color: Color(0xFF263238), size: 28), // Clipboard icon
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isRTL ? 'طلب جديد' : 'New Order Request',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF263238)),
                        ),
                        Icon(isRTL ? Icons.chevron_left : Icons.chevron_right, color: const Color(0xFF263238)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.selectedServices.map((e) => e.serviceName).join(', '),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF455A64)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Color(0xFF455A64)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.location.formattedAddress,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF455A64)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Color(0xFF455A64)),
                        const SizedBox(width: 4),
                        Text(
                          '${order.appointment.date}, ${order.appointment.time}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF455A64)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: isRTL ? Alignment.centerLeft : Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProviderOrderDetailsScreen(orderId: order.id)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF264653), // Teal/Dark blue button
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.viewDetails ?? 'View Details'),
                  const SizedBox(width: 8),
                  Icon(isRTL ? Icons.arrow_back : Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required int count,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count.toString(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                  ),
                ],
              ),
            ),
            Icon(isRTL ? Icons.chevron_left : Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentOrders(BuildContext context, List<ServiceRequestModel> orders, ThemeData theme, ColorScheme colorScheme) {
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isRTL ? 'الطلبات الحديثة' : 'Recent Orders',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
            ),
            GestureDetector(
              onTap: () {
                ProviderDashboardScreen.switchTab(context, 1);
              },
              child: Row(
                children: [
                  Text(
                    isRTL ? 'عرض الكل' : 'View All',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.primary),
                  ),
                  Icon(isRTL ? Icons.chevron_left : Icons.chevron_right, size: 16, color: colorScheme.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...orders.map((o) => _buildRecentOrderTile(context, o, colorScheme)),
      ],
    );
  }

  Widget _buildRecentOrderTile(BuildContext context, ServiceRequestModel order, ColorScheme colorScheme) {
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    
    // Status colors and text
    Color statusBgColor;
    Color statusDotColor;
    Color statusTextColor;
    String statusText;
    
    switch (order.status) {
      case ServiceRequestStatus.pendingProviderApproval:
        statusBgColor = const Color(0xFFFFF3E0); // Light orange
        statusDotColor = const Color(0xFFFF9800);
        statusTextColor = const Color(0xFFE65100);
        statusText = isRTL ? 'قيد الانتظار' : 'Pending';
        break;
      case ServiceRequestStatus.approved:
        statusBgColor = const Color(0xFFE8F5E9); // Light green
        statusDotColor = const Color(0xFF4CAF50);
        statusTextColor = const Color(0xFF2E7D32);
        statusText = isRTL ? 'قيد التنفيذ' : 'In Progress';
        break;
      case ServiceRequestStatus.completed:
        statusBgColor = const Color(0xFFE3F2FD); // Light blue
        statusDotColor = const Color(0xFF2196F3);
        statusTextColor = const Color(0xFF1565C0);
        statusText = isRTL ? 'مكتمل' : 'Completed';
        break;
      default:
        statusBgColor = Colors.grey.shade100;
        statusDotColor = Colors.grey;
        statusTextColor = Colors.grey.shade700;
        statusText = isRTL ? 'ملغي' : 'Cancelled';
    }

    // Format date nicely
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDateObj = DateTime.tryParse(order.appointment.date) ?? order.createdAt;
    final orderDay = DateTime(orderDateObj.year, orderDateObj.month, orderDateObj.day);
    
    String dateStr;
    if (orderDay.isAtSameMomentAs(today)) {
      dateStr = isRTL ? 'اليوم' : 'Today';
    } else if (orderDay.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      dateStr = isRTL ? 'أمس' : 'Yesterday';
    } else {
      dateStr = DateFormat('MMM dd').format(orderDateObj);
    }
    dateStr += ', ${order.appointment.time}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProviderOrderDetailsScreen(orderId: order.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E1), // Light yellow
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.build_circle, color: Color(0xFF00695C), size: 28),
            ),
            const SizedBox(width: 16),
            
            // Middle Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.selectedServices.map((s) => s.serviceName).join(', '),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF78909C)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.location.formattedAddress,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Color(0xFF78909C)),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            
            // Right Status & Chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusDotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusTextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Icon(isRTL ? Icons.chevron_left : Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
