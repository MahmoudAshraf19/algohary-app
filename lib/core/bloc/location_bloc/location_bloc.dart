import 'package:flutter_bloc/flutter_bloc.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc() : super(LocationInitial()) {
    on<SetLocation>((event, emit) {
      emit(LocationSelected(
        latitude: event.latitude,
        longitude: event.longitude,
        address: event.address,
      ));
    });

    on<ClearLocation>((event, emit) {
      emit(LocationInitial());
    });
  }
}
