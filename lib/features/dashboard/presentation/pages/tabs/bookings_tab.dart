import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_state.dart';
import 'package:algohary_project/features/auth/data/models/user_model.dart';
import 'package:algohary_project/features/auth/data/repositories/auth_repository.dart';
import 'package:algohary_project/core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../bookings/data/models/booking_models.dart';
import '../../../../bookings/data/repositories/bookings_repository.dart';
import '../../../../bookings/presentation/pages/request_details_screen.dart';
import '../../../../bookings/presentation/bloc/request_details/request_details_bloc.dart';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  final BookingsRepository _repository = BookingsRepository();
  final AuthRepository _authRepo = AuthRepository();
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all'; // 'all', 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'
  
  final Map<String, Future<UserModel?>> _providerCache = {};

  Future<UserModel?> _getProviderDetails(String providerId) {
    if (!_providerCache.containsKey(providerId)) {
      _providerCache[providerId] = _authRepo.getUserById(providerId);
    }
    return _providerCache[providerId]!;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshBookings() async {
    setState(() {}); // Triggers StreamBuilder to rebuild, which will pull latest data if stream updates.
  }

  void _openFilterBottomSheet(AppLocalizations l10n, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.filterBookingsTitle ?? 'Filter Bookings',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Text(l10n.filterDate ?? 'Date', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBottomSheetChip(l10n.filterDateAll ?? 'All Dates', true, theme),
                        _buildBottomSheetChip(l10n.filterDateToday ?? 'Today', false, theme),
                        _buildBottomSheetChip(l10n.filterDateTomorrow ?? 'Tomorrow', false, theme),
                        _buildBottomSheetChip(l10n.filterDateThisWeek ?? 'This Week', false, theme),
                        _buildBottomSheetChip(l10n.filterDateThisMonth ?? 'This Month', false, theme),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.btnReset ?? 'Reset'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(l10n.btnApplyFilters ?? 'Apply Filters'),
                          ),
                        ),
                      ],
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

  Widget _buildBottomSheetChip(String label, bool isSelected, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlue : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          fontSize: 13,
        ),
      ),
    );
  }

  Color _getStatusColor(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.pendingProviderApproval:
      case ServiceRequestStatus.pendingProviderConfirmation:
      case ServiceRequestStatus.changeProposed:
        return AppColors.orange;
      case ServiceRequestStatus.approved:
        return AppColors.primaryBlue;
      case ServiceRequestStatus.inProgress:
        return Colors.blueAccent;
      case ServiceRequestStatus.completed:
        return Colors.green;
      case ServiceRequestStatus.rejected:
      case ServiceRequestStatus.cancelledByUser:
      case ServiceRequestStatus.cancelledByProvider:
      case ServiceRequestStatus.expired:
        return AppColors.red;
    }
  }

  String _getLocalizedStatus(ServiceRequestStatus status, AppLocalizations l10n) {
    switch (status) {
      case ServiceRequestStatus.pendingProviderApproval:
      case ServiceRequestStatus.pendingProviderConfirmation:
      case ServiceRequestStatus.changeProposed:
        return l10n.statusPendingProviderApproval ?? 'Pending';
      case ServiceRequestStatus.approved:
        return l10n.statusConfirmed ?? 'Confirmed';
      case ServiceRequestStatus.inProgress:
        return l10n.statusInProgress ?? 'In Progress';
      case ServiceRequestStatus.completed:
        return l10n.statusCompleted ?? 'Completed';
      case ServiceRequestStatus.rejected:
      case ServiceRequestStatus.cancelledByUser:
      case ServiceRequestStatus.cancelledByProvider:
      case ServiceRequestStatus.expired:
        return l10n.statusCancelledByUser ?? 'Cancelled';
    }
  }

  String _mapStatusFilter(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.pendingProviderApproval:
      case ServiceRequestStatus.pendingProviderConfirmation:
      case ServiceRequestStatus.changeProposed:
        return 'pending';
      case ServiceRequestStatus.approved:
        return 'confirmed';
      case ServiceRequestStatus.inProgress:
        return 'in_progress';
      case ServiceRequestStatus.completed:
        return 'completed';
      case ServiceRequestStatus.rejected:
      case ServiceRequestStatus.cancelledByUser:
      case ServiceRequestStatus.cancelledByProvider:
      case ServiceRequestStatus.expired:
        return 'cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        elevation: 0,
        title: Text(
          l10n.navBookings ?? 'Bookings',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: theme.colorScheme.onSurface),
            onPressed: () => _openFilterBottomSheet(l10n, theme),
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthSuccess) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final user = state.user;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusTabs(l10n, theme),
              const SizedBox(height: 8),
              _buildSearchBar(l10n, theme),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<ServiceRequestModel>>(
                  stream: _repository.streamUserRequests(user.id, isProvider: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text(l10n.errorLoadingBookings ?? 'Error loading bookings'));
                    }
                    
                    var requests = snapshot.data ?? [];
                    
                    // Apply Status Filter
                    if (_selectedStatus != 'all') {
                      requests = requests.where((r) => _mapStatusFilter(r.status) == _selectedStatus).toList();
                    }

                    // Apply Search Filter
                    if (_searchQuery.isNotEmpty) {
                      final query = _searchQuery.toLowerCase();
                      requests = requests.where((r) {
                        final idMatch = r.id.toLowerCase().contains(query);
                        final serviceMatch = r.selectedServices.any((s) => s.serviceName.toLowerCase().contains(query));
                        // Assuming provider search is handled manually or we skip it for synchronous filtering
                        return idMatch || serviceMatch;
                      }).toList();
                    }
                    
                    if (requests.isEmpty) {
                      return _buildEmptyState(l10n, theme);
                    }

                    // Sort by newest first
                    requests.sort((a, b) {
                       try {
                         return DateTime.parse(b.appointment.date).compareTo(DateTime.parse(a.appointment.date));
                       } catch (_) { return 0; }
                    });
                    
                    return RefreshIndicator(
                      onRefresh: _refreshBookings,
                      color: AppColors.primaryBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          return _buildBookingCard(request, user.id, l10n, theme, isDark);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusTabs(AppLocalizations l10n, ThemeData theme) {
    final statuses = [
      {'key': 'all', 'label': l10n.filterAll ?? 'All'},
      {'key': 'pending', 'label': l10n.statusPendingProviderApproval ?? 'Pending'},
      {'key': 'confirmed', 'label': l10n.statusConfirmed ?? 'Confirmed'},
      {'key': 'in_progress', 'label': l10n.statusInProgress ?? 'In Progress'},
      {'key': 'completed', 'label': l10n.statusCompleted ?? 'Completed'},
      {'key': 'cancelled', 'label': l10n.statusCancelledByUser ?? 'Cancelled'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: statuses.map((s) {
          final isSelected = _selectedStatus == s['key'];
          return GestureDetector(
            onTap: () => setState(() => _selectedStatus = s['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                s['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: l10n.searchBookings ?? 'Search bookings...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: theme.colorScheme.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 24),
            Text(
              l10n.emptyBookingsTitle ?? 'No Bookings Yet',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyBookingsDesc ?? 'Your service bookings will appear here once you request a service.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate to home or services
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(l10n.btnFindService ?? 'Find a Service'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(ServiceRequestModel request, String userId, AppLocalizations l10n, ThemeData theme, bool isDark) {
    final statusColor = _getStatusColor(request.status);
    final statusText = _getLocalizedStatus(request.status, l10n);
    final dateDisplay = '${request.appointment.date} • ${request.appointment.time}';
    final serviceName = request.selectedServices.isNotEmpty ? request.selectedServices.first.serviceName : 'Service';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (_) => RequestDetailsBloc(bookingsRepository: _repository),
              child: RequestDetailsScreen(
                requestId: request.id,
                currentUserId: userId,
                isProvider: false,
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Provider & Status
            FutureBuilder<UserModel?>(
              future: _getProviderDetails(request.providerId),
              builder: (context, snapshot) {
                final provider = snapshot.data;
                final providerName = provider != null ? '${provider.firstName} ${provider.lastName}' : '...';
                final providerImage = provider?.imageUrl;
                final category = request.selectedServices.isNotEmpty ? request.selectedServices.first.categoryName : '';

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                            backgroundImage: providerImage != null && providerImage.isNotEmpty
                                ? CachedNetworkImageProvider(providerImage)
                                : null,
                            child: providerImage == null || providerImage.isEmpty
                                ? const Icon(Icons.person, color: AppColors.primaryBlue)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  providerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  category,
                                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
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
                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Service Name & ID
            Text(
              serviceName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.bookingId ?? "Booking ID"} #${request.id.substring(0, 8).toUpperCase()}',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
            ),
            // Date, Time & Location Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Text(
                        dateDisplay,
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          request.location.formattedAddress,
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Price & Bottom Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${request.pricing.amount}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3.0),
                      child: Text(
                        request.pricing.currency,
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to details (same as tapping card)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (_) => RequestDetailsBloc(bookingsRepository: _repository),
                          child: RequestDetailsScreen(
                            requestId: request.id,
                            currentUserId: userId,
                            isProvider: false,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Text(l10n.viewDetails ?? 'View Details', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
