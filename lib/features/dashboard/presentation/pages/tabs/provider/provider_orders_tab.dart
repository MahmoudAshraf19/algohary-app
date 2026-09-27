import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import '../../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../../auth/presentation/bloc/auth_state.dart';
import '../../../../../bookings/data/models/booking_models.dart';
import '../../../../../bookings/data/repositories/bookings_repository.dart';
import '../../../../../bookings/presentation/bloc/provider_orders/provider_orders_bloc.dart';
import '../../../../../bookings/presentation/bloc/provider_orders/provider_orders_event.dart';
import '../../../../../bookings/presentation/bloc/provider_orders/provider_orders_state.dart';
import 'provider_order_details_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:intl/intl.dart';

class ProviderOrdersTab extends StatelessWidget {
  const ProviderOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = (authState is AuthSuccess) ? authState.user : null;
    
    return BlocProvider(
      create: (_) => ProviderOrdersBloc(bookingsRepository: BookingsRepository())
        ..add(LoadProviderOrders(providerId: user?.id ?? '')),
      child: const ProviderOrdersView(),
    );
  }
}

class ProviderOrdersView extends StatefulWidget {
  const ProviderOrdersView({super.key});

  @override
  State<ProviderOrdersView> createState() => _ProviderOrdersViewState();
}

class _ProviderOrdersViewState extends State<ProviderOrdersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<ProviderOrdersBloc>().add(FilterOrders(searchQuery: query));
  }

  void _showFilterBottomSheet(BuildContext context) {
    // Advanced filtering bottom sheet implementation
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          l10n.navOrders ?? 'Orders',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: colorScheme.onSurface,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
              color: const Color(0xFF325A65), // From the design image
              borderRadius: BorderRadius.circular(24),
            ),
            tabs: [
              Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l10n.tabNew ?? 'New'))),
              Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l10n.tabInProgress ?? 'In Progress'))),
              Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l10n.tabCompleted ?? 'Completed'))),
              Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l10n.tabCancelled ?? 'Cancelled'))),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search orders...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _showFilterBottomSheet(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.tune, color: colorScheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ProviderOrdersBloc, ProviderOrdersState>(
              builder: (context, state) {
                if (state is ProviderOrdersLoading || state is ProviderOrdersInitial) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ProviderOrdersError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (state is ProviderOrdersLoaded) {
                  final newOrders = state.filteredOrders.where((o) => o.status == ServiceRequestStatus.pendingProviderApproval || o.status == ServiceRequestStatus.changeProposed || o.status == ServiceRequestStatus.pendingProviderConfirmation).toList();
                  final inProgressOrders = state.filteredOrders.where((o) => o.status == ServiceRequestStatus.approved || o.status == ServiceRequestStatus.inProgress).toList();
                  final completedOrders = state.filteredOrders.where((o) => o.status == ServiceRequestStatus.completed).toList();
                  final cancelledOrders = state.filteredOrders.where((o) => o.status == ServiceRequestStatus.cancelledByUser || o.status == ServiceRequestStatus.cancelledByProvider || o.status == ServiceRequestStatus.rejected || o.status == ServiceRequestStatus.expired).toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList(newOrders, colorScheme, l10n),
                      _buildOrdersList(inProgressOrders, colorScheme, l10n),
                      _buildOrdersList(completedOrders, colorScheme, l10n),
                      _buildOrdersList(cancelledOrders, colorScheme, l10n),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<ServiceRequestModel> orders, ColorScheme colorScheme, AppLocalizations l10n) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'No orders found',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, colorScheme, l10n);
      },
    );
  }

  Widget _buildOrderCard(ServiceRequestModel order, ColorScheme colorScheme, AppLocalizations l10n) {
    final title = order.selectedServices.isNotEmpty ? order.selectedServices.first.serviceName : 'Service';
    final date = order.appointment.timestamp != null 
        ? DateFormat('MMM d, yyyy').format(order.appointment.timestamp!)
        : order.appointment.date;

    Color statusColor;
    String statusText;
    switch (order.status) {
      case ServiceRequestStatus.pendingProviderApproval:
        statusColor = Colors.orange;
        statusText = l10n.orderStatusPending ?? 'Pending';
        break;
      case ServiceRequestStatus.approved:
      case ServiceRequestStatus.inProgress:
        statusColor = Colors.blue;
        statusText = l10n.orderStatusInProgress ?? 'In Progress';
        break;
      case ServiceRequestStatus.completed:
        statusColor = Colors.green;
        statusText = l10n.orderStatusCompleted ?? 'Completed';
        break;
      default:
        statusColor = Colors.grey;
        statusText = order.status.value;
    }

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProviderOrderDetailsScreen(orderId: order.id)));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
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
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: Icon(Icons.handyman, color: colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#ORD-${order.id.substring(0, 5).toUpperCase()}',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$date, ${order.appointment.time}',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
