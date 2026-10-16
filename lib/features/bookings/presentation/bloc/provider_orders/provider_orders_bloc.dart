import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/booking_models.dart';
import '../../../data/repositories/bookings_repository.dart';
import 'provider_orders_event.dart';
import 'provider_orders_state.dart';

class ProviderOrdersBloc extends Bloc<ProviderOrdersEvent, ProviderOrdersState> {
  final BookingsRepository _bookingsRepository;
  StreamSubscription<List<ServiceRequestModel>>? _ordersSubscription;

  ProviderOrdersBloc({required this._bookingsRepository})
      : super(ProviderOrdersInitial()) {
    on<LoadProviderOrders>(_onLoadProviderOrders);
    on<FilterOrders>(_onFilterOrders);
    on<_OrdersUpdated>(_onOrdersUpdated);
    on<_OrdersError>(_onOrdersError);
  }

  /// Applies the search query to [orders].
  List<ServiceRequestModel> _applyFilters(List<ServiceRequestModel> orders, String? searchQuery) {
    if (searchQuery == null || searchQuery.trim().isEmpty) {
      return List<ServiceRequestModel>.from(orders);
    }
    final query = searchQuery.trim().toLowerCase();
    return orders.where((order) {
      // You might want to get the actual user name, but for now we search by ID or services
      return order.selectedServices.any((s) => s.serviceName.toLowerCase().contains(query)) ||
          order.id.toLowerCase().contains(query);
    }).toList();
  }

  void _onOrdersUpdated(_OrdersUpdated event, Emitter<ProviderOrdersState> emit) {
    // A live update used to reset the list to "unfiltered" while the search box
    // still showed the old query. Re-apply the active filters instead.
    final current = state;
    if (current is ProviderOrdersLoaded) {
      emit(ProviderOrdersLoaded(
        allOrders: event.orders,
        filteredOrders: _applyFilters(event.orders, current.searchQuery),
        searchQuery: current.searchQuery,
        filterDate: current.filterDate,
        filterStatus: current.filterStatus,
      ));
    } else {
      emit(ProviderOrdersLoaded(allOrders: event.orders, filteredOrders: event.orders));
    }
  }

  void _onOrdersError(_OrdersError event, Emitter<ProviderOrdersState> emit) {
    emit(ProviderOrdersError(message: event.error));
  }

  void _onLoadProviderOrders(LoadProviderOrders event, Emitter<ProviderOrdersState> emit) {
    emit(ProviderOrdersLoading());
    _ordersSubscription?.cancel();
    
    // Using a StreamBuilder logic directly inside the UI might be better for real-time lists,
    // but we can also use a StreamSubscription inside BLoC if we want advanced filtering.
    // For now, we will just stream all and apply local filters.
    _ordersSubscription = _bookingsRepository
        .streamUserRequests(event.providerId, isProvider: true)
        .listen((orders) {
      add(_OrdersUpdated(orders));
    }, onError: (error, stackTrace) {
      // Print the full error and stacktrace to the terminal
      debugPrint('ProviderOrdersBloc stream error: $error');
      debugPrint('$stackTrace');
      
      // Emit a generic user-friendly message to the state
      add(_OrdersError('Oops, something went wrong while loading orders.\nPlease try again later.'));
    });
  }

  void _onFilterOrders(FilterOrders event, Emitter<ProviderOrdersState> emit) {
    if (state is ProviderOrdersLoaded) {
      final currentState = state as ProviderOrdersLoaded;
      
      final filtered = _applyFilters(currentState.allOrders, event.searchQuery);

      // Built directly (not via copyWith) so clearing the query really clears it.
      emit(ProviderOrdersLoaded(
        allOrders: currentState.allOrders,
        filteredOrders: filtered,
        searchQuery: event.searchQuery,
        filterDate: event.filterDate,
        filterStatus: event.filterStatus,
      ));
    }
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}

class _OrdersUpdated extends ProviderOrdersEvent {
  final List<ServiceRequestModel> orders;
  const _OrdersUpdated(this.orders);
  @override
  List<Object?> get props => [orders];
}

class _OrdersError extends ProviderOrdersEvent {
  final String error;
  const _OrdersError(this.error);
  @override
  List<Object?> get props => [error];
}
