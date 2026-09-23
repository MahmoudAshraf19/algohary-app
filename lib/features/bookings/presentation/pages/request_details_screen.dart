import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:algohary_project/features/auth/data/models/user_model.dart';
import 'package:algohary_project/features/auth/data/repositories/auth_repository.dart';
import '../bloc/request_details/request_details_bloc.dart';
import '../bloc/request_details/request_details_event.dart';
import '../bloc/request_details/request_details_state.dart';
import '../../data/models/booking_models.dart';
import '../../../chat/presentation/pages/chat_detail_screen.dart';
import '../widgets/report_problem_dialog.dart';

class RequestDetailsScreen extends StatefulWidget {
  final String requestId;
  final String currentUserId;
  final bool isProvider;

  const RequestDetailsScreen({
    super.key,
    required this.requestId,
    required this.currentUserId,
    required this.isProvider,
  });

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final AuthRepository _authRepo = AuthRepository();
  UserModel? _otherPartyUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    context.read<RequestDetailsBloc>().add(LoadRequestDetailsEvent(widget.requestId));
  }

  void _loadOtherParty(String targetUserId) async {
    if (_otherPartyUser != null) return;
    try {
      final user = await _authRepo.getUserById(targetUserId);
      if (mounted) {
        setState(() {
          _otherPartyUser = user;
          _isLoadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
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

  void _showCancelDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelBookingConfirmTitle ?? 'Cancel Booking?'),
        content: Text(l10n.cancelBookingConfirmDesc ?? 'Are you sure you want to cancel this booking?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.keepBooking ?? 'Keep Booking', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.isProvider) {
                context.read<RequestDetailsBloc>().add(RejectRequestEvent(
                  providerId: widget.currentUserId,
                  reason: 'Cancelled by provider',
                ));
              } else {
                // Assuming we have CancelRequestEvent or we trigger it another way. For now, we mock.
                // context.read<RequestDetailsBloc>().add(CancelRequestEvent(userId: widget.currentUserId));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancel logic to be implemented')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.cancelBooking ?? 'Cancel Booking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Booking Details', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: theme.colorScheme.surface,
            elevation: 8,
            offset: const Offset(0, 45),
            onSelected: (value) {
              if (value == 'cancel') {
                _showCancelDialog(context, l10n);
              } else if (value == 'report') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) => ReportProblemDialog(
                    bookingId: widget.requestId,
                    currentUserId: widget.currentUserId,
                  ),
                );
              } else if (value == 'support') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(
                      conversationId: 'support_${widget.currentUserId}',
                      recipientId: 'support_admin',
                      recipientName: l10n.contactSupport ?? 'Support',
                      recipientAvatar: 'assets/icons/support_logo.png',
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_problem_outlined, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    const SizedBox(width: 12),
                    Text(l10n.reportProblem ?? 'Report a Problem', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'support',
                child: Row(
                  children: [
                    Icon(Icons.support_agent_outlined, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    const SizedBox(width: 12),
                    Text(l10n.contactSupport ?? 'Contact Support', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<RequestDetailsBloc, RequestDetailsState>(
        listener: (context, state) {
          if (state is RequestDetailsLoaded && state.actionError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.actionError!)),
            );
          }
        },
        builder: (context, state) {
          if (state is RequestDetailsLoading || state is RequestDetailsInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RequestDetailsError) {
            return Center(child: Text(state.message));
          } else if (state is RequestDetailsLoaded) {
            final request = state.request;
            final targetUserId = widget.isProvider ? request.userId : request.providerId;
            
            if (_otherPartyUser == null && _isLoadingUser) {
              _loadOtherParty(targetUserId);
            }

            final isCancelled = request.status == ServiceRequestStatus.cancelledByUser ||
                                request.status == ServiceRequestStatus.cancelledByProvider ||
                                request.status == ServiceRequestStatus.rejected;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 40),
                  children: [
                    _buildStatusHeader(request, l10n, theme),
                    if (isCancelled) _buildCancellationBanner(request, l10n, theme),
                    _buildTimeline(request, l10n, theme),
                    const Divider(height: 32),
                    _buildUserCard(l10n, theme, isDark),
                    _buildServiceSection(request, l10n, theme),
                    _buildRequestDetailsSection(request, l10n, theme),
                    _buildAttachmentsSection(request, l10n, theme),
                    _buildScheduleSection(request, l10n, theme),
                    _buildLocationSection(request, l10n, theme),
                    _buildPricingSection(request, l10n, theme),
                    if (!state.isProcessingAction)
                      _buildActionButtons(context, request, theme, l10n),
                  ],
                ),
                if (state.isProcessingAction)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black26,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatusHeader(ServiceRequestModel request, AppLocalizations l10n, ThemeData theme) {
    final statusColor = _getStatusColor(request.status);
    final statusText = _getLocalizedStatus(request.status, l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.bookingId ?? "Booking ID"} #${request.id.substring(0, 8).toUpperCase()}',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationBanner(ServiceRequestModel request, AppLocalizations l10n, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statusCancelledByUser ?? 'Booking Cancelled',
            style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.cancellationReasonTitle ?? "Reason:"} ${request.originalRequest?["cancellation_reason"] ?? "Customer request"}',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ServiceRequestModel request, AppLocalizations l10n, ThemeData theme) {
    // Determine active step
    int currentStep = 0;
    if (request.status == ServiceRequestStatus.approved || request.status == ServiceRequestStatus.pendingProviderConfirmation) {
      currentStep = 1;
    } else if (request.status == ServiceRequestStatus.inProgress) {
      currentStep = 2;
    } else if (request.status == ServiceRequestStatus.completed) {
      currentStep = 3;
    }

    Widget _buildStep(String title, bool isCompleted, bool isActive) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppColors.primaryBlue : (isActive ? AppColors.primaryBlue.withOpacity(0.2) : theme.colorScheme.surfaceContainerHighest),
                border: Border.all(
                  color: isActive || isCompleted ? AppColors.primaryBlue : theme.colorScheme.surfaceContainerHighest,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : (isActive ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryBlue))) : null),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                color: isActive || isCompleted ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildStep(l10n.timelineRequestSubmitted ?? 'Request Submitted', currentStep > 0, currentStep == 0),
        _buildStep(l10n.timelineProviderConfirmed ?? 'Provider Confirmed', currentStep > 1, currentStep == 1),
        _buildStep(l10n.timelineServiceInProgress ?? 'Service In Progress', currentStep > 2, currentStep == 2),
        _buildStep(l10n.timelineServiceCompleted ?? 'Service Completed', currentStep >= 3, currentStep == 3),
      ],
    );
  }

  Widget _buildUserCard(AppLocalizations l10n, ThemeData theme, bool isDark) {
    final title = widget.isProvider ? 'Customer' : (l10n.serviceProvider ?? 'Service Provider');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _isLoadingUser
              ? const Center(child: CircularProgressIndicator())
              : _otherPartyUser == null
                  ? const Text('Could not load user details')
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                          backgroundImage: _otherPartyUser!.imageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(_otherPartyUser!.imageUrl)
                              : null,
                          child: _otherPartyUser!.imageUrl.isEmpty
                              ? const Icon(Icons.person, color: AppColors.primaryBlue, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_otherPartyUser!.firstName} ${_otherPartyUser!.lastName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                        // Quick Actions
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat_bubble, color: AppColors.primaryBlue),
                              onPressed: () {
                                final ids = [widget.currentUserId, _otherPartyUser!.id];
                                ids.sort();
                                final conversationId = ids.join('_');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatDetailScreen(
                                      conversationId: conversationId,
                                      recipientId: _otherPartyUser!.id,
                                      recipientName: '${_otherPartyUser!.firstName} ${_otherPartyUser!.lastName}',
                                      recipientAvatar: _otherPartyUser!.imageUrl,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
        ],
      ),
    );
  }

  Widget _buildServiceSection(ServiceRequestModel request, AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.serviceDetails ?? 'Service Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (request.selectedServices.isNotEmpty) ...[
            Text(
              request.selectedServices.first.serviceName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 4),
            Text(
              request.selectedServices.first.categoryName,
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(l10n.selectedServices ?? 'Selected Services', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...request.selectedServices.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.serviceName, style: const TextStyle(fontSize: 15))),
                  Text('×${s.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            )),
          ]
        ],
      ),
    );
  }

  Widget _buildRequestDetailsSection(ServiceRequestModel request, AppLocalizations l10n, ThemeData theme) {
    final notes = request.originalRequest?['notes'] ?? '';
    if (notes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.requestDetails ?? 'Request Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Additional Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            notes,
            style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.8), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(ServiceRequestModel request, AppLocalizations l10n, ThemeData theme) {
    final attachments = request.originalRequest?['attachments'] as List<dynamic>? ?? [];
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.attachmentsTitle ?? 'Attachments', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: attachments.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerHighest,
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(attachments[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(ServiceRequestModel request, AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.scheduleTitle ?? 'Schedule', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                        Text(request.appointment.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Time', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                        Text(request.appointment.time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(ServiceRequestModel request, AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.serviceLocation ?? 'Service Location', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: AppColors.primaryBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Address', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      request.location.formattedAddress,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {}, // Map intent
                      child: Text(
                        l10n.openInMaps ?? 'Open in Maps',
                        style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(ServiceRequestModel request, AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.paymentSummary ?? 'Payment Summary', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildPriceRow(l10n.serviceFee ?? 'Service Fee', '${request.pricing.amount} ${request.pricing.currency}'),
          const SizedBox(height: 8),
          _buildPriceRow(l10n.discount ?? 'Discount', '-0 ${request.pricing.currency}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _buildPriceRow(l10n.total ?? 'Total', '${request.pricing.amount} ${request.pricing.currency}', isTotal: true),
          
          const SizedBox(height: 24),
          Text(l10n.paymentMethod ?? 'Payment Method', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.money, color: Colors.green),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.paymentCash ?? 'Cash on Service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(l10n.paymentStatusUnpaid ?? 'Payment Status: Unpaid', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ServiceRequestModel request, ThemeData theme, AppLocalizations l10n) {
    List<Widget> buttons = [];

    if (widget.isProvider) {
      if (request.status == ServiceRequestStatus.pendingProviderApproval) {
        buttons = [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                context.read<RequestDetailsBloc>().add(RejectRequestEvent(
                  providerId: widget.currentUserId,
                  reason: 'Not available',
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red.withOpacity(0.1),
                foregroundColor: AppColors.red,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                context.read<RequestDetailsBloc>().add(ApproveRequestEvent(widget.currentUserId));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ];
      }
    } else {
      // Customer
      if (request.status == ServiceRequestStatus.changeProposed) {
        buttons = [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (request.currentProposal != null) {
                  context.read<RequestDetailsBloc>().add(AcceptChangesEvent(
                    userId: widget.currentUserId,
                    acceptedProposal: request.currentProposal!,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Accept Proposal', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ];
      }
      
      // Can cancel if it's pending or approved
      bool canCancel = request.status == ServiceRequestStatus.pendingProviderApproval || 
                       request.status == ServiceRequestStatus.pendingProviderConfirmation || 
                       request.status == ServiceRequestStatus.approved ||
                       request.status == ServiceRequestStatus.changeProposed;
                       
      if (canCancel) {
        if (buttons.isNotEmpty) {
          buttons.add(const SizedBox(width: 16));
        }
        buttons.add(
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showCancelDialog(context, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red.withOpacity(0.1),
                foregroundColor: AppColors.red,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.cancelBooking ?? 'Cancel Booking', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        );
      }
    }
    
    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(children: buttons),
    );
  }
}
