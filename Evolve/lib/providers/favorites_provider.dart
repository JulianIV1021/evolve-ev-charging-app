import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams the current user's favorite station IDs from Firestore.
final favoritesProvider = StreamProvider<List<String>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => List<String>.from(doc.data()?['favorites'] ?? []));
});

/// Returns a function that toggles a station in/out of favorites.
/// Usage: `ref.read(toggleFavoriteProvider)('stationId')`
final toggleFavoriteProvider = Provider<Future<void> Function(String)>((ref) {
  return (String stationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(uid);
    final snap = await docRef.get();
    final current =
        List<String>.from(snap.data()?['favorites'] ?? []);
    if (current.contains(stationId)) {
      current.remove(stationId);
    } else {
      current.add(stationId);
    }
    await docRef.update({'favorites': current});
  };
});
