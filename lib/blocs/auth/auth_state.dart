abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final String userId;
  Authenticated(this.userId);
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}
