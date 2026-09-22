import 'package:equatable/equatable.dart';
import '../../../data/models/booking_models.dart';

abstract class RequestDetailsEvent extends Equatable {
  const RequestDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadRequestDetailsEvent extends RequestDetailsEvent {
  final String requestId;
  const LoadRequestDetailsEvent(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class RequestUpdatedEvent extends RequestDetailsEvent {
  final ServiceRequestModel? request;
  const RequestUpdatedEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class ApproveRequestEvent extends RequestDetailsEvent {
  final String providerId;
  const ApproveRequestEvent(this.providerId);

  @override
  List<Object?> get props => [providerId];
}

class RejectRequestEvent extends RequestDetailsEvent {
  final String providerId;
  final String reason;
  const RejectRequestEvent({required this.providerId, required this.reason});

  @override
  List<Object?> get props => [providerId, reason];
}

class ProposeChangesEvent extends RequestDetailsEvent {
  final String providerId;
  final RequestRevisionModel revision;
  final Map<String, dynamic> newProposal;
  
  const ProposeChangesEvent({
    required this.providerId,
    required this.revision,
    required this.newProposal,
  });

  @override
  List<Object?> get props => [providerId, revision, newProposal];
}

class AcceptChangesEvent extends RequestDetailsEvent {
  final String userId;
  final Map<String, dynamic> acceptedProposal;
  
  const AcceptChangesEvent({
    required this.userId,
    required this.acceptedProposal,
  });

  @override
  List<Object?> get props => [userId, acceptedProposal];
}

class ConfirmUpdatedRequestEvent extends RequestDetailsEvent {
  final String providerId;
  
  const ConfirmUpdatedRequestEvent(this.providerId);

  @override
  List<Object?> get props => [providerId];
}
