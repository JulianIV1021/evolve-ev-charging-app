import 'dart:async';

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/api_config.dart';
import '../models/ev_profile_model.dart';
import '../models/route_option_model.dart';
import '../utils/app_logger.dart';
import '../utils/polyline_decoder.dart';
import 'navigation_service.dart';

/// Google Maps Directions API implementation of [NavigationService].
class GoogleNavigationService implements NavigationService {
  GoogleNavigationService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConfig.directionsBaseUrl));

  final Dio _dio;
  final _uuid = const Uuid();

  StreamController<NavigationState>? _navController;
  StreamSubscription<Position>? _positionSub;
  // ignore: unused_field
  RouteOption? _activeRoute;

  // ---------------------------------------------------------------------------
  // Route fetching
  // ---------------------------------------------------------------------------

  @override
  Future<List<RouteOption>> getRouteOptions({
    required LatLng origin,
    required LatLng destination,
    required EVProfile evProfile,
  }) async {
    final correlationId = _uuid.v4();
    AppLogger.instance.info('route_options_fetching', {
      'correlation_id': correlationId,
      'dest_lat': destination.latitude,
      'dest_lng': destination.longitude,
    });

    try {
      // Two parallel API calls — like Waze giving real route choices:
      //   1. Standard routing with alternatives (fastest, balanced)
      //   2. Avoid-highways routing (more scenic / eco-friendly path)
      final results = await Future.wait([
        _fetchDirections(origin, destination),
        _fetchDirections(origin, destination, avoid: 'highways'),
      ]);

      final standardRaw = results[0];
      final ecoRaw = results[1];

      // Parse both into RouteOption candidates
      final standard = _parseApiRoutes(standardRaw, destination, evProfile);
      final eco = _parseApiRoutes(ecoRaw, destination, evProfile);

      // Add eco routes that are genuinely different (distance differs >0.5 km)
      final all = [...standard];
      for (final e in eco) {
        if (!all.any((s) => (s.distanceKm - e.distanceKm).abs() < 0.5)) {
          all.add(e);
        }
      }

      if (all.isEmpty) {
        AppLogger.instance.warning('route_options_no_results', {
          'correlation_id': correlationId,
        });
        return [_fallbackRoute(origin, destination, evProfile, RouteMode.fastest)];
      }

      // Sort by duration: shortest time first
      all.sort((a, b) => a.eta.compareTo(b.eta));

      // Assign modes to the top 3 distinct real routes
      final modes = [RouteMode.fastest, RouteMode.cheapest, RouteMode.greenest];
      final options = <RouteOption>[];
      for (int i = 0; i < all.length && i < 3; i++) {
        options.add(all[i].withMode(modes[i]));
      }

      // Synthetic pad as last resort when API returned fewer than 3 unique routes
      while (options.length < 3) {
        final base = options.first;
        final idx = options.length;
        // idx=1 → Most Efficient: +20% time, -12% energy
        // idx=2 → Greenest:       +15% time, -17% energy
        final timeFactor = idx == 1 ? 1.20 : 1.15;
        final energyFactor = idx == 1 ? 0.88 : 0.83;
        final energy = base.estimatedEnergyKwh * energyFactor;
        final arrivalSoc = (evProfile.currentSocPercent -
                (energy / evProfile.batteryCapacityKwh))
            .clamp(-1.0, 1.0);
        options.add(RouteOption(
          id: _uuid.v4(),
          mode: modes[idx],
          eta: Duration(seconds: (base.eta.inSeconds * timeFactor).round()),
          distanceKm: base.distanceKm,
          estimatedEnergyKwh: energy,
          estimatedArrivalSocPercent: arrivalSoc,
          polylinePoints: base.polylinePoints,
          chargingStops: arrivalSoc < 0
              ? [
                  ChargingStop(
                    stationId: '',
                    stationName: 'Charging stop needed',
                    location: destination,
                    estimatedChargeKwh: -arrivalSoc * evProfile.batteryCapacityKwh,
                  ),
                ]
              : [],
        ));
      }

      AppLogger.instance.info('route_options_fetched', {
        'correlation_id': correlationId,
        'real_routes': all.length,
        'total': options.length,
      });

      return options;
    } on DioException catch (e) {
      AppLogger.instance.error('route_options_fetch_failed', {
        'correlation_id': correlationId,
        'error': e.message ?? 'dio_error',
      });
      return [_fallbackRoute(origin, destination, evProfile, RouteMode.fastest)];
    }
  }

  /// Single Directions API call. Returns raw route list (may be empty on error).
  Future<List<dynamic>> _fetchDirections(
    LatLng origin,
    LatLng destination, {
    String? avoid,
  }) async {
    try {
      final resp = await _dio.get('', queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'alternatives': 'true',
        'key': ApiConfig.googleMapsApiKey,
        if (avoid != null) 'avoid': avoid,
      });
      final status = resp.data['status'] as String? ?? 'UNKNOWN';
      final routes = resp.data['routes'] as List<dynamic>? ?? [];
      // ignore: avoid_print
      print('[DEBUG] Directions API status=$status, routes=${routes.length}, avoid=${avoid ?? 'none'}, error=${resp.data['error_message'] ?? 'none'}');
      if (status != 'OK') {
        AppLogger.instance.warning('directions_api_non_ok', {
          'status': status,
          'error_message': resp.data['error_message'] ?? '',
          'avoid': avoid ?? 'none',
          'routes_count': routes.length,
        });
      } else {
        AppLogger.instance.info('directions_api_ok', {
          'routes_count': routes.length,
          'avoid': avoid ?? 'none',
        });
      }
      return routes;
    } on DioException catch (e) {
      // ignore: avoid_print
      print('[DEBUG] Directions API DioException: ${e.message}, type=${e.type}');
      AppLogger.instance.error('directions_api_request_failed', {
        'error': e.message ?? e.toString(),
        'avoid': avoid ?? 'none',
      });
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('[DEBUG] Directions API unexpected error: $e');
      AppLogger.instance.error('directions_api_unexpected_error', {
        'error': e.toString(),
        'avoid': avoid ?? 'none',
      });
      return [];
    }
  }

  /// Parse a raw Directions API route list into [RouteOption] candidates.
  /// Mode is set to [RouteMode.fastest] as placeholder — caller reassigns.
  List<RouteOption> _parseApiRoutes(
    List<dynamic> raw,
    LatLng destination,
    EVProfile evProfile,
  ) {
    final result = <RouteOption>[];
    for (final r in raw) {
      try {
        final leg = (r['legs'] as List).first as Map<String, dynamic>;
        final durationSec = (leg['duration_in_traffic']?['value'] ??
            leg['duration']['value']) as int;
        final distanceKm = (leg['distance']['value'] as int) / 1000.0;
        final points =
            decodePolyline(r['overview_polyline']['points'] as String);
        final energyKwh = _estimateEnergy(distanceKm, evProfile);
        final arrivalSoc = (evProfile.currentSocPercent -
                energyKwh / evProfile.batteryCapacityKwh)
            .clamp(-1.0, 1.0);
        result.add(RouteOption(
          id: _uuid.v4(),
          mode: RouteMode.fastest, // reassigned after dedup + sort
          eta: Duration(seconds: durationSec),
          distanceKm: distanceKm,
          estimatedEnergyKwh: energyKwh,
          estimatedArrivalSocPercent: arrivalSoc,
          polylinePoints: points,
          chargingStops: arrivalSoc < 0
              ? [
                  ChargingStop(
                    stationId: '',
                    stationName: 'Charging stop needed',
                    location: destination,
                    estimatedChargeKwh: -arrivalSoc * evProfile.batteryCapacityKwh,
                  ),
                ]
              : [],
        ));
      } catch (_) {
        // Skip malformed route entries
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Turn-by-turn navigation
  // ---------------------------------------------------------------------------

  @override
  Stream<NavigationState> startNavigation(RouteOption route) {
    _navController?.close();
    _navController = StreamController<NavigationState>.broadcast();
    _activeRoute = route;

    // Defer so the caller's .listen() attaches before we emit —
    // broadcast streams drop events fired before any listener subscribes.
    scheduleMicrotask(() {
      _navController?.add(
        NavigationState(
          phase: NavigationPhase.active,
          currentInstruction: 'Head towards destination',
          etaRemaining: route.eta,
          distanceRemainingKm: route.distanceKm,
        ),
      );
    });

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      final current = LatLng(pos.latitude, pos.longitude);
      _onPositionUpdate(current, route);
    });

    return _navController!.stream;
  }

  @override
  Future<void> stopNavigation() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _navController?.add(
      const NavigationState(phase: NavigationPhase.cancelled),
    );
    await _navController?.close();
    _navController = null;
    _activeRoute = null;
  }

  @override
  Future<RouteOption> reroute({
    required LatLng currentPosition,
    required LatLng destination,
    required EVProfile evProfile,
    required RouteMode preferredMode,
    String? reason,
  }) async {
    AppLogger.instance.warning('navigation_reroute_triggered', {
      'reason': reason ?? 'unknown',
    });

    _navController?.add(
      NavigationState(phase: NavigationPhase.rerouting, rerouteReason: reason),
    );

    final options = await getRouteOptions(
      origin: currentPosition,
      destination: destination,
      evProfile: evProfile,
    );

    final preferred = options.firstWhere(
      (o) => o.mode == preferredMode,
      orElse: () => options.first,
    );

    _activeRoute = preferred;
    _navController?.add(NavigationState(
      phase: NavigationPhase.active,
      currentInstruction: 'Rerouting complete',
      etaRemaining: preferred.eta,
      distanceRemainingKm: preferred.distanceKm,
    ));

    return preferred;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _onPositionUpdate(LatLng current, RouteOption route) {
    final dest = route.polylinePoints.isNotEmpty
        ? route.polylinePoints.last
        : null;
    if (dest == null) return;

    final distToDestM = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      dest.latitude,
      dest.longitude,
    );

    if (distToDestM < 50) {
      _navController?.add(
        NavigationState(phase: NavigationPhase.arrived, currentPosition: current),
      );
      stopNavigation();
      return;
    }

    final remainingKm = distToDestM / 1000.0;
    final etaSec = (remainingKm / 0.05).round(); // ~50 km/h estimate

    _navController?.add(NavigationState(
      phase: NavigationPhase.active,
      currentPosition: current,
      currentInstruction: _nearestInstruction(current, route),
      etaRemaining: Duration(seconds: etaSec),
      distanceRemainingKm: remainingKm,
    ));
  }

  String _nearestInstruction(LatLng pos, RouteOption route) {
    if (route.polylinePoints.isEmpty) return 'Continue towards destination';
    // Find nearest polyline point index
    double minDist = double.infinity;
    int nearestIdx = 0;
    for (int i = 0; i < route.polylinePoints.length; i++) {
      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        route.polylinePoints[i].latitude,
        route.polylinePoints[i].longitude,
      );
      if (d < minDist) {
        minDist = d;
        nearestIdx = i;
      }
    }
    final progress = nearestIdx / route.polylinePoints.length;
    if (progress < 0.25) return 'Head towards destination';
    if (progress < 0.5) return 'Continue on current road';
    if (progress < 0.75) return 'Keep going straight';
    return 'Destination is ahead';
  }

  double _estimateEnergy(double distanceKm, EVProfile evProfile) {
    return distanceKm * ApiConfig.defaultConsumptionWhPerKm / 1000.0;
  }

  RouteOption _fallbackRoute(
    LatLng origin,
    LatLng destination,
    EVProfile evProfile,
    RouteMode mode,
  ) {
    final distKm = Geolocator.distanceBetween(
          origin.latitude,
          origin.longitude,
          destination.latitude,
          destination.longitude,
        ) /
        1000.0;
    final energy = _estimateEnergy(distKm, evProfile);
    final arrivalSoc =
        evProfile.currentSocPercent - (energy / evProfile.batteryCapacityKwh);
    return RouteOption(
      id: _uuid.v4(),
      mode: mode,
      eta: Duration(minutes: (distKm / 0.5).round()),
      distanceKm: distKm,
      estimatedEnergyKwh: energy,
      estimatedArrivalSocPercent: arrivalSoc.clamp(-1.0, 1.0),
      polylinePoints: [origin, destination],
    );
  }
}
