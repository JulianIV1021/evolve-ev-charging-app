import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

/// Current Firebase auth user — emits null when signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authStateChanges;
});

/// Firestore approval status for the current user.
/// Returns null while loading, true if approved, false if pending.
final approvalStatusProvider = StreamProvider<bool?>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.valueOrNull;

  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return null;
    return snap.data()?['approved'] == true;
  });
});
