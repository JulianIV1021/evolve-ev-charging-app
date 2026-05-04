import 'package:equatable/equatable.dart';

/// EV efficiency score for a route produced by [GreenRoutingService].
class RouteScore extends Equatable {
  const RouteScore({
    required this.efficiencyRating,
    required this.estimatedCo2GramsSaved,
    required this.estimatedEnergyCostSavings,
    required this.isGreenRoute,
  });

  /// Relative efficiency 0.0 (worst) – 1.0 (best among candidates).
  final double efficiencyRating;

  /// CO₂ saved in grams vs the highest-consumption candidate route.
  final double estimatedCo2GramsSaved;

  /// Energy cost saved in local currency vs highest-consumption candidate.
  final double estimatedEnergyCostSavings;

  /// True for the lowest-energy route among all candidates.
  final bool isGreenRoute;

  @override
  List<Object?> get props => [
        efficiencyRating,
        estimatedCo2GramsSaved,
        isGreenRoute,
      ];
}
