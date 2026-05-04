import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ConnectorType { type2, chademo, ccs2, j1772, other }

enum ChargerType { ac, dc }

enum ChargerStatus { available, busy, offline, faulted }

extension ConnectorTypeX on ConnectorType {
  String get displayName => switch (this) {
        ConnectorType.type2 => 'Type 2',
        ConnectorType.chademo => 'CHAdeMO',
        ConnectorType.ccs2 => 'CCS 2',
        ConnectorType.j1772 => 'J1772',
        ConnectorType.other => 'Other',
      };
}

extension ChargerTypeX on ChargerType {
  String get displayName => this == ChargerType.ac ? 'AC' : 'DC';
}

class ChargerModel extends Equatable {
  const ChargerModel({
    required this.id,
    required this.stationId,
    required this.connectorType,
    required this.chargerType,
    required this.powerKw,
    required this.status,
    required this.pricePerKwh,
    this.idleFeePerMin,
    this.enabled = true,
    this.currentSessionId,
  });

  final String id;
  final String stationId;
  final ConnectorType connectorType;
  final ChargerType chargerType;
  final double powerKw;
  final ChargerStatus status;
  final double pricePerKwh;
  final double? idleFeePerMin;
  final bool enabled;
  final String? currentSessionId;

  bool get isAvailable =>
      enabled && status == ChargerStatus.available && (currentSessionId?.isEmpty ?? true);

  factory ChargerModel.fromFirestore(
    String stationId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return ChargerModel(
      id: doc.id,
      stationId: stationId,
      connectorType: _parseConnector(d['connectorType']),
      chargerType: _parseChargerType(d['chargerType']),
      powerKw: (d['powerKw'] ?? 7).toDouble(),
      status: _parseStatus(d['status']),
      pricePerKwh: (d['pricePerKwh'] ?? 15).toDouble(),
      idleFeePerMin: d['idleFeePerMin'] != null
          ? (d['idleFeePerMin'] as num).toDouble()
          : null,
      enabled: (d['enabled'] ?? true) == true,
      currentSessionId: d['currentSessionId'] as String?,
    );
  }

  static ConnectorType _parseConnector(dynamic v) => switch (v) {
        'type2' => ConnectorType.type2,
        'chademo' => ConnectorType.chademo,
        'ccs2' => ConnectorType.ccs2,
        'j1772' => ConnectorType.j1772,
        _ => ConnectorType.other,
      };

  static ChargerType _parseChargerType(dynamic v) =>
      (v as String?)?.toUpperCase() == 'DC' ? ChargerType.dc : ChargerType.ac;

  static ChargerStatus _parseStatus(dynamic v) {
    if (v == null) return ChargerStatus.offline;
    final s = v.toString().toLowerCase().trim();
    return switch (s) {
      'available' || 'active' || 'online' || 'open' || 'enabled' || 'ready' || 'idle' =>
        ChargerStatus.available,
      'busy' || 'occupied' || 'charging' || 'in_use' || 'inuse' || 'in use' =>
        ChargerStatus.busy,
      'faulted' || 'fault' || 'error' || 'faulting' => ChargerStatus.faulted,
      _ => ChargerStatus.offline,
    };
  }

  @override
  List<Object?> get props =>
      [id, stationId, status, enabled, currentSessionId];
}
