import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignUpSubmitted extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final dynamic profileImage; // dynamic or XFile? (we can avoid importing image_picker here by using dynamic, but let's use dynamic or Object for Clean Arch)

  const SignUpSubmitted({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.profileImage,
  });

  @override
  List<Object?> get props => [firstName, lastName, email, password, profileImage];
}

class LogoutRequested extends AuthEvent {}

class UpdateProfileRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  final String phone;
  final dynamic profileImage;

  const UpdateProfileRequested({
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.profileImage,
  });

  @override
  List<Object?> get props => [firstName, lastName, phone, profileImage];
}
