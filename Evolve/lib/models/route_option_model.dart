import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'route_score_model.dart';

enum RouteMode { fastest, cheapest, greenest }

enum NavigationPhase { idle, computing, active, rerouting, arrived, cancelled }

class ChargingStop extends Equatable {
  const ChargingStop({
    required this.stationId,
    required this.stationName,
    required this.location,
    required this.estimatedChargeKwh,
  });

  final String stationId;
  final String stationName;
  final LatLng location;
  final double estimatedChargeKwh;

  @override
  List<Object?> get props => [stationId];
}

class RouteOption extends Equatable {
  const RouteOption({
    required this.id,
    required this.mode,
    required this.eta,
    required this.distanceKm,
    required this.estimatedEnergyKwh,
    required this.estimatedArrivalSocPercent,
    required this.polylinePoints,
    this.score,
    this.chargingStops = const [],
  });

  final String id;
  final RouteMode mode;
  final Duration eta;
  final double distanceKm;
  final double estimatedEnergyKwh;

  /// Estimated SoC at destination (0.0–1.0). May be negative if range insufficient.
  final double estimatedArrivalSocPercent;

  final List<LatLng> polylinePoints;
  final RouteScore? score;
  final List<ChargingStop> chargingStops;

  bool get arrivalSocInsufficient =>
      estimatedArrivalSocPercent < 0.10;

  RouteOption withScore(RouteScore s) => RouteOption(
        id: id,
        mode: mode,
        eta: eta,
        distanceKm: distanceKm,
        estimatedEnergyKwh: estimatedEnergyKwh,
        estimatedArrivalSocPercent: estimatedArrivalSocPercent,
        polylinePoints: polylinePoints,
        score: s,
        chargingStops: chargingStops,
      );

  RouteOption withMode(RouteMode m) => RouteOption(
        id: id,
        mode: m,
        eta: eta,
        distanceKm: distanceKm,
        estimatedEnergyKwh: estimatedEnergyKwh,
        estimatedArrivalSocPercent: estimatedArrivalSocPercent,
        polylinePoints: polylinePoints,
        score: score,
        chargingStops: chargingStops,
      );

  @override
  List<Object?> get props =>
      [id, mode, estimatedEnergyKwh, estimatedArrivalSocPercent];
}

class NavigationState extends Equatable {
  const NavigationState({
    required this.phase,
    this.currentPosition,
    this.currentInstruction,
    this.etaRemaining,
    this.distanceRemainingKm,
    this.rerouteReason,
  });

  final NavigationPhase phase;
  final LatLng? currentPosition;
  final String? currentInstruction;
  final Duration? etaRemaining;
  final double? distanceRemainingKm;
  final String? rerouteReason;

  static const idle = NavigationState(phase: NavigationPhase.idle);

  @override
  List<Object?> get props => [phase, currentPosition, currentInstruction];
}
