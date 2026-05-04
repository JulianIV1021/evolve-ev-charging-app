import 'package:equatable/equatable.dart';
import 'charger_model.dart';

/// Vehicle profile stored in Firestore at users/{uid}.evProfile.
class EVProfile extends Equatable {
  const EVProfile({
    this.vehicleMake = '',
    this.vehicleModel = '',
    this.batteryCapacityKwh = 60.0,
    this.currentSocPercent = 0.8,
    this.connectors = const [ConnectorType.type2],
    this.maxChargingPowerKw = 50.0,
  });

  final String vehicleMake;
  final String vehicleModel;

  /// Total usable battery capacity in kWh.
  final double batteryCapacityKwh;

  /// Current state of charge (0.0–1.0). User-entered before navigation.
  final double currentSocPercent;

  /// Preferred connector types.
  final List<ConnectorType> connectors;

  /// Max AC or DC charging power accepted by the vehicle.
  final double maxChargingPowerKw;

  /// Current usable energy in kWh.
  double get currentEnergyKwh => batteryCapacityKwh * currentSocPercent;

  factory EVProfile.fromMap(Map<String, dynamic> m) {
    return EVProfile(
      vehicleMake: m['vehicleMake'] as String? ?? '',
      vehicleModel: m['vehicleModel'] as String? ?? '',
      batteryCapacityKwh: (m['batteryCapacityKwh'] as num?)?.toDouble() ?? 60.0,
      currentSocPercent: (m['currentSocPercent'] as num?)?.toDouble() ?? 0.8,
      connectors: (m['connectors'] as List<dynamic>? ?? ['type2'])
          .map((e) => _parseConnector(e))
          .toList(),
      maxChargingPowerKw:
          (m['maxChargingPowerKw'] as num?)?.toDouble() ?? 50.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'vehicleMake': vehicleMake,
        'vehicleModel': vehicleModel,
        'batteryCapacityKwh': batteryCapacityKwh,
        'currentSocPercent': currentSocPercent,
        'connectors': connectors.map((c) => c.name).toList(),
        'maxChargingPowerKw': maxChargingPowerKw,
      };

  static ConnectorType _parseConnector(dynamic v) => switch (v) {
        'type2' => ConnectorType.type2,
        'chademo' => ConnectorType.chademo,
        'ccs2' => ConnectorType.ccs2,
        'j1772' => ConnectorType.j1772,
        _ => ConnectorType.other,
      };

  EVProfile copyWith({
    String? vehicleMake,
    String? vehicleModel,
    double? batteryCapacityKwh,
    double? currentSocPercent,
    List<ConnectorType>? connectors,
    double? maxChargingPowerKw,
  }) {
    return EVProfile(
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      batteryCapacityKwh: batteryCapacityKwh ?? this.batteryCapacityKwh,
      currentSocPercent: currentSocPercent ?? this.currentSocPercent,
      connectors: connectors ?? this.connectors,
      maxChargingPowerKw: maxChargingPowerKw ?? this.maxChargingPowerKw,
    );
  }

  @override
  List<Object?> get props => [
        vehicleMake,
        vehicleModel,
        batteryCapacityKwh,
        currentSocPercent,
        connectors,
        maxChargingPowerKw,
      ];
}
