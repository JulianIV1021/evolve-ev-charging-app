import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/charger_model.dart';
import '../models/ev_profile_model.dart';
import '../models/filter_model.dart';
import '../models/station_model.dart';
import '../services/station_filter_service.dart';
import '../services/station_repository.dart';

// ---------------------------------------------------------------------------
// Station stream
// ---------------------------------------------------------------------------

final allStationsProvider = StreamProvider<List<StationModel>>((ref) {
  return StationRepository.instance.watchAllStations();
});

final chargersForStationProvider =
    StreamProvider.family<List<ChargerModel>, String>((ref, stationId) {
  return StationRepository.instance.watchChargersForStation(stationId);
});

// ---------------------------------------------------------------------------
// Filter state
// ---------------------------------------------------------------------------

final stationFilterProvider =
    StateProvider<StationFilter>((_) => StationFilter.empty);

// ---------------------------------------------------------------------------
// User location
// ---------------------------------------------------------------------------

final userLocationProvider = FutureProvider<LatLng?>((ref) async {
  try {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return null;

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return LatLng(pos.latitude, pos.longitude);
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// EV Profile
// ---------------------------------------------------------------------------

final evProfileProvider = StreamProvider<EVProfile>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(const EVProfile());

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) {
    final data = snap.data();
    if (data == null || data['evProfile'] == null) return const EVProfile();
    return EVProfile.fromMap(data['evProfile'] as Map<String, dynamic>);
  });
});

// ---------------------------------------------------------------------------
// Stations with distance computed and sorted (depends on allStations + location)
// Separated so that filter/evProfile changes do NOT rerun distance computation.
// ---------------------------------------------------------------------------

final stationsWithDistanceProvider = Provider<List<StationModel>>((ref) {
  final stations = ref.watch(allStationsProvider).valueOrNull ?? [];
  final userLatLng = ref.watch(userLocationProvider).valueOrNull;
  if (userLatLng == null) return stations;
  final withDist = stations.map((s) {
    final distM = Geolocator.distanceBetween(
      userLatLng.latitude,
      userLatLng.longitude,
      s.location.latitude,
      s.location.longitude,
    );
    return s.copyWith(distanceKm: distM / 1000.0);
  }).toList();
  withDist.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return withDist;
});

// ---------------------------------------------------------------------------
// Filtered stations (applies filter predicates; depends on stationsWithDistance)
// evProfile/filter changes only re-run the filter predicate, not distance sort.
// ---------------------------------------------------------------------------

final filteredStationsProvider = Provider<List<StationModel>>((ref) {
  final withDist = ref.watch(stationsWithDistanceProvider);
  final filter = ref.watch(stationFilterProvider);
  final evProfile = ref.watch(evProfileProvider).valueOrNull;
  return StationFilterService.instance.apply(
    stations: withDist,
    filter: filter,
    evProfile: evProfile,
  );
});

// ---------------------------------------------------------------------------
// Selected station
// ---------------------------------------------------------------------------

final selectedStationIdProvider = StateProvider<String?>((_) => null);

// ---------------------------------------------------------------------------
// Map ready — true once GoogleMap.onMapCreated fires in StationsMapScreen
// ---------------------------------------------------------------------------

final mapReadyProvider = StateProvider<bool>((_) => false);

// ---------------------------------------------------------------------------
// Station name resolver (used in ActivityScreen session cards)
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Active charging session (for session recovery after app restart)
// ---------------------------------------------------------------------------

/// Streams the session ID of any in-progress session for the current user.
/// Returns null when no active session exists.
/// Used by HomeScreen to restore navigation if the app was killed mid-charge.
final activeSessionProvider = StreamProvider<String?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('sessions')
      .where('userId', isEqualTo: user.uid)
      .where('status', whereIn: [
        'pending_start',
        'active',
        'charging',
        'complete',
        'idle_fee',
      ])
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isEmpty ? null : snap.docs.first.id);
});

// ---------------------------------------------------------------------------
// Station name resolver (used in ActivityScreen session cards)
// ---------------------------------------------------------------------------

/// Resolves a station's human-readable name from stationId.
/// Checks the in-memory station list first; falls back to a Firestore read.
final stationNameProvider =
    FutureProvider.family<String, String>((ref, stationId) async {
  if (stationId.isEmpty) return 'Charging Session';

  // Fast path: already in memory
  final cached = ref.read(allStationsProvider).valueOrNull;
  if (cached != null) {
    final match = cached.where((s) => s.id == stationId).firstOrNull;
    if (match != null) return match.name;
  }

  // Firestore fallback
  final doc = await FirebaseFirestore.instance
      .collection('stations')
      .doc(stationId)
      .get();
  return doc.data()?['name'] as String? ?? stationId;
});
