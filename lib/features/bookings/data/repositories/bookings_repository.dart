import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_models.dart';
import '../../../../core/network/firebase_config.dart';

class BookingsRepository {
  final FirebaseFirestore _firestore;

  BookingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseConfig.firestore;

  // Collection References
  CollectionReference get _requestsCol => _firestore.collection('serviceRequests');

  /// Create a new Service Request
  Future<String> createServiceRequest(ServiceRequestModel request) async {
    final docRef = _requestsCol.doc();
    final requestWithId = ServiceRequestModel(
      id: docRef.id,
      userId: request.userId,
      providerId: request.providerId,
      status: request.status,
      selectedServices: request.selectedServices,
      appointment: request.appointment,
      location: request.location,
      pricing: request.pricing,
      originalRequest: request.originalRequest,
      currentProposal: request.currentProposal,
      revisionNumber: request.revisionNumber,
      lastAction: request.lastAction,
      userConfirmedProviderContact: request.userConfirmedProviderContact,
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
    );

    final batch = _firestore.batch();
    batch.set(docRef, requestWithId.toJson());

    // Also write initial status history
    final historyRef = docRef.collection('statusHistory').doc();
    final initialHistory = StatusHistoryModel(
      status: request.status.value,
      performedBy: 'USER',
      performedById: request.userId,
      message: 'Request submitted',
      createdAt: DateTime.now(),
    );
    batch.set(historyRef, initialHistory.toJson());

    await batch.commit();
    return docRef.id;
  }

  /// Stream all requests for a specific user (either customer or provider)
  Stream<List<ServiceRequestModel>> streamUserRequests(String userId, {bool isProvider = false}) {
    final fieldName = isProvider ? 'providerId' : 'userId';
    return _requestsCol
        .where(fieldName, isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ServiceRequestModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Stream a single request's details
  Stream<ServiceRequestModel?> streamRequestDetails(String requestId) {
    return _requestsCol.doc(requestId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ServiceRequestModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Update request status
  Future<void> updateRequestStatus({
    required String requestId,
    required ServiceRequestStatus newStatus,
    required String performedBy,
    required String performedById,
    String? message,
  }) async {
    final docRef = _requestsCol.doc(requestId);
    final batch = _firestore.batch();

    final action = RequestActionModel(
      type: 'STATUS_UPDATE',
      performedBy: performedBy,
      performedById: performedById,
      performedAt: DateTime.now(),
    );

    batch.update(docRef, {
      'status': newStatus.value,
      'lastAction': action.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final historyRef = docRef.collection('statusHistory').doc();
    final history = StatusHistoryModel(
      status: newStatus.value,
      performedBy: performedBy,
      performedById: performedById,
      message: message ?? 'Status updated to ${newStatus.value}',
      createdAt: DateTime.now(),
    );
    batch.set(historyRef, history.toJson());

    await batch.commit();
  }

  /// Propose changes (Provider to User)
  Future<void> proposeChanges({
    required String requestId,
    required RequestRevisionModel revision,
    required Map<String, dynamic> newProposal,
  }) async {
    final docRef = _requestsCol.doc(requestId);
    final revisionRef = docRef.collection('revisions').doc();
    
    final batch = _firestore.batch();

    final action = RequestActionModel(
      type: 'CHANGE_PROPOSED',
      performedBy: revision.proposedBy,
      performedById: revision.proposedById,
      performedAt: DateTime.now(),
    );

    // Update main document
    batch.update(docRef, {
      'status': ServiceRequestStatus.changeProposed.value,
      'revisionNumber': FieldValue.increment(1),
      'currentProposal': newProposal,
      'lastAction': action.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Add revision
    batch.set(revisionRef, revision.toJson());

    // Add history
    final historyRef = docRef.collection('statusHistory').doc();
    final history = StatusHistoryModel(
      status: ServiceRequestStatus.changeProposed.value,
      performedBy: revision.proposedBy,
      performedById: revision.proposedById,
      message: revision.reason,
      createdAt: DateTime.now(),
    );
    batch.set(historyRef, history.toJson());

    await batch.commit();
  }

  /// Accept changes (User)
  Future<void> acceptProposedChanges({
    required String requestId,
    required String userId,
    required Map<String, dynamic> acceptedProposal,
  }) async {
    final docRef = _requestsCol.doc(requestId);
    final batch = _firestore.batch();

    final action = RequestActionModel(
      type: 'CHANGES_ACCEPTED',
      performedBy: 'USER',
      performedById: userId,
      performedAt: DateTime.now(),
    );

    // We overwrite the pricing and appointment with the accepted proposal
    // Note: The specific fields (pricing, appointment, etc.) should ideally be parsed carefully here.
    // Assuming acceptedProposal has 'pricing' and 'appointment' maps.
    batch.update(docRef, {
      'status': ServiceRequestStatus.pendingProviderConfirmation.value,
      'pricing': acceptedProposal['pricing'] ?? FieldValue.delete(),
      'appointment': acceptedProposal['appointment'] ?? FieldValue.delete(),
      'currentProposal': null, // Clear proposal since it's accepted
      'lastAction': action.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final historyRef = docRef.collection('statusHistory').doc();
    final history = StatusHistoryModel(
      status: ServiceRequestStatus.pendingProviderConfirmation.value,
      performedBy: 'USER',
      performedById: userId,
      message: 'User accepted proposed changes',
      createdAt: DateTime.now(),
    );
    batch.set(historyRef, history.toJson());

    await batch.commit();
  }
}
