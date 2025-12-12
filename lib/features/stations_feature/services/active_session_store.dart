import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/charging_session.dart';

/// Lightweight helper to fetch the currently active session for the signed-in user.
class ActiveSessionStore {
  ActiveSessionStore._();
  static final ActiveSessionStore instance = ActiveSessionStore._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<ChargingSession?> fetchActive() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ChargingSession.fromDoc(snap.docs.first);
  }
}
