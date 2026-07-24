import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final result = await checkAuth();
    if (result.user != null) {
      emit(AuthAuthenticated());
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await signInGoogle();
    if (result.user != null) {
      emit(AuthAuthenticated());
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
      emit(AuthAuthenticated());
    } else {
      emit(AuthFailure(message: result.error ?? 'Invalid email or password'));
    }
  }

  Future<void> _onEmailSignUp(
    AuthEmailSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await signUpEmail(
      event.email,
      event.password,
      event.name,
    );
    if (result.user != null) {
      emit(AuthAuthenticated());
    } else {
      emit(AuthFailure(message: result.error ?? 'Sign-up failed'));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await signOut();
    emit(AuthUnauthenticated());
  }
}