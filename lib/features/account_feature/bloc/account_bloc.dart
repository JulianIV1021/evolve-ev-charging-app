import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/utils/logger.dart';
import '../repository/account_repository.dart';
import 'account_event.dart';
import 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AccountRepository _accountRepository;

  AccountBloc(this._accountRepository) : super(const AccountState()) {
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignInWithEmailPasswordEvent>(_onSignInWithEmailPassword);
    on<SignUpWithEmailPasswordEvent>(_onSignUpWithEmailPassword);
    on<SendPasswordResetEvent>(_onSendPasswordReset);
    on<SignOutEvent>(_onSignOut);
    on<ClearErrorEvent>(_onClearError);
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final cred = await _accountRepository.signInWithGoogle();
      await _upsertUser(cred.user);
      emit(state.copyWith(
        status: AccountStatus.authenticated,
        isLoading: false,
      ));
    } on FirebaseAuthException catch (e) {
      log.severe('Google sign-in error: ${e.message}');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        status: AccountStatus.error,
      ));
    } catch (e) {
      log.severe('Google sign-in error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: _parseFirebaseError(e),
        status: AccountStatus.error,
      ));
    }
  }

  Future<void> _onSignInWithEmailPassword(
    SignInWithEmailPasswordEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final cred = await _accountRepository.signInWithEmailPassword(
        event.email,
        event.password,
      );
      await _upsertUser(cred.user);
      emit(state.copyWith(
        status: AccountStatus.authenticated,
        isLoading: false,
      ));
    } catch (e) {
      log.severe('Email sign-in error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: _parseFirebaseError(e),
        status: AccountStatus.error,
      ));
    }
  }

  Future<void> _onSignUpWithEmailPassword(
    SignUpWithEmailPasswordEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final cred = await _accountRepository.signUpWithEmailPassword(
        event.email,
        event.password,
      );
      await _upsertUser(cred.user);
      emit(state.copyWith(
        status: AccountStatus.authenticated,
        isLoading: false,
      ));
    } catch (e) {
      log.severe('Email sign-up error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: _parseFirebaseError(e),
        status: AccountStatus.error,
      ));
    }
  }

  Future<void> _onSendPasswordReset(
    SendPasswordResetEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));
    try {
      await _accountRepository.sendPasswordResetEmail(event.email);
      emit(state.copyWith(
        isLoading: false,
        successMessage: 'Password reset email sent. Check your inbox.',
      ));
    } catch (e) {
      log.severe('Password reset error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: _parseFirebaseError(e),
      ));
    }
  }

  Future<void> _onSignOut(
    SignOutEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _accountRepository.logOut();
      emit(const AccountState(status: AccountStatus.unauthenticated));
    } catch (e) {
      log.severe('Sign out error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: _parseFirebaseError(e),
      ));
    }
  }

  void _onClearError(ClearErrorEvent event, Emitter<AccountState> emit) {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }

  Future<void> _upsertUser(User? user) async {
    if (user == null) return;
    try {
      final providerIds = user.providerData.map((p) => p.providerId).toList();
      final createdAt = user.metadata.creationTime;
      final lastSignIn = user.metadata.lastSignInTime;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'emailVerified': user.emailVerified,
        'providerIds': providerIds,
        // Preserve original creation time when present.
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'lastSignInTime': lastSignIn,
        // Always update last login.
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      log.severe('User upsert failed: $e');
    }
  }

  String _parseFirebaseError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        case 'invalid-credential':
          return 'Invalid email or password.';
        default:
          return e.message ?? 'An error occurred. Please try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
