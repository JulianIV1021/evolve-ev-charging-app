import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/ev_profile_model.dart';
import '../models/route_option_model.dart';

/// Abstract navigation service interface.
/// Implementation: [GoogleNavigationService].
abstract class NavigationService {
  /// Fetch route options from [origin] to [destination] for the given [evProfile].
  /// Returns a list of [RouteOption]: fastest, cheapest, and one pre-scored for greenest.
  Future<List<RouteOption>> getRouteOptions({
    required LatLng origin,
    required LatLng destination,
    required EVProfile evProfile,
  });

  /// Start turn-by-turn navigation on a chosen [route].
  /// Emits [NavigationState] events as the user moves.
  Stream<NavigationState> startNavigation(RouteOption route);

  /// Stop the active navigation session.
  Future<void> stopNavigation();

  /// Compute a new route from [currentPosition] to [destination].
  /// Called on station-offline or traffic-delay auto-reroute.
  Future<RouteOption> reroute({
    required LatLng currentPosition,
    required LatLng destination,
    required EVProfile evProfile,
    required RouteMode preferredMode,
    String? reason,
  });
}
