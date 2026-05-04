import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles Google Sign-In and syncs the user profile to Firestore.
///
/// Firebase Console setup required:
///   - Authentication → Sign-in method → Google → Enable
///   - Android: add SHA-1 fingerprint from `./gradlew signingReport`
///   - iOS: add REVERSED_CLIENT_ID from GoogleService-Info.plist as a
///     URL scheme in ios/Runner/Info.plist
class GoogleAuthService {
  GoogleAuthService._();

  static Future<UserCredential?> signIn() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // User cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result =
        await FirebaseAuth.instance.signInWithCredential(credential);

    // Auto-create Firestore user doc on first sign-in
    final uid = result.user!.uid;
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(uid);
    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        'name': result.user!.displayName ?? '',
        'email': result.user!.email ?? '',
        'role': 'user',
        'approved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return result;
  }
}
