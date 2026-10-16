import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../dashboard/presentation/services/provider_location_tracker.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required this._authRepository})
      : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<SignUpSubmitted>(_onSignUpSubmitted);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ToggleOnlineStatus>(_onToggleOnlineStatus);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        if (user.userType == 'provider' && user.isOnline) {
          ProviderLocationTracker().startTracking(user.id);
        }
        emit(AuthSuccess(user: user));
      } else {
        emit(AuthInitial()); // User not logged in
      }
    } catch (_) {
      emit(AuthInitial());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.loginWithEmailAndPassword(
        email: event.email,
        password: event.password,
        isProvider: event.isProvider,
      );
      if (user.userType == 'provider' && user.isOnline) {
        ProviderLocationTracker().startTracking(user.id);
      }
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthFailure(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUpWithEmailAndPassword(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        password: event.password,
        profileImage: event.profileImage as XFile?,
      );
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthFailure(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await ProviderLocationTracker().stopTracking(updateStatus: true);
    } catch (_) {
      // Never let a tracker failure prevent the user from signing out.
    }
    try {
      await _authRepository.logout();
    } finally {
      // Always leave the authenticated area, even if remote cleanup failed.
      emit(AuthInitial());
    }
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final previousState = state;
    emit(AuthLoading());
    try {
      final user = await _authRepository.updateProfile(
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
        profileImage: event.profileImage,
        categoryId: event.categoryId,
        services: event.services,
        governorateId: event.governorateId,
        cities: event.cities,
        about: event.about,
      );
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthFailure(message: e.toString().replaceAll('Exception: ', '')));
      // A failed profile update must not log the user out of the UI: every
      // screen that reads the user expects an AuthSuccess state. Screens that
      // react to the update result only listen to AuthLoading -> X transitions.
      if (previousState is AuthSuccess) {
        emit(previousState);
      }
    }
  }

  Future<void> _onToggleOnlineStatus(
    ToggleOnlineStatus event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is AuthSuccess) {
      try {
        await _authRepository.updateOnlineStatus(event.isOnline);
        // The user may have logged out (or the state changed) while the request
        // was in flight; never resurrect an authenticated state after that.
        if (state is! AuthSuccess) return;
        if (currentState.user.userType == 'provider') {
          if (event.isOnline) {
            ProviderLocationTracker().startTracking(currentState.user.id);
          } else {
            ProviderLocationTracker().stopTracking(updateStatus: false);
          }
        }
        // Create a new UserModel with updated isOnline status
        final updatedUser = currentState.user.copyWith(
          isOnline: event.isOnline,
          updatedAt: DateTime.now(),
        );
        emit(AuthSuccess(user: updatedUser));
      } catch (e) {
        // Fallback to the latest authenticated state if the request failed.
        if (state is AuthSuccess) emit(state);
      }
    }
  }
}
