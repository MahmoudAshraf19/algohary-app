import 'package:equatable/equatable.dart';
import 'package:algohary_project/features/subscriptions/data/models/subscription_plan_model.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final List<SubscriptionPlanModel> plans;

  const SubscriptionLoaded({required this.plans});

  @override
  List<Object?> get props => [plans];
}

class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError({required this.message});

  @override
  List<Object?> get props => [message];
}

class SubscriptionActivating extends SubscriptionState {}

class SubscriptionActivated extends SubscriptionState {}
