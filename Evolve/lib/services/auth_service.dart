import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around FirebaseAuth and Firestore user-profile logic.
/// Extracted from the original login_screen.dart — no behavior changes.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// Stream of the currently signed-in [User], or null when signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The synchronously available current user (may be null on cold start
  /// before Firebase finishes restoring the session).
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (cred.user != null) await _ensureUserProfile(cred.user!);
    return cred;
  }

  /// Create a new account with an optional display name.
  /// Creates the Firestore user document with approved: false.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (cred.user != null) {
      await _ensureUserProfile(cred.user!, displayName: displayName);
    }
    return cred;
  }

  /// Send a password-reset email to [email].
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign the current user out.
  Future<void> signOut() => _auth.signOut();

  // ---------------------------------------------------------------------------

  /// Ensures a Firestore user document exists for [user].
  /// Preserves any existing fields — only creates if missing.
  Future<void> _ensureUserProfile(User user, {String? displayName}) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'email': user.email ?? '',
        'name': displayName ?? '',
        'role': 'user',
        'approved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
