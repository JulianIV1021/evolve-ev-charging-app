import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/charger_model.dart';
import '../models/station_model.dart';

/// Firestore wrapper for the stations collection.
/// Chargers are loaded on-demand per station to avoid N+1 real-time listeners
/// on the map screen. The detail sheet calls [watchChargersForStation] for
/// live per-station charger updates.
class StationRepository {
  StationRepository._();
  static final StationRepository instance = StationRepository._();

  final _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Stations
  // ---------------------------------------------------------------------------

  /// Real-time stream of all stations (without chargers).
  /// Charger counts are not pre-loaded here for performance.
  Stream<List<StationModel>> watchAllStations() {
    return _db.collection('stations').snapshots().map((snap) =>
        snap.docs.map(StationModel.fromFirestore).toList());
  }

  /// One-shot fetch of a single station document.
  Future<StationModel> getStation(String stationId) async {
    final doc = await _db.collection('stations').doc(stationId).get();
    return StationModel.fromFirestore(doc);
  }

  // ---------------------------------------------------------------------------
  // Chargers
  // ---------------------------------------------------------------------------

  /// Real-time stream of chargers for a given station.
  Stream<List<ChargerModel>> watchChargersForStation(String stationId) {
    return _db
        .collection('stations')
        .doc(stationId)
        .collection('chargers')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChargerModel.fromFirestore(stationId, doc))
            .toList());
  }

  /// One-shot fetch of all chargers for a station.
  Future<List<ChargerModel>> getChargers(String stationId) async {
    final snap = await _db
        .collection('stations')
        .doc(stationId)
        .collection('chargers')
        .get();
    return snap.docs.map((d) => ChargerModel.fromFirestore(stationId, d)).toList();
  }
}
