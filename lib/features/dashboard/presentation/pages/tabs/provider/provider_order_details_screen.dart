import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:algohary_project/core/network/firebase_config.dart';
import 'package:intl/intl.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../../auth/presentation/bloc/auth_state.dart';
import '../../../../../bookings/data/models/booking_models.dart';
import '../../../../../bookings/data/repositories/bookings_repository.dart';
import 'complaint_screen.dart';

class ProviderOrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const ProviderOrderDetailsScreen({super.key, required this.orderId});

  @override
  State<ProviderOrderDetailsScreen> createState() => _ProviderOrderDetailsScreenState();
}

class _ProviderOrderDetailsScreenState extends State<ProviderOrderDetailsScreen> {
  final BookingsRepository _repo = BookingsRepository();

  void _updateStatus(ServiceRequestStatus newStatus, String currentUserId) async {
    try {
      await _repo.updateRequestStatus(
        requestId: widget.orderId,
        newStatus: newStatus,
        performedBy: 'PROVIDER',
        performedById: currentUserId,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showProposePriceDialog(ServiceRequestModel order, String currentUserId, ColorScheme colorScheme, AppLocalizations l10n) {
    final controller = TextEditingController(text: order.pricing.amount.toString());
    
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colorScheme.surface,
        title: Text(
          l10n.proposeNewPrice ?? 'Propose New Price',
          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.category ?? "Category"}: ${order.selectedServices.firstOrNull?.serviceName ?? ""}',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
              decoration: InputDecoration(
                labelText: '${l10n.newPrice ?? "New Price"} (${order.pricing.currency})',
                labelStyle: TextStyle(color: colorScheme.primary),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                prefixIcon: Icon(Icons.attach_money, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.btnCancel ?? 'Cancel', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAmount = double.tryParse(controller.text);
              if (newAmount == null) return;
              
              Navigator.pop(ctx);
              try {
                final revision = RequestRevisionModel(
                  revisionNumber: order.revisionNumber + 1,
                  proposedBy: 'PROVIDER',
                  proposedById: currentUserId,
                  changes: {'price': newAmount},
                  reason: 'Provider proposed a new price of $newAmount',
                  status: 'PENDING',
                  createdAt: DateTime.now(),
                );
                
                final newProposal = {
                  'pricing': {
                    'amount': newAmount,
                    'currency': order.pricing.currency,
                    'priceSource': 'PROVIDER_PROPOSAL',
                  }
                };

                await _repo.proposeChanges(
                  requestId: widget.orderId,
                  revision: revision,
                  newProposal: newProposal,
                );
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.submit ?? 'Submit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    
    final authState = context.read<AuthBloc>().state;
    final user = (authState is AuthSuccess) ? authState.user : null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Order Details', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: StreamBuilder<ServiceRequestModel?>(
        stream: _repo.streamRequestDetails(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Order not found'));
          }

          final order = snapshot.data!;
          final date = order.appointment.timestamp != null 
              ? DateFormat('MMM d, yyyy').format(order.appointment.timestamp!)
              : order.appointment.date;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Info (Ideally fetched from users collection)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseConfig.firestore.collection('users').doc(order.userId).get(),
                  builder: (context, userSnap) {
                    String customerName = 'Customer';
                    String customerPhone = 'N/A';
                    if (userSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (userSnap.hasData && userSnap.data!.exists) {
                      final data = userSnap.data!.data() as Map<String, dynamic>;
                      customerName = '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
                      if (customerName.isEmpty) customerName = 'Customer';
                      customerPhone = data['phone'] ?? 'N/A';
                    }
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.person, color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)),
                                const SizedBox(height: 4),
                                Text(customerPhone, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
                const SizedBox(height: 24),
                
                // Order Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.build, order.selectedServices.isNotEmpty ? order.selectedServices.first.serviceName : 'Service', '#ORD-${order.id.substring(0, 5).toUpperCase()}', colorScheme),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                      _buildInfoRow(Icons.schedule, 'Scheduled Time', '$date, ${order.appointment.time}', colorScheme),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                      _buildInfoRow(Icons.location_on, 'Location', order.location.formattedAddress, colorScheme),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Services List
                Text('Service Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      ...order.selectedServices.map((service) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(service.serviceName, style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                            Text('x${service.quantity}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                      const Divider(height: 24),
                      if (order.status == ServiceRequestStatus.changeProposed && order.currentProposal != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Original Total', style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16, color: colorScheme.onSurfaceVariant, decoration: TextDecoration.lineThrough)),
                            Text('${order.pricing.amount} ${order.pricing.currency}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.normal, fontSize: 16, decoration: TextDecoration.lineThrough)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Proposed Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                            Text('${order.currentProposal!["pricing"]["amount"]} ${order.currentProposal!["pricing"]["currency"]}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)),
                            Text('${order.pricing.amount} ${order.pricing.currency}', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons based on Status
                _buildActionButtons(order, user!.id, colorScheme, l10n),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ServiceRequestModel order, String currentUserId, ColorScheme colorScheme, AppLocalizations l10n) {
    if (order.status == ServiceRequestStatus.pendingProviderApproval) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _updateStatus(ServiceRequestStatus.approved, currentUserId),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(l10n.acceptOrder ?? 'Accept Order', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _showProposePriceDialog(order, currentUserId, colorScheme, l10n),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Propose Price Change', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _updateStatus(ServiceRequestStatus.rejected, currentUserId),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(l10n.declineOrder ?? 'Decline', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    } else if (order.status == ServiceRequestStatus.changeProposed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'Awaiting User Confirmation',
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'You proposed: ${order.currentProposal?['pricing']?['amount']} ${order.pricing.currency}',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => _updateStatus(ServiceRequestStatus.cancelledByProvider, currentUserId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(l10n.cancelBooking ?? 'Cancel Booking', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    } else if (order.status == ServiceRequestStatus.approved) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _updateStatus(ServiceRequestStatus.inProgress, currentUserId),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(l10n.updateStatus ?? 'Update Status to In Progress', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _updateStatus(ServiceRequestStatus.cancelledByProvider, currentUserId),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(l10n.cancelBooking ?? 'Cancel Booking', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    } else if (order.status == ServiceRequestStatus.inProgress) {
      return SizedBox(
        child: ElevatedButton(
          onPressed: () async {
            if (order.isCompletedByProvider) return;
            try {
              await _repo.markAsCompleted(requestId: order.id, userId: currentUserId, isProvider: true);
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: order.isCompletedByProvider ? Colors.grey : Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            order.isCompletedByProvider ? 'Awaiting User Confirmation' : 'Mark as Completed', 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
        ),
      );
    } 
    
    if (order.status == ServiceRequestStatus.completed || 
        order.status == ServiceRequestStatus.inProgress || 
        order.status == ServiceRequestStatus.cancelledByUser || 
        order.status == ServiceRequestStatus.cancelledByProvider || 
        order.status == ServiceRequestStatus.rejected) {
      
      Widget? existingButton;
      if (order.status == ServiceRequestStatus.completed || order.status == ServiceRequestStatus.cancelledByUser || order.status == ServiceRequestStatus.cancelledByProvider || order.status == ServiceRequestStatus.rejected) {
         existingButton = Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Order Status: ${order.status.value}',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
          );
      }

      return Column(
        children: [
          if (existingButton != null) existingButton,
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintScreen(order: order)));
            },
            icon: const Icon(Icons.report_problem, color: Colors.orange),
            label: Text(l10n.fileComplaint ?? 'File a Complaint', style: const TextStyle(color: Colors.orange)),
          ),
        ],
      );
    }
    
    // Fallback for other statuses like pendingProviderConfirmation, changeProposed
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Order Status: ${order.status.value}',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      ),
    );
  }
}
