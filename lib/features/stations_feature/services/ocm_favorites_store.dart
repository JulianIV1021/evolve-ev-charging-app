import 'package:flutter/foundation.dart';

import '../models/ocm_station.dart';

/// Simple in-memory favorites store for OCM stations.
class OcmFavoritesStore {
  OcmFavoritesStore._();

  static final OcmFavoritesStore instance = OcmFavoritesStore._();

  /// Map of station id -> station details.
  final ValueNotifier<Map<int, OcmStation>> favorites =
      ValueNotifier<Map<int, OcmStation>>({});

  bool isFavorite(int id) => favorites.value.containsKey(id);

  void toggle(OcmStation station) {
    final next = Map<int, OcmStation>.from(favorites.value);
    if (next.containsKey(station.id)) {
      next.remove(station.id);
    } else {
      next[station.id] = station;
    }
    favorites.value = next;
  }
}
