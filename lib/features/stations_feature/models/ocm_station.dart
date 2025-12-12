import 'package:google_maps_flutter/google_maps_flutter.dart';

class OcmConnector {
  final String connectorType;
  final double? powerKw;
  final String? currentType;

  OcmConnector({
    required this.connectorType,
    this.powerKw,
    this.currentType,
  });

  Map<String, dynamic> toJson() => {
        'connectorType': connectorType,
        'powerKw': powerKw,
        'currentType': currentType,
      };

  factory OcmConnector.fromStorageJson(Map<String, dynamic> json) {
    return OcmConnector(
      connectorType: json['connectorType']?.toString() ?? 'Unknown',
      powerKw: (json['powerKw'] as num?)?.toDouble(),
      currentType: json['currentType']?.toString(),
    );
  }
}

class OcmStation {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String status;
  final String operatorName;
  final String usageCost; // raw text from OCM
  final int numberOfPoints;
  final List<OcmConnector> connectors;
  final double? powerKw; // convenience: first connector power
  final String? connectorType; // convenience: first connector type

  OcmStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.status,
    required this.operatorName,
    required this.usageCost,
    required this.numberOfPoints,
    required this.connectors,
    this.powerKw,
    this.connectorType,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  /// Simple “AC 22 kW” style text for the first connector.
  String get powerSummary {
    if (connectors.isEmpty) return 'AC / DC';
    final c = connectors.first;
    final kw = c.powerKw != null ? '${c.powerKw!.toStringAsFixed(0)} kW' : '';
    final current = c.currentType ?? '';
    final pieces = [current, kw].where((p) => p.trim().isNotEmpty).toList();
    return pieces.isEmpty ? 'AC / DC' : pieces.join(' ');
  }

  /// Simple connector label like “Type 2 (Tethered)” or whatever OCM gives.
  String get connectorSummary {
    if (connectors.isEmpty) return 'Connector';
    return connectors.first.connectorType;
  }

  bool get isAvailable =>
      status.toLowerCase().contains('available') ||
      status.toLowerCase().contains('operational');

  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

  Map<String, dynamic> toStorageJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': status,
      'operatorName': operatorName,
      'usageCost': usageCost,
      'numberOfPoints': numberOfPoints,
      'powerKw': powerKw,
      'connectorType': connectorType,
      'connectors': connectors.map((c) => c.toJson()).toList(),
    };
  }

  factory OcmStation.fromStorageJson(Map<String, dynamic> json) {
    final storedConnectors = (json['connectors'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(OcmConnector.fromStorageJson)
        .toList();

    return OcmStation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Charging station',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      address: json['address']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Unknown',
      operatorName: json['operatorName']?.toString() ?? 'Unknown operator',
      usageCost: json['usageCost']?.toString() ?? 'See rates at station',
      numberOfPoints: (json['numberOfPoints'] as num?)?.toInt() ?? 1,
      connectors: storedConnectors,
      powerKw: (json['powerKw'] as num?)?.toDouble(),
      connectorType: json['connectorType']?.toString(),
    );
  }

  factory OcmStation.fromJson(Map<String, dynamic> json) {
    final addr = json['AddressInfo'] as Map<String, dynamic>? ?? {};
    final statusType = json['StatusType'] as Map<String, dynamic>? ?? {};
    final operatorInfo = json['OperatorInfo'] as Map<String, dynamic>? ?? {};

    final connections = (json['Connections'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((c) {
          final connType =
              (c['ConnectionType']?['Title'] ?? 'Unknown').toString();
          final powerKw = (c['PowerKW'] as num?)?.toDouble();
          final current = (c['CurrentType']?['Title'] ?? '').toString();
          return OcmConnector(
            connectorType: connType,
            powerKw: powerKw,
            currentType: current.isEmpty ? null : current,
          );
        })
        .toList();

    final parts = <String>[
      addr['AddressLine1']?.toString() ?? '',
      addr['Town']?.toString() ?? '',
      addr['StateOrProvince']?.toString() ?? '',
      addr['Country']?['ISOCode']?.toString() ??
          addr['Country']?['Title']?.toString() ??
          '',
    ].where((p) => p.trim().isNotEmpty).toList();

    final firstConn = connections.isNotEmpty ? connections.first : null;
    final firstPower = firstConn?.powerKw;
    final firstConnectorType = firstConn?.connectorType;

    return OcmStation(
      id: (json['ID'] as int?) ?? 0,
      name: (addr['Title'] ?? 'Charging station').toString(),
      latitude: (addr['Latitude'] as num).toDouble(),
      longitude: (addr['Longitude'] as num).toDouble(),
      address: parts.join(', '),
      status: (statusType['Title'] ?? 'Unknown').toString(),
      operatorName: (operatorInfo['Title'] ?? 'Unknown operator').toString(),
      usageCost: (json['UsageCost'] ?? 'See rates at station').toString(),
      numberOfPoints: (json['NumberOfPoints'] as int?) ?? 1,
      connectors: connections,
      powerKw: firstPower,
      connectorType: firstConnectorType,
    );
  }
}
