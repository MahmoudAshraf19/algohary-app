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

  /// Accept changes (User).
  ///
  /// The terms that get applied are read from the server inside a transaction
  /// (not from the client-side copy the user was looking at). Otherwise a
  /// provider revising the proposal at the same moment would let the user
  /// accept a price / appointment they never saw.
  /// [acceptedProposal] is kept for API compatibility and only used to detect
  /// that the proposal changed while the user was deciding.
  Future<void> acceptProposedChanges({
    required String requestId,
    required String userId,
    required Map<String, dynamic> acceptedProposal,
  }) async {
    final docRef = _requestsCol.doc(requestId);
    final historyRef = docRef.collection('statusHistory').doc();

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      if (!snap.exists) throw Exception('Request not found');

      final data = snap.data() as Map<String, dynamic>;
      if (data['userId'] != userId) {
        throw Exception('Not allowed');
      }
      if (ServiceRequestStatusExt.fromString((data['status'] ?? '').toString()) !=
          ServiceRequestStatus.changeProposed) {
        throw Exception('Proposal is no longer pending');
      }

      final serverProposal = data['currentProposal'];
      if (serverProposal is! Map) {
        throw Exception('Proposal not found');
      }
      final proposal = Map<String, dynamic>.from(serverProposal);

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

      if (proposal['pricing'] != null) {
        updateData['pricing'] = proposal['pricing'];
      }
      if (proposal['appointment'] != null) {
        updateData['appointment'] = proposal['appointment'];
      }

      transaction.update(docRef, updateData);
      transaction.set(
        historyRef,
        StatusHistoryModel(
          status: ServiceRequestStatus.approved.value,
          performedBy: 'USER',
          performedById: userId,
          message: 'User accepted proposed changes',
          createdAt: DateTime.now(),
        ).toJson(),
      );
    });
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

      // Only the two parties of the request may complete it, and only while it
      // is still active (never revive cancelled / rejected / expired requests).
      if (isProvider ? request.providerId != userId : request.userId != userId) {
        throw Exception('Not allowed');
      }
      const notCompletableStatuses = {
        ServiceRequestStatus.completed,
        ServiceRequestStatus.rejected,
        ServiceRequestStatus.cancelledByUser,
        ServiceRequestStatus.cancelledByProvider,
        ServiceRequestStatus.expired,
        ServiceRequestStatus.pendingProviderApproval,
        ServiceRequestStatus.changeProposed,
        ServiceRequestStatus.pendingProviderConfirmation,
      };
      if (notCompletableStatuses.contains(request.status)) {
        throw Exception('Request cannot be completed in its current status');
      }
      if (isProvider ? request.isCompletedByProvider : request.isCompletedByUser) {
        return; // already marked by this side: nothing to do (idempotent)
      }

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

    // Complaint + history entry + notification are written atomically so a
    // partial failure can never leave a complaint behind while the user is told
    // the submission failed (which previously produced duplicate complaints).
    final batch = _firestore.batch();
    batch.set(docRef, complaintWithId.toJson());

    // Also update request history to reflect complaint
    final historyRef = _requestsCol.doc(complaint.bookingId).collection('statusHistory').doc();
    final history = StatusHistoryModel(
      status: 'COMPLAINT_FILED',
      performedBy: complaint.submittedBy,
      performedById: complaint.submittedById,
      message: 'Complaint filed: ${complaint.reason}',
      createdAt: DateTime.now(),
    );
    batch.set(historyRef, history.toJson());

    final shortId = complaint.bookingId.length > 5
        ? complaint.bookingId.substring(0, 5)
        : complaint.bookingId;
    _addNotification(
      batch,
      userId: complaint.againstId,
      title: 'New Complaint Filed',
      body: 'A complaint has been filed against you regarding booking #$shortId',
      type: 'COMPLAINT',
      relatedId: complaint.bookingId,
    );

    await batch.commit();
  }

  /// Queues an in-app notification in [batch].
  ///
  /// It is written to `users/{userId}/notifications` with the same field names
  /// the app reads (`referenceId`, ...). The previous top-level `notifications`
  /// collection (`userId` / `relatedId`) was never read by [NotificationService],
  /// so complaint notifications never appeared in the app.
  void _addNotification(
    WriteBatch batch, {
    required String userId,
    required String title,
    required String body,
    required String type,
    required String relatedId,
  }) {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc();
    batch.set(ref, {
      'title': title,
      'body': body,
      'type': type,
      'referenceId': relatedId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
