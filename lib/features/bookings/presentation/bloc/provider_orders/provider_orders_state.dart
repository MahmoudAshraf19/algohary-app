import 'package:equatable/equatable.dart';
import '../../../data/models/booking_models.dart';

abstract class ProviderOrdersState extends Equatable {
  const ProviderOrdersState();

  @override
  List<Object?> get props => [];
}

class ProviderOrdersInitial extends ProviderOrdersState {}

class ProviderOrdersLoading extends ProviderOrdersState {}

class ProviderOrdersLoaded extends ProviderOrdersState {
  final List<ServiceRequestModel> allOrders;
  final List<ServiceRequestModel> filteredOrders;
  final String? searchQuery;
  final String? filterDate;
  final String? filterStatus;

  const ProviderOrdersLoaded({
    required this.allOrders,
    required this.filteredOrders,
    this.searchQuery,
    this.filterDate,
    this.filterStatus,
  });

  ProviderOrdersLoaded copyWith({
    List<ServiceRequestModel>? allOrders,
    List<ServiceRequestModel>? filteredOrders,
    String? searchQuery,
    String? filterDate,
    String? filterStatus,
  }) {
    return ProviderOrdersLoaded(
      allOrders: allOrders ?? this.allOrders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      searchQuery: searchQuery ?? this.searchQuery,
      filterDate: filterDate ?? this.filterDate,
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }

  @override
  List<Object?> get props => [allOrders, filteredOrders, searchQuery, filterDate, filterStatus];
}

class ProviderOrdersError extends ProviderOrdersState {
  final String message;

  const ProviderOrdersError({required this.message});

  @override
  List<Object?> get props => [message];
}
