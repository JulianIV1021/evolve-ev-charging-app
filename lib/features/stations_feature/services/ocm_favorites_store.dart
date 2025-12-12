import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/ocm_station.dart';

/// Favorites store with Firestore persistence per user.
class OcmFavoritesStore {
  OcmFavoritesStore._();

  static final OcmFavoritesStore instance = OcmFavoritesStore._();

  String? _userId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _favSub;

  /// Map of station id -> station details.
  final ValueNotifier<Map<int, OcmStation>> favorites =
      ValueNotifier<Map<int, OcmStation>>({});

  bool isFavorite(int id) => favorites.value.containsKey(id);

  /// Initialize for the given user. Pass null to clear when signed out.
  Future<void> loadForUser(String? userId) async {
    // Cancel old subscription.
    await _favSub?.cancel();
    _favSub = null;
    _userId = userId;
    if (userId == null) {
      favorites.value = {};
      return;
    }

    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites');

    _favSub = col.snapshots().listen((snapshot) {
      final map = <int, OcmStation>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        try {
          final station = OcmStation.fromStorageJson(data);
          map[station.id] = station;
        } catch (_) {
          // Ignore malformed entries.
        }
      }
      favorites.value = map;
    });
  }

  Future<void> toggle(OcmStation station) async {
    if (_userId == null) return;
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .doc(station.id.toString());

    if (favorites.value.containsKey(station.id)) {
      await col.delete();
    } else {
      await col.set(station.toStorageJson());
    }
  }
}
