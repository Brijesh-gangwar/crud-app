import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthBloc(this._auth, this._googleSignIn) : super(AuthInitial()) {
    on<AuthCheckRequested>((event, emit) {
      final user = _auth.currentUser;
      if (user != null) {
        emit(Authenticated(user.uid));
      } else {
        emit(AuthInitial());
      }
    });

    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
        emit(Authenticated(userCredential.user!.uid));
      } catch (e) {
        emit(AuthFailure("Login failed: ${e.toString()}"));
      }
    });

    on<AuthRegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
        emit(Authenticated(userCredential.user!.uid));
      } catch (e) {
        emit(AuthFailure("Registration failed: ${e.toString()}"));
      }
    });

    on<GoogleSignInRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          emit(AuthFailure("Google Sign-In aborted"));
          return;
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        emit(Authenticated(userCredential.user!.uid));
      } catch (e) {
        emit(AuthFailure("Google Sign-In failed: ${e.toString()}"));
      }
    });

    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _auth.signOut();
        await _googleSignIn.signOut();
        emit(AuthInitial());
      } catch (e) {
        emit(AuthFailure("Logout failed: ${e.toString()}"));
      }
    });
  }
}
