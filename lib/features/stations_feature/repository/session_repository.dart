import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/charging_session.dart';
import '../models/ocm_station.dart';

abstract class SessionRepository {
  Stream<List<ChargingSession>> sessionsStream();
  Future<String> startSession(OcmStation station);
  Future<void> endSession(String sessionId);
}

class SessionRepositoryImpl implements SessionRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final Battery battery;

  SessionRepositoryImpl({
    required this.auth,
    required this.firestore,
    Battery? battery,
  }) : battery = battery ?? Battery();

  String _uid() {
    final user = auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-signed-in',
        message: 'User must be signed in to track sessions.',
      );
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _col() =>
      firestore.collection('users').doc(_uid()).collection('sessions');

  @override
  Stream<List<ChargingSession>> sessionsStream() {
    // React to auth changes so the list refreshes after sign‑in/out without
    // needing a manual app restart.
    return auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(<ChargingSession>[]);
      }
      return firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .orderBy('startedAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map(ChargingSession.fromDoc).toList());
    });
  }

  @override
  Future<String> startSession(OcmStation station) async {
    final uid = _uid();
    final startBattery = await battery.batteryLevel;
    final payload = {
      'stationId': station.id.toString(),
      'stationName': station.name,
      'latitude': station.latitude,
      'longitude': station.longitude,
      'isFree': true, // OCM free-flow assumption; adjust if needed
      'connectorType': station.connectorType,
      'powerKw': station.powerKw,
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
      'startBatteryPercent': startBattery,
      'userId': uid,
    };
    final doc = await _col().add(payload);
    return doc.id;
  }

  @override
  Future<void> endSession(String sessionId) async {
    final ref = _col().doc(sessionId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final startedAt = data['startedAt'] as Timestamp?;
    final startBattery = data['startBatteryPercent'] as int?;
    final endBattery = await battery.batteryLevel;

    int? durationSeconds;
    if (startedAt != null) {
      durationSeconds =
          DateTime.now().difference(startedAt.toDate()).inSeconds;
    }

    double? energyEstimate;
    if (startBattery != null && endBattery != null) {
      final delta = (endBattery - startBattery).clamp(0, 100);
      // crude phone battery capacity estimate; adjust for your mock
      const phoneBatteryKWh = 0.015;
      energyEstimate = (delta / 100.0) * phoneBatteryKWh;
    }

    await ref.update({
      'status': 'completed',
      'endedAt': FieldValue.serverTimestamp(),
      'endBatteryPercent': endBattery,
      'durationSeconds': durationSeconds,
      'energyKWhEstimate': energyEstimate,
    });
  }
}
