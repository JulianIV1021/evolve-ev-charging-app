import 'package:equatable/equatable.dart';
// import 'package:flutter_map_training/features/stations_feature/bloc/bloc.dart'; // Removed unused import
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/ocm_station.dart';

abstract class StationsEvent extends Equatable {
  const StationsEvent();
  @override
  List<Object> get props => [];
}

class FetchStationsEvent extends StationsEvent {}
class StationsRequested extends StationsEvent {}

class CenterOnUserRequested extends StationsEvent {
  final LatLng target;
  const CenterOnUserRequested(this.target);
}

class ChangeMapTypeEvent extends StationsEvent {
  final MapType mapType;
  const ChangeMapTypeEvent(this.mapType);
}

class LocationRequestedEvent extends StationsEvent {
  final void Function() onLocationDenied;

  const LocationRequestedEvent({required this.onLocationDenied});
}

class PermissionRequestEvent extends StationsEvent {}

class SearchQueryChangedEvent extends StationsEvent {
  final String searchQuery;
  const SearchQueryChangedEvent(this.searchQuery);
}

class AddToRecentSearchesEvent extends StationsEvent {
  final OcmStation station;
  const AddToRecentSearchesEvent(this.station);
}

class LoadSearchHistoryEvent extends StationsEvent {}

class ClearRecentSearchesEvent extends StationsEvent {}

class ClearSearchQueryEvent extends StationsEvent {}

class StationSelectedViaSearchEvent extends StationsEvent {
  final OcmStation station;
  const StationSelectedViaSearchEvent(this.station);
}

class OnCameraMoveEvent extends StationsEvent {
  final CameraPosition cameraPosition;
  const OnCameraMoveEvent(this.cameraPosition);
}
