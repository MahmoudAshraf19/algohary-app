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

    final updateData = <String, dynamic>{
      'status': ServiceRequestStatus.approved.value,
      'currentProposal': FieldValue.delete(),
      'lastAction': action.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (acceptedProposal['pricing'] != null) {
      updateData['pricing'] = acceptedProposal['pricing'];
    }
    if (acceptedProposal['appointment'] != null) {
      updateData['appointment'] = acceptedProposal['appointment'];
    }

    batch.update(docRef, updateData);

    final historyRef = docRef.collection('statusHistory').doc();
    final history = StatusHistoryModel(
      status: ServiceRequestStatus.approved.value,
      performedBy: 'USER',
      performedById: userId,
      message: 'User accepted proposed changes',
      createdAt: DateTime.now(),
    );
    batch.set(historyRef, history.toJson());

    await batch.commit();
  }

  /// Mark request as completed (by User or Provider)
  Future<void> markAsCompleted({
    required String requestId,
    required String userId,
    required bool isProvider,
  }) async {
    final docRef = _requestsCol.doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final docSnap = await transaction.get(docRef);
      if (!docSnap.exists) throw Exception('Request not found');

      final request = ServiceRequestModel.fromJson(docSnap.data() as Map<String, dynamic>, docSnap.id);
      
      bool willBeCompleted = false;
      if (isProvider) {
        if (request.isCompletedByUser) willBeCompleted = true;
      } else {
        if (request.isCompletedByProvider) willBeCompleted = true;
      }

      final action = RequestActionModel(
        type: willBeCompleted ? 'COMPLETED' : 'MARKED_COMPLETED',
        performedBy: isProvider ? 'PROVIDER' : 'USER',
        performedById: userId,
        performedAt: DateTime.now(),
      );

      transaction.update(docRef, {
        if (isProvider) 'isCompletedByProvider': true,
        if (!isProvider) 'isCompletedByUser': true,
        if (willBeCompleted) 'status': ServiceRequestStatus.completed.value,
        'lastAction': action.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final historyRef = docRef.collection('statusHistory').doc();
      final history = StatusHistoryModel(
        status: willBeCompleted ? ServiceRequestStatus.completed.value : request.status.value,
        performedBy: isProvider ? 'PROVIDER' : 'USER',
        performedById: userId,
        message: willBeCompleted ? 'Order completed' : 'Marked order as completed, waiting for confirmation',
        createdAt: DateTime.now(),
      );
      transaction.set(historyRef, history.toJson());
    });
  }

  /// Submit a complaint
  Future<void> submitComplaint(ComplaintModel complaint) async {
    final docRef = _firestore.collection('complaints').doc();
    final complaintWithId = ComplaintModel(
      id: docRef.id,
      bookingId: complaint.bookingId,
      submittedBy: complaint.submittedBy,
      submittedById: complaint.submittedById,
      againstId: complaint.againstId,
      reason: complaint.reason,
      description: complaint.description,
      status: complaint.status,
      createdAt: complaint.createdAt,
    );
    await docRef.set(complaintWithId.toJson());

    // Also update request history to reflect complaint
    final historyRef = _requestsCol.doc(complaint.bookingId).collection('statusHistory').doc();
    final history = StatusHistoryModel(
      status: 'COMPLAINT_FILED',
      performedBy: complaint.submittedBy,
      performedById: complaint.submittedById,
      message: 'Complaint filed: ${complaint.reason}',
      createdAt: DateTime.now(),
    );
    await historyRef.set(history.toJson());

    // Send notification
    await _sendNotification(
      userId: complaint.againstId,
      title: 'New Complaint Filed',
      body: 'A complaint has been filed against you regarding booking #${complaint.bookingId.substring(0, 5)}',
      type: 'COMPLAINT',
      relatedId: complaint.bookingId,
    );
  }

  /// Helper to send a notification (writes to Firestore, assumes Cloud Functions will send FCM)
  Future<void> _sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String relatedId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
