import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/ev_profile_model.dart';
import '../models/route_option_model.dart';
import '../services/google_navigation_service.dart';
import '../services/green_routing_service.dart';

// ---------------------------------------------------------------------------
// Navigation service singleton
// ---------------------------------------------------------------------------

final navigationServiceProvider = Provider<GoogleNavigationService>(
  (_) => GoogleNavigationService(),
);

// ---------------------------------------------------------------------------
// Route computation
// ---------------------------------------------------------------------------

final _routeParamsProvider = StateProvider<_RouteParams?>((_) => null);

class _RouteParams {
  const _RouteParams({
    required this.origin,
    required this.destination,
    required this.evProfile,
    required this.destinationStationId,
  });

  final LatLng origin;
  final LatLng destination;
  final EVProfile evProfile;
  final String destinationStationId;
}

final routeOptionsProvider =
    FutureProvider<List<RouteOption>>((ref) async {
  final params = ref.watch(_routeParamsProvider);
  if (params == null) return [];

  final svc = ref.watch(navigationServiceProvider);
  final raw = await svc.getRouteOptions(
    origin: params.origin,
    destination: params.destination,
    evProfile: params.evProfile,
  );

  // Score all candidates for efficiency rating display.
  // The padding in GoogleNavigationService already assigns each route
  // distinct, correct values — so we return scored directly without
  // letting selectGreenRoute overwrite the Greenest slot.
  final gs = GreenRoutingService.instance;
  final scored = gs.scoreAll(candidates: raw, evProfile: params.evProfile);

  return scored;
});

/// Call this to initiate a route fetch before opening RouteOptionsScreen.
void fetchRouteOptions(
  WidgetRef ref, {
  required LatLng origin,
  required LatLng destination,
  required EVProfile evProfile,
  required String destinationStationId,
}) {
  ref.read(_routeParamsProvider.notifier).state = _RouteParams(
    origin: origin,
    destination: destination,
    evProfile: evProfile,
    destinationStationId: destinationStationId,
  );
}

// ---------------------------------------------------------------------------
// Active navigation state
// ---------------------------------------------------------------------------

final selectedRouteProvider = StateProvider<RouteOption?>((_) => null);

final navigationStateProvider =
    StateProvider<NavigationState>((_) => NavigationState.idle);

final destinationStationIdProvider = StateProvider<String?>((_) => null);
