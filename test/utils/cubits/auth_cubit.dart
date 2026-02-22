import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

/// A cubit managing authentication state.
final class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState.guest());

  void logIn(String username) => emit(AuthState.authenticated(username));

  void logOut() => emit(const AuthState.guest());

  void updateProfile(String username) {
    if (state.isAuthenticated) {
      emit(AuthState.authenticated(username));
    }
  }
}

@immutable
final class AuthState {
  const AuthState.guest()
      : username = null,
        isAuthenticated = false;

  const AuthState.authenticated(String user)
      : username = user,
        isAuthenticated = true;

  final String? username;
  final bool isAuthenticated;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          username == other.username &&
          isAuthenticated == other.isAuthenticated;

  @override
  int get hashCode => Object.hash(username, isAuthenticated);
}
