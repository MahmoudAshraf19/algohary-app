import 'package:equatable/equatable.dart';
import '../../../data/models/booking_models.dart';

abstract class RequestDetailsState extends Equatable {
  const RequestDetailsState();

  @override
  List<Object?> get props => [];
}

class RequestDetailsInitial extends RequestDetailsState {}

class RequestDetailsLoading extends RequestDetailsState {}

class RequestDetailsLoaded extends RequestDetailsState {
  final ServiceRequestModel request;
  final bool isProcessingAction;
  final String? actionError;

  const RequestDetailsLoaded({
    required this.request,
    this.isProcessingAction = false,
    this.actionError,
  });

  RequestDetailsLoaded copyWith({
    ServiceRequestModel? request,
    bool? isProcessingAction,
    String? actionError,
  }) {
    return RequestDetailsLoaded(
      request: request ?? this.request,
      isProcessingAction: isProcessingAction ?? this.isProcessingAction,
      actionError: actionError, // null by default when copying unless specified
    );
  }

  @override
  List<Object?> get props => [request, isProcessingAction, actionError];
}

class RequestDetailsError extends RequestDetailsState {
  final String message;
  const RequestDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
