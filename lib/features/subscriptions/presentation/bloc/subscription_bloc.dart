import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/features/subscriptions/data/repositories/subscription_repository.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository repository;

  SubscriptionBloc({required this.repository}) : super(SubscriptionInitial()) {
    on<FetchSubscriptionPlans>(_onFetchSubscriptionPlans);
    on<ActivateSubscription>(_onActivateSubscription);
  }

  Future<void> _onFetchSubscriptionPlans(
    FetchSubscriptionPlans event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final plans = await repository.getSubscriptionPlans();
      // Sort plans by place
      plans.sort((a, b) => (int.tryParse(a.place) ?? 0).compareTo(int.tryParse(b.place) ?? 0));
      emit(SubscriptionLoaded(plans: plans));
    } catch (e) {
      emit(SubscriptionError(message: e.toString()));
    }
  }

  Future<void> _onActivateSubscription(
    ActivateSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    debugPrint('==================================================');
    debugPrint('DEBUG: _onActivateSubscription called in Bloc');
    // Save previous state to revert if needed
    final currentState = state;
    emit(SubscriptionActivating());
    try {
      await repository.activateSubscription(
        userId: event.userId,
        plan: event.plan,
        notificationTitle: event.notificationTitle,
        notificationBody: event.notificationBody,
      );
      debugPrint('DEBUG: activateSubscription returned successfully');
      emit(SubscriptionActivated());
      if (currentState is SubscriptionLoaded) {
        emit(SubscriptionLoaded(plans: currentState.plans));
      }
    } catch (e) {
      debugPrint('DEBUG: ERROR in _onActivateSubscription: $e');
      emit(SubscriptionError(message: e.toString()));
      if (currentState is SubscriptionLoaded) {
        emit(SubscriptionLoaded(plans: currentState.plans)); // Restore state after error
      }
    }
  }
}
