import 'package:equatable/equatable.dart';
import '../../../data/models/booking_models.dart';

abstract class CreateRequestEvent extends Equatable {
  const CreateRequestEvent();

  @override
  List<Object?> get props => [];
}

class SelectServiceEvent extends CreateRequestEvent {
  final SelectedServiceModel service;
  const SelectServiceEvent(this.service);

  @override
  List<Object?> get props => [service];
}

class RemoveServiceEvent extends CreateRequestEvent {
  final String serviceId;
  const RemoveServiceEvent(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

class ConfirmContactNoticeEvent extends CreateRequestEvent {
  final bool isConfirmed;
  const ConfirmContactNoticeEvent(this.isConfirmed);

  @override
  List<Object?> get props => [isConfirmed];
}

class SelectAppointmentEvent extends CreateRequestEvent {
  final String date;
  final String time;
  final String timezone;
  const SelectAppointmentEvent({required this.date, required this.time, required this.timezone});

  @override
  List<Object?> get props => [date, time, timezone];
}

class SelectLocationEvent extends CreateRequestEvent {
  final LocationModel location;
  const SelectLocationEvent(this.location);

  @override
  List<Object?> get props => [location];
}

class EnterAgreedPriceEvent extends CreateRequestEvent {
  final double amount;
  final String currency;
  const EnterAgreedPriceEvent({required this.amount, this.currency = 'EGP'});

  @override
  List<Object?> get props => [amount, currency];
}

class SubmitRequestEvent extends CreateRequestEvent {
  final String userId;
  final String providerId;
  const SubmitRequestEvent({required this.userId, required this.providerId});

  @override
  List<Object?> get props => [userId, providerId];
}
