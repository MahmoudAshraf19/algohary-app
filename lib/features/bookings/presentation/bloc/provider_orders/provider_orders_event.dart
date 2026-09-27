import 'package:equatable/equatable.dart';

abstract class ProviderOrdersEvent extends Equatable {
  const ProviderOrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadProviderOrders extends ProviderOrdersEvent {
  final String providerId;

  const LoadProviderOrders({required this.providerId});

  @override
  List<Object?> get props => [providerId];
}

class FilterOrders extends ProviderOrdersEvent {
  final String? searchQuery;
  final String? filterDate; // e.g., 'Today', 'Yesterday', 'Specific Date'
  final String? filterStatus; // e.g., 'PENDING', 'COMPLETED'
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterOrders({
    this.searchQuery,
    this.filterDate,
    this.filterStatus,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [searchQuery, filterDate, filterStatus, startDate, endDate];
}
