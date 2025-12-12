import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

abstract class SignInService {
  Stream<User?> get authStateChanges;
  User? get currentUser;

  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithEmailPassword(String email, String password);
  Future<UserCredential> signUpWithEmailPassword(String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> logOut();
}

class SignInServiceImpl implements SignInService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  SignInServiceImpl(this._firebaseAuth)
      : _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'login_hint': 'user@example.com'});
      return await _firebaseAuth.signInWithPopup(googleProvider);
    } else {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'sign-in-cancelled',
          message: 'Google sign-in was cancelled by user',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    }
  }

  @override
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
  ) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> logOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
