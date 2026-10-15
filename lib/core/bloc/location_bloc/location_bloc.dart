import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  static const _prefAddressKey = 'selected_location_address';
  static const _prefLatKey = 'selected_location_lat';
  static const _prefLngKey = 'selected_location_lng';

  LocationBloc() : super(LocationInitial()) {
    on<LoadSavedLocation>((event, emit) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final address = prefs.getString(_prefAddressKey);
        final lat = prefs.getDouble(_prefLatKey) ?? 30.0444;
        final lng = prefs.getDouble(_prefLngKey) ?? 31.2357;

        if (address != null && address.isNotEmpty) {
          emit(LocationSelected(latitude: lat, longitude: lng, address: address));
        }
      } catch (_) {}
    });

    on<SetLocation>((event, emit) async {
      emit(LocationSelected(
        latitude: event.latitude,
        longitude: event.longitude,
        address: event.address,
      ));

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefAddressKey, event.address);
        await prefs.setDouble(_prefLatKey, event.latitude);
        await prefs.setDouble(_prefLngKey, event.longitude);
      } catch (_) {}
    });

    on<ClearLocation>((event, emit) async {
      emit(LocationInitial());
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_prefAddressKey);
        await prefs.remove(_prefLatKey);
        await prefs.remove(_prefLngKey);
      } catch (_) {}
    });
  }
}
