import 'package:firebase_auth/firebase_auth.dart';

import '../services/signup_service.dart';

abstract class AccountRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;

  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithEmailPassword(String email, String password);
  Future<UserCredential> signUpWithEmailPassword(String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> logOut();
}

class AccountRepositoryImpl implements AccountRepository {
  final SignInService signInService;

  AccountRepositoryImpl(this.signInService);

  @override
  Stream<User?> get authStateChanges => signInService.authStateChanges;

  @override
  User? get currentUser => signInService.currentUser;

  @override
  Future<UserCredential> signInWithGoogle() {
    return signInService.signInWithGoogle();
  }

  @override
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) {
    return signInService.signInWithEmailPassword(email, password);
  }

  @override
  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
  ) {
    return signInService.signUpWithEmailPassword(email, password);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return signInService.sendPasswordResetEmail(email);
  }

  @override
  Future<void> logOut() {
    return signInService.logOut();
  }
}
