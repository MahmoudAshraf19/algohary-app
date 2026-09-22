import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/booking_models.dart';
import '../../../data/repositories/bookings_repository.dart';
import 'request_details_event.dart';
import 'request_details_state.dart';

class RequestDetailsBloc extends Bloc<RequestDetailsEvent, RequestDetailsState> {
  final BookingsRepository _bookingsRepository;
  StreamSubscription<ServiceRequestModel?>? _requestSubscription;

  RequestDetailsBloc({required BookingsRepository bookingsRepository})
      : _bookingsRepository = bookingsRepository,
        super(RequestDetailsInitial()) {
    on<LoadRequestDetailsEvent>(_onLoadRequestDetails);
    on<RequestUpdatedEvent>(_onRequestUpdated);
    on<ApproveRequestEvent>(_onApproveRequest);
    on<RejectRequestEvent>(_onRejectRequest);
    on<ProposeChangesEvent>(_onProposeChanges);
    on<AcceptChangesEvent>(_onAcceptChanges);
    on<ConfirmUpdatedRequestEvent>(_onConfirmUpdatedRequest);
  }

  void _onLoadRequestDetails(LoadRequestDetailsEvent event, Emitter<RequestDetailsState> emit) {
    emit(RequestDetailsLoading());
    _requestSubscription?.cancel();
    _requestSubscription = _bookingsRepository.streamRequestDetails(event.requestId).listen(
      (request) {
        add(RequestUpdatedEvent(request));
      },
      onError: (error) {
        emit(RequestDetailsError('Failed to load request: $error'));
      },
    );
  }

  void _onRequestUpdated(RequestUpdatedEvent event, Emitter<RequestDetailsState> emit) {
    if (event.request == null) {
      emit(const RequestDetailsError('Service request not found.'));
    } else {
      if (state is RequestDetailsLoaded) {
        // Keep processing state if it was there
        emit((state as RequestDetailsLoaded).copyWith(request: event.request));
      } else {
        emit(RequestDetailsLoaded(request: event.request!));
      }
    }
  }

  Future<void> _onApproveRequest(ApproveRequestEvent event, Emitter<RequestDetailsState> emit) async {
    if (state is! RequestDetailsLoaded) return;
    final currentState = state as RequestDetailsLoaded;
    
    emit(currentState.copyWith(isProcessingAction: true));
    try {
      await _bookingsRepository.updateRequestStatus(
        requestId: currentState.request.id,
        newStatus: ServiceRequestStatus.approved,
        performedBy: 'PROVIDER',
        performedById: event.providerId,
        message: 'Request approved by provider.',
      );
      // We don't emit success here because the stream will update the state automatically.
    } catch (e) {
      emit(currentState.copyWith(isProcessingAction: false, actionError: 'Failed to approve request.'));
    }
  }

  Future<void> _onRejectRequest(RejectRequestEvent event, Emitter<RequestDetailsState> emit) async {
    if (state is! RequestDetailsLoaded) return;
    final currentState = state as RequestDetailsLoaded;
    
    emit(currentState.copyWith(isProcessingAction: true));
    try {
      await _bookingsRepository.updateRequestStatus(
        requestId: currentState.request.id,
        newStatus: ServiceRequestStatus.rejected,
        performedBy: 'PROVIDER',
        performedById: event.providerId,
        message: event.reason,
      );
    } catch (e) {
      emit(currentState.copyWith(isProcessingAction: false, actionError: 'Failed to reject request.'));
    }
  }

  Future<void> _onProposeChanges(ProposeChangesEvent event, Emitter<RequestDetailsState> emit) async {
    if (state is! RequestDetailsLoaded) return;
    final currentState = state as RequestDetailsLoaded;
    
    emit(currentState.copyWith(isProcessingAction: true));
    try {
      await _bookingsRepository.proposeChanges(
        requestId: currentState.request.id,
        revision: event.revision,
        newProposal: event.newProposal,
      );
    } catch (e) {
      emit(currentState.copyWith(isProcessingAction: false, actionError: 'Failed to propose changes.'));
    }
  }

  Future<void> _onAcceptChanges(AcceptChangesEvent event, Emitter<RequestDetailsState> emit) async {
    if (state is! RequestDetailsLoaded) return;
    final currentState = state as RequestDetailsLoaded;
    
    emit(currentState.copyWith(isProcessingAction: true));
    try {
      await _bookingsRepository.acceptProposedChanges(
        requestId: currentState.request.id,
        userId: event.userId,
        acceptedProposal: event.acceptedProposal,
      );
    } catch (e) {
      emit(currentState.copyWith(isProcessingAction: false, actionError: 'Failed to accept changes.'));
    }
  }

  Future<void> _onConfirmUpdatedRequest(ConfirmUpdatedRequestEvent event, Emitter<RequestDetailsState> emit) async {
    if (state is! RequestDetailsLoaded) return;
    final currentState = state as RequestDetailsLoaded;
    
    emit(currentState.copyWith(isProcessingAction: true));
    try {
      await _bookingsRepository.updateRequestStatus(
        requestId: currentState.request.id,
        newStatus: ServiceRequestStatus.approved,
        performedBy: 'PROVIDER',
        performedById: event.providerId,
        message: 'Provider confirmed the updated request.',
      );
    } catch (e) {
      emit(currentState.copyWith(isProcessingAction: false, actionError: 'Failed to confirm request.'));
    }
  }

  @override
  Future<void> close() {
    _requestSubscription?.cancel();
    return super.close();
  }
}
