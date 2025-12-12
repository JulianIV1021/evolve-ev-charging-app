import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/ocm_station.dart';

/// Persists per-user search history in Firestore.
class SearchHistoryStore {
  SearchHistoryStore._();
  static final SearchHistoryStore instance = SearchHistoryStore._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Load search history for the current user (most recent first).
  Future<List<OcmStation>> fetchAll() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('search_history')
        .orderBy('updatedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => OcmStation.fromStorageJson(d.data()))
        .toList();
  }

  /// Add/replace a station in the user's search history.
  Future<void> add(OcmStation station) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = _firestore
        .collection('users')
        .doc(uid)
        .collection('search_history')
        .doc(station.id.toString());
    await doc.set({
      'stationId': station.id,
      'name': station.name,
      'address': station.address,
      'latitude': station.latitude,
      'longitude': station.longitude,
      'operatorName': station.operatorName,
      'powerKw': station.powerKw,
      'connectorType': station.connectorType,
      'usageCost': station.usageCost,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Clear all search history for the user.
  Future<void> clear() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('search_history')
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
