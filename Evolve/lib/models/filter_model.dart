import 'package:equatable/equatable.dart';
import 'charger_model.dart';
import 'station_model.dart';

/// UI filter state for the station map. All fields are optional (null = no filter).
class StationFilter extends Equatable {
  const StationFilter({
    this.acOnly = false,
    this.dcOnly = false,
    this.availabilityFilter = const [],
    this.connectorTypes = const [],
    this.minPowerKw,
    this.maxPowerKw,
    this.maxPricePerKwh,
    this.compatibleOnly = true,
  });

  final bool acOnly;
  final bool dcOnly;
  final List<StationStatus> availabilityFilter;
  final List<ConnectorType> connectorTypes;
  final double? minPowerKw;
  final double? maxPowerKw;
  final double? maxPricePerKwh;

  /// When true, only show stations whose chargers are compatible with the
  /// user's EVProfile connector list.
  final bool compatibleOnly;

  bool get isDefault =>
      !acOnly &&
      !dcOnly &&
      availabilityFilter.isEmpty &&
      connectorTypes.isEmpty &&
      minPowerKw == null &&
      maxPowerKw == null &&
      maxPricePerKwh == null;

  StationFilter copyWith({
    bool? acOnly,
    bool? dcOnly,
    List<StationStatus>? availabilityFilter,
    List<ConnectorType>? connectorTypes,
    double? minPowerKw,
    double? maxPowerKw,
    double? maxPricePerKwh,
    bool? compatibleOnly,
    bool clearMinPower = false,
    bool clearMaxPower = false,
    bool clearMaxPrice = false,
  }) {
    return StationFilter(
      acOnly: acOnly ?? this.acOnly,
      dcOnly: dcOnly ?? this.dcOnly,
      availabilityFilter: availabilityFilter ?? this.availabilityFilter,
      connectorTypes: connectorTypes ?? this.connectorTypes,
      minPowerKw: clearMinPower ? null : (minPowerKw ?? this.minPowerKw),
      maxPowerKw: clearMaxPower ? null : (maxPowerKw ?? this.maxPowerKw),
      maxPricePerKwh:
          clearMaxPrice ? null : (maxPricePerKwh ?? this.maxPricePerKwh),
      compatibleOnly: compatibleOnly ?? this.compatibleOnly,
    );
  }

  static const StationFilter empty = StationFilter();

  @override
  List<Object?> get props => [
        acOnly,
        dcOnly,
        availabilityFilter,
        connectorTypes,
        minPowerKw,
        maxPowerKw,
        maxPricePerKwh,
        compatibleOnly,
      ];
}
