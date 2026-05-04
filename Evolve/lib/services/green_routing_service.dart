import '../config/api_config.dart';
import '../models/ev_profile_model.dart';
import '../models/route_option_model.dart';
import '../models/route_score_model.dart';
import '../utils/app_logger.dart';

/// Client-side EV route scoring (ASSUMPTION A4: no third-party EV routing API).
///
/// Algorithm:
/// 1. Score each route relative to the worst candidate (0.0 = worst, 1.0 = best).
/// 2. Mark lowest-energy route as [RouteScore.isGreenRoute].
/// 3. [selectGreenRoute] enforces a minimum 10% arrival SoC buffer.
class GreenRoutingService {
  GreenRoutingService._();
  static final GreenRoutingService instance = GreenRoutingService._();

  /// Score [route] relative to [allCandidates].
  RouteScore scoreRoute({
    required RouteOption route,
    required List<RouteOption> allCandidates,
    required EVProfile evProfile,
    double avgPricePerKwh = 15.0, // ₱/kWh default
  }) {
    final energies = allCandidates.map((r) => r.estimatedEnergyKwh).toList();
    final maxEnergy = energies.reduce((a, b) => a > b ? a : b);
    final minEnergy = energies.reduce((a, b) => a < b ? a : b);
    final range = maxEnergy - minEnergy;

    final efficiencyRating =
        range < 0.001 ? 1.0 : (maxEnergy - route.estimatedEnergyKwh) / range;

    final energySaved = maxEnergy - route.estimatedEnergyKwh;
    final co2Saved = energySaved * ApiConfig.co2GramsPerKwh;
    final costSaved = energySaved * avgPricePerKwh;
    final isGreen = (route.estimatedEnergyKwh - minEnergy).abs() < 0.001;

    return RouteScore(
      efficiencyRating: efficiencyRating.clamp(0.0, 1.0),
      estimatedCo2GramsSaved: co2Saved.clamp(0, double.infinity),
      estimatedEnergyCostSavings: costSaved.clamp(0, double.infinity),
      isGreenRoute: isGreen,
    );
  }

  /// Score all candidates and return the list with [RouteScore] attached.
  List<RouteOption> scoreAll({
    required List<RouteOption> candidates,
    required EVProfile evProfile,
  }) {
    return candidates.map((r) {
      final score = scoreRoute(
        route: r,
        allCandidates: candidates,
        evProfile: evProfile,
      );
      return r.withScore(score);
    }).toList();
  }

  /// Select the greenest route that satisfies the arrival SoC buffer.
  ///
  /// If no candidate meets [minArrivalSocPercent], returns the highest-SoC
  /// candidate with a warning logged.
  RouteOption selectGreenRoute({
    required List<RouteOption> candidates,
    required EVProfile evProfile,
    double minArrivalSocPercent = ApiConfig.minArrivalSocPercent,
  }) {
    // Never pick the Fastest route as the Greenest — it's the same road,
    // just relabelled. Greenest must be a genuine eco alternative.
    final pool = candidates.where((r) => r.mode != RouteMode.fastest).toList();
    final searchPool = pool.isNotEmpty ? pool : candidates;

    final viable = searchPool
        .where((r) => r.estimatedArrivalSocPercent >= minArrivalSocPercent)
        .toList();

    RouteOption selected;
    if (viable.isEmpty) {
      // Best-effort: route with highest arrival SoC
      selected = searchPool.reduce(
        (a, b) => a.estimatedArrivalSocPercent > b.estimatedArrivalSocPercent
            ? a
            : b,
      );
      AppLogger.instance.warning('green_route_soc_buffer_unmet', {
        'best_arrival_soc': selected.estimatedArrivalSocPercent,
        'required_soc': minArrivalSocPercent,
      });
    } else {
      // Lowest energy among viable candidates
      selected = viable.reduce(
        (a, b) =>
            a.estimatedEnergyKwh < b.estimatedEnergyKwh ? a : b,
      );
    }

    AppLogger.instance.info('green_route_selected', {
      'energy_kwh': selected.estimatedEnergyKwh,
      'arrival_soc': selected.estimatedArrivalSocPercent,
      'co2_saved_g': selected.score?.estimatedCo2GramsSaved ?? 0,
    });

    return selected.withMode(RouteMode.greenest);
  }
}
