import '../models/charger_model.dart';
import '../models/ev_profile_model.dart';
import '../models/filter_model.dart';
import '../models/station_model.dart';

/// Applies [StationFilter] predicates to a list of [StationModel].
/// Pure client-side filtering — no Firestore query modification.
class StationFilterService {
  StationFilterService._();
  static final StationFilterService instance = StationFilterService._();

  List<StationModel> apply({
    required List<StationModel> stations,
    required StationFilter filter,
    EVProfile? evProfile,
  }) {
    if (filter.isDefault) return stations;

    return stations.where((station) {
      final chargers = station.chargers;

      // Availability
      if (filter.availabilityFilter.isNotEmpty &&
          !filter.availabilityFilter.contains(station.status)) {
        return false;
      }

      if (chargers.isNotEmpty) {
        // Charger type
        if (filter.acOnly && !chargers.any((c) => c.chargerType == ChargerType.ac)) {
          return false;
        }
        if (filter.dcOnly && !chargers.any((c) => c.chargerType == ChargerType.dc)) {
          return false;
        }

        // Connector types
        if (filter.connectorTypes.isNotEmpty &&
            !chargers.any((c) => filter.connectorTypes.contains(c.connectorType))) {
          return false;
        }

        // Power range
        if (filter.minPowerKw != null &&
            !chargers.any((c) => c.powerKw >= filter.minPowerKw!)) {
          return false;
        }
        if (filter.maxPowerKw != null &&
            !chargers.any((c) => c.powerKw <= filter.maxPowerKw!)) {
          return false;
        }

        // Price
        if (filter.maxPricePerKwh != null &&
            !chargers.any((c) => c.pricePerKwh <= filter.maxPricePerKwh!)) {
          return false;
        }

        // EV profile compatibility
        if (filter.compatibleOnly && evProfile != null) {
          final userConnectors = evProfile.connectors.toSet();
          if (!chargers.any((c) => userConnectors.contains(c.connectorType))) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }
}
