import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/ocm_station.dart';
import '../services/location_service.dart';
import '../services/ocm_stations_service.dart';

abstract class StationRepository {
  final LocationService locationService;

  const StationRepository({
    required this.locationService,
  });

  Future<List<OcmStation>> getStations();
  Future<List<OcmStation>> getStationsNearby({
    required double latitude,
    required double longitude,
  });

  Future<LatLng> getCurrentLocation();

  Future<void> requestPermission();
}

class StationRepositoryImpl implements StationRepository {
  @override
  final LocationService locationService;

  StationRepositoryImpl({
    required this.locationService,
  });

  @override
  Future<List<OcmStation>> getStations() async {
    final currentLocation = await locationService.getCurrentLocation();
    return await getStationsNearby(
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
    );
  }

  @override
  Future<List<OcmStation>> getStationsNearby({
    required double latitude,
    required double longitude,
  }) async {
    return await fetchOcmStationsNearby(
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<LatLng> getCurrentLocation() async {
    return await locationService.getCurrentLocation();
  }

  @override
  Future<void> requestPermission() async {
    return await locationService.requestPermission();
  }
}
