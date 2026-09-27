import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
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
    await _authRepository.logout();
    emit(AuthInitial());
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.updateProfile(
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
        profileImage: event.profileImage,
      );
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthFailure(message: e.toString().replaceAll('Exception: ', '')));
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
        // Create a new UserModel with updated isOnline status
        final updatedUser = UserModel(
          id: currentState.user.id,
          firstName: currentState.user.firstName,
          lastName: currentState.user.lastName,
          email: currentState.user.email,
          phone: currentState.user.phone,
          imageUrl: currentState.user.imageUrl,
          userType: currentState.user.userType,
          isActive: currentState.user.isActive,
          isBlocked: currentState.user.isBlocked,
          isOnline: event.isOnline,
          fcmToken: currentState.user.fcmToken,
          subscription: currentState.user.subscription,
          createdAt: currentState.user.createdAt,
          updatedAt: DateTime.now(),
          lastLoginAt: currentState.user.lastLoginAt,
          categoryId: currentState.user.categoryId,
          services: currentState.user.services,
          governorateId: currentState.user.governorateId,
          cities: currentState.user.cities,
          about: currentState.user.about,
        );
        emit(AuthSuccess(user: updatedUser));
      } catch (e) {
        // Fallback to current state if failed, optionally could show a toast
        emit(currentState);
      }
    }
  }
}
