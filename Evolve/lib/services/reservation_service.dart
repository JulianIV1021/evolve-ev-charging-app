import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/reservation_model.dart';
import '../utils/app_logger.dart';

/// Firestore-backed reservation service.
/// Creates holds on charger slots with client-side expiry timers.
/// ASSUMPTION A7: A Cloud Function also handles server-side expiry for reliability.
class ReservationService {
  ReservationService._();
  static final ReservationService instance = ReservationService._();

  final _db = FirebaseFirestore.instance;

  Timer? _expiryTimer;

  // ---------------------------------------------------------------------------

  Future<ReservationModel> createReservation({
    required String stationId,
    required String chargerId,
    required int holdDurationMinutes,
    String? stationName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final expiresAt =
        DateTime.now().add(Duration(minutes: holdDurationMinutes));

    final ref = _db.collection('reservations').doc();
    await ref.set({
      'stationId': stationId,
      'chargerId': chargerId,
      'userId': user.uid,
      'stationName': stationName ?? '',
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    AppLogger.instance.info('reservation_created', {
      'station_id': stationId,
      'charger_id': chargerId,
      'expires_at': expiresAt.toIso8601String(),
    });

    final reservation = ReservationModel(
      id: ref.id,
      stationId: stationId,
      chargerId: chargerId,
      userId: user.uid,
      expiresAt: expiresAt,
      status: ReservationStatus.active,
      stationName: stationName ?? '',
    );

    // Client-side expiry timer (server-side Cloud Function handles authoritative expiry)
    _expiryTimer?.cancel();
    _expiryTimer = Timer(Duration(minutes: holdDurationMinutes), () {
      _markExpired(ref.id);
    });

    return reservation;
  }

  Future<void> cancelReservation(String reservationId) async {
    await _db
        .collection('reservations')
        .doc(reservationId)
        .update({'status': 'cancelled'});
    _expiryTimer?.cancel();

    AppLogger.instance.info('reservation_cancelled', {
      'reservation_id': reservationId,
    });
  }

  Stream<ReservationModel> watchReservation(String reservationId) {
    return _db
        .collection('reservations')
        .doc(reservationId)
        .snapshots()
        .where((snap) => snap.exists)
        .map(ReservationModel.fromFirestore);
  }

  Future<void> _markExpired(String reservationId) async {
    try {
      await _db
          .collection('reservations')
          .doc(reservationId)
          .update({'status': 'expired'});
      AppLogger.instance.warning('reservation_expired', {
        'reservation_id': reservationId,
      });
    } catch (_) {}
  }
}
