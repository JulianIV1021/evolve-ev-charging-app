import 'package:cloud_firestore/cloud_firestore.dart';

class ChargingSession {
  final String id;
  final String stationId;
  final String stationName;
  final double latitude;
  final double longitude;
  final bool isFree;
  final String? connectorType;
  final double? powerKw;
  final Timestamp? startedAt;
  final Timestamp? endedAt;
  final String status; // active | completed
  final int? startBatteryPercent;
  final int? endBatteryPercent;
  final int? durationSeconds;
  final double? energyKWhEstimate;

  ChargingSession({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.latitude,
    required this.longitude,
    required this.isFree,
    this.connectorType,
    this.powerKw,
    this.startedAt,
    this.endedAt,
    this.status = 'active',
    this.startBatteryPercent,
    this.endBatteryPercent,
    this.durationSeconds,
    this.energyKWhEstimate,
  });

  factory ChargingSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChargingSession(
      id: doc.id,
      stationId: data['stationId']?.toString() ?? '',
      stationName: data['stationName']?.toString() ?? 'Station',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      isFree: data['isFree'] == true,
      connectorType: data['connectorType']?.toString(),
      powerKw: (data['powerKw'] as num?)?.toDouble(),
      startedAt: data['startedAt'] as Timestamp?,
      endedAt: data['endedAt'] as Timestamp?,
      status: data['status']?.toString() ?? 'active',
      startBatteryPercent: data['startBatteryPercent'] as int?,
      endBatteryPercent: data['endBatteryPercent'] as int?,
      durationSeconds: data['durationSeconds'] as int?,
      energyKWhEstimate:
          (data['energyKWhEstimate'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stationId': stationId,
      'stationName': stationName,
      'latitude': latitude,
      'longitude': longitude,
      'isFree': isFree,
      'connectorType': connectorType,
      'powerKw': powerKw,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'status': status,
      'startBatteryPercent': startBatteryPercent,
      'endBatteryPercent': endBatteryPercent,
      'durationSeconds': durationSeconds,
      'energyKWhEstimate': energyKWhEstimate,
    };
  }
}
