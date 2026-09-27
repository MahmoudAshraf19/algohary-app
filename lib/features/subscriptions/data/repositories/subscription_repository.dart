import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:algohary_project/core/network/firebase_config.dart';
import 'package:algohary_project/features/subscriptions/data/models/subscription_plan_model.dart';
import 'package:algohary_project/features/auth/data/models/user_model.dart';

import 'package:flutter/foundation.dart';

class SubscriptionRepository {
  final FirebaseFirestore _firestore;

  SubscriptionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseConfig.firestore;

  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    try {
      final snapshot = await _firestore.collection('subscription_plans').get();
      return snapshot.docs
          .map((doc) => SubscriptionPlanModel.fromMap(doc.data(), doc.id))
          .where((plan) => plan.isEnable)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch subscription plans: $e');
    }
  }

  Future<void> activateSubscription({
    required String userId,
    required SubscriptionPlanModel plan,
    required String notificationTitle,
    required String notificationBody,
  }) async {
    debugPrint('==================================================');
    debugPrint('DEBUG: activateSubscription called in Repository');
    debugPrint('DEBUG: userId is $userId');
    debugPrint('DEBUG: plan is ${plan.id} - ${plan.name}');
    try {
      final now = DateTime.now();
      DateTime? endDate;

      if (plan.expiryDay != '-1') {
        int days = int.tryParse(plan.expiryDay) ?? 0;
        endDate = now.add(Duration(days: days));
      }

      final subscriptionData = {
        'is_subscribed': true,
        'is_active': true,
        'plan': plan.id,
        'start_date': FieldValue.serverTimestamp(),
        'end_date': endDate,
      };

      await _firestore.collection('users').doc(userId).update({
        'subscription': subscriptionData,
        'is_active': true, // Add root level is_active true
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Insert notification
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': notificationTitle,
        'body': notificationBody,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'subscription',
      });
      debugPrint('DEBUG: Firestore update and notification insert SUCCESSFUL');
    } catch (e) {
      debugPrint('DEBUG: ERROR in activateSubscription: $e');
      throw Exception('Failed to activate subscription: $e');
    }
  }
}
