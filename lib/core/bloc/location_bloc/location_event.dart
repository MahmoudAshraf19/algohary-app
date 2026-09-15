import 'package:equatable/equatable.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class SetLocation extends LocationEvent {
  final double latitude;
  final double longitude;
  final String address;

  const SetLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}

class ClearLocation extends LocationEvent {}
