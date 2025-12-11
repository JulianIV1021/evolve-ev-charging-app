import 'package:equatable/equatable.dart';
// import 'package:flutter/cupertino.dart'; // Removed unused import
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/ocm_station.dart';

enum StationStatus { initial, loading, loaded, error }

class StationsState extends Equatable {
  final StationStatus status;
  final List<OcmStation> stations;
  final MapType mapType;
  final CameraPosition cameraPosition;
  final String searchQuery;
  final List<OcmStation> recentSearches;

  const StationsState({
    this.status = StationStatus.initial,
    this.stations = const <OcmStation>[],
    this.mapType = MapType.normal,
    this.cameraPosition = const CameraPosition(
      target: LatLng(47.808376, 14.373285),
      zoom: 8,
    ),
    this.searchQuery = '',
    this.recentSearches = const <OcmStation>[],
  });

  StationsState copyWith({
    StationStatus? status,
    List<OcmStation>? stations,
    MapType? mapType,
    CameraPosition? cameraPosition,
    String? searchQuery,
    List<OcmStation>? recentSearches,
  }) {
    return StationsState(
      status: status ?? this.status,
      stations: stations ?? this.stations,
      mapType: mapType ?? this.mapType,
      cameraPosition: cameraPosition ?? this.cameraPosition,
      searchQuery: searchQuery ?? this.searchQuery,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }

  @override
  List<Object?> get props => [
        status,
        stations,
        mapType,
        cameraPosition,
        searchQuery,
        recentSearches,
      ];
}
