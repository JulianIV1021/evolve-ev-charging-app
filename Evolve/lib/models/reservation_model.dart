import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ReservationStatus { active, expired, used, cancelled }

class ReservationModel extends Equatable {
  const ReservationModel({
    required this.id,
    required this.stationId,
    required this.chargerId,
    required this.userId,
    required this.expiresAt,
    required this.status,
    this.stationName = '',
  });

  final String id;
  final String stationId;
  final String chargerId;
  final String userId;
  final DateTime expiresAt;
  final ReservationStatus status;
  final String stationName;

  bool get isActive => status == ReservationStatus.active;

  Duration get timeRemaining {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory ReservationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return ReservationModel(
      id: doc.id,
      stationId: d['stationId'] as String,
      chargerId: d['chargerId'] as String,
      userId: d['userId'] as String,
      expiresAt: (d['expiresAt'] as Timestamp).toDate(),
      status: _parseStatus(d['status']),
      stationName: d['stationName'] as String? ?? '',
    );
  }

  static ReservationStatus _parseStatus(dynamic v) => switch (v) {
        'active' => ReservationStatus.active,
        'expired' => ReservationStatus.expired,
        'used' => ReservationStatus.used,
        _ => ReservationStatus.cancelled,
      };

  @override
  List<Object?> get props => [id, status, expiresAt];
}
