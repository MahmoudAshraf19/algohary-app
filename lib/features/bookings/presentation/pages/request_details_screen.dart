import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/request_details/request_details_bloc.dart';
import '../bloc/request_details/request_details_event.dart';
import '../bloc/request_details/request_details_state.dart';
import '../../data/models/booking_models.dart';

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
  @override
  void initState() {
    super.initState();
    context.read<RequestDetailsBloc>().add(LoadRequestDetailsEvent(widget.requestId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
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
            
            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Status: ${request.status.value}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Services', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...request.selectedServices.map((s) => Text('- ${s.serviceName} (x${s.quantity})')),
                    const SizedBox(height: 16),
                    const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${request.appointment.date} at ${request.appointment.time}'),
                    const SizedBox(height: 16),
                    const Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${request.pricing.amount} ${request.pricing.currency}'),
                    const SizedBox(height: 32),
                    if (state.isProcessingAction)
                      const Center(child: CircularProgressIndicator())
                    else
                      _buildActionButtons(context, request),
                  ],
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ServiceRequestModel request) {
    if (widget.isProvider) {
      if (request.status == ServiceRequestStatus.pendingProviderApproval) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                context.read<RequestDetailsBloc>().add(ApproveRequestEvent(widget.currentUserId));
              },
              child: const Text('Approve'),
            ),
            ElevatedButton(
              onPressed: () {
                // In real app, open dialog to get reason
                context.read<RequestDetailsBloc>().add(RejectRequestEvent(
                  providerId: widget.currentUserId,
                  reason: 'Not available',
                ));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      } else if (request.status == ServiceRequestStatus.pendingProviderConfirmation) {
        return ElevatedButton(
          onPressed: () {
            context.read<RequestDetailsBloc>().add(ConfirmUpdatedRequestEvent(widget.currentUserId));
          },
          child: const Text('Confirm Updated Request'),
        );
      }
    } else {
      // Customer
      if (request.status == ServiceRequestStatus.changeProposed) {
        return ElevatedButton(
          onPressed: () {
            // Assume we accept the currentProposal
            if (request.currentProposal != null) {
              context.read<RequestDetailsBloc>().add(AcceptChangesEvent(
                userId: widget.currentUserId,
                acceptedProposal: request.currentProposal!,
              ));
            }
          },
          child: const Text('Accept Proposed Changes'),
        );
      }
    }
    
    return const SizedBox.shrink();
  }
}
