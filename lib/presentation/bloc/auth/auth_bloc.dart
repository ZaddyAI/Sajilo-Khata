import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../domain/repositories/i_auth_repository.dart';
import '../../../../domain/usecases/auth/check_auth.dart';
import '../../../../domain/usecases/auth/sign_in_email.dart';
import '../../../../domain/usecases/auth/sign_in_google.dart';
import '../../../../domain/usecases/auth/sign_out.dart';
import '../../../../domain/usecases/auth/sign_up_email.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final SignInWithEmail signInEmail;
  final SignUpWithEmail signUpEmail;
  final SignInWithGoogle signInGoogle;
  final CheckAuth checkAuth;
  final SignOut signOut;

  AuthBloc({
    required this.authRepository,
    required this.signInEmail,
    required this.signUpEmail,
    required this.signInGoogle,
    required this.checkAuth,
    required this.signOut,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthGuestLoginRequested>(_onGuestLoginRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthEmailSignInRequested>(_onEmailSignIn);
    on<AuthEmailSignUpRequested>(_onEmailSignUp);
    on<AuthSignOutRequested>(_onSignOut);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool('isGuestMode') ?? false;

      // Check current user with a short timeout to prevent startup hangs when offline
      final result = await checkAuth().timeout(
        const Duration(seconds: 2),
        onTimeout: () => (user: null, error: 'Auth check timeout'),
      );

      if (result.user != null) {
        await prefs.setBool('isGuestMode', false);
        emit(const AuthAuthenticated(isGuest: false));
        return;
      }

      // Check network connectivity
      bool isOffline = false;
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        isOffline =
            connectivityResult.isEmpty ||
            connectivityResult.every((r) => r == ConnectivityResult.none);
      } catch (_) {}

      // If offline or previously selected guest mode, enter Guest Mode
      if (isOffline || isGuest) {
        await prefs.setBool('isGuestMode', true);
        emit(const AuthAuthenticated(isGuest: true));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool('isGuestMode') ?? false;
      if (isGuest) {
        emit(const AuthAuthenticated(isGuest: true));
      } else {
        emit(AuthUnauthenticated());
      }
    }
  }

  Future<void> _onGuestLoginRequested(
    AuthGuestLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuestMode', true);
    emit(const AuthAuthenticated(isGuest: true));
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await signInGoogle();
    if (result.user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuestMode', false);
      emit(const AuthAuthenticated(isGuest: false));
    } else {
      emit(AuthFailure(message: result.error ?? 'Google sign-in failed'));
    }
  }

  Future<void> _onEmailSignIn(
    AuthEmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await signInEmail(event.email, event.password);
    if (result.user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuestMode', false);
      emit(const AuthAuthenticated(isGuest: false));
    } else {
      emit(AuthFailure(message: result.error ?? 'Invalid email or password'));
    }
  }

  Future<void> _onEmailSignUp(
    AuthEmailSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await signUpEmail(event.email, event.password, event.name);
    if (result.user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuestMode', false);
      emit(const AuthAuthenticated(isGuest: false));
    } else {
      emit(AuthFailure(message: result.error ?? 'Sign-up failed'));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuestMode', false);
    await signOut();
    emit(AuthUnauthenticated());
  }
}
