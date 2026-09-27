import 'package:equatable/equatable.dart';
import 'package:algohary_project/features/subscriptions/data/models/subscription_plan_model.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class FetchSubscriptionPlans extends SubscriptionEvent {}

class ActivateSubscription extends SubscriptionEvent {
  final String userId;
  final SubscriptionPlanModel plan;
  final String notificationTitle;
  final String notificationBody;

  const ActivateSubscription({
    required this.userId,
    required this.plan,
    required this.notificationTitle,
    required this.notificationBody,
  });

  @override
  List<Object?> get props => [userId, plan, notificationTitle, notificationBody];
}
