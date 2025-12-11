import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../common/utils/logger.dart';
import '../models/ocm_station.dart';
import '../repository/station_repository.dart';
import 'bloc.dart';

class StationsBloc extends Bloc<StationsEvent, StationsState> {
  final StationRepository stationsRepository;
  GoogleMapController? mapController;

  StationsBloc(this.stationsRepository) : super(const StationsState()) {
    on<FetchStationsEvent>(_onStationsFetched);
    on<StationsRequested>(_onStationsRequested);
    on<CenterOnUserRequested>(_onCenterOnUserRequested);
    on<ChangeMapTypeEvent>(_onMapTypeChanged);
    on<LocationRequestedEvent>(_onLocationRequested);
    on<PermissionRequestEvent>(_onPermissionRequested);
    on<SearchQueryChangedEvent>(_onSearchQueryChanged);
    on<AddToRecentSearchesEvent>(_onAddToRecentSearches);
    on<ClearRecentSearchesEvent>(_onClearRecentSearches);
    on<ClearSearchQueryEvent>(_onClearSearchQuery);
    on<StationSelectedViaSearchEvent>(_onStationSelectedViaSearch);
    on<OnCameraMoveEvent>(_onCameraMove);
  }

  void initMapController(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _onStationsFetched(
    FetchStationsEvent event,
    Emitter<StationsState> emit,
  ) async {
    emit(state.copyWith(status: StationStatus.loading));
    try {
      final currentLocation = await stationsRepository.getCurrentLocation();
      final stations = await stationsRepository.getStationsNearby(
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
      );
      emit(state.copyWith(
        status: StationStatus.loaded,
        stations: stations,
        cameraPosition: CameraPosition(
          target: currentLocation,
          zoom: 14,
        ),
      ));
    } catch (_) {
      emit(state.copyWith(status: StationStatus.error));
    }
  }

  Future<void> _onCenterOnUserRequested(
    CenterOnUserRequested event,
    Emitter<StationsState> emit,
  ) async {
    final position = CameraPosition(
      target: event.target,
      zoom: 14,
    );
    mapController?.animateCamera(CameraUpdate.newCameraPosition(position));
    emit(state.copyWith(cameraPosition: position));
  }

  Future<void> _onStationsRequested(
    StationsRequested event,
    Emitter<StationsState> emit,
  ) async {
    emit(state.copyWith(status: StationStatus.loading));
    try {
      final currentLocation = await stationsRepository.getCurrentLocation();
      final stations = await stationsRepository.getStationsNearby(
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
      );
      emit(state.copyWith(
        status: StationStatus.loaded,
        stations: stations,
        cameraPosition: CameraPosition(
          target: currentLocation,
          zoom: 14,
        ),
      ));
    } catch (e, st) {
      log.severe('Stations load failed: $e\n$st');
      emit(state.copyWith(status: StationStatus.error));
    }
  }

  Future<void> _onMapTypeChanged(
    ChangeMapTypeEvent event,
    Emitter<StationsState> emit,
  ) async {
    emit(state.copyWith(
      mapType: event.mapType,
    ));
  }

  Future<void> _onLocationRequested(
    LocationRequestedEvent event,
    Emitter<StationsState> emit,
  ) async {
    try {
      final location = await stationsRepository.getCurrentLocation();
      mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: 15, // recenter with a closer zoom
        ),
      ));
    } catch (error) {
      event.onLocationDenied();
      log.severe(error);
    }
  }

  Future<void> _onPermissionRequested(
    PermissionRequestEvent event,
    Emitter<StationsState> emit,
  ) async {
    await stationsRepository.requestPermission();
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChangedEvent event,
    Emitter<StationsState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.searchQuery));
  }

  Future<void> _onAddToRecentSearches(
    AddToRecentSearchesEvent event,
    Emitter<StationsState> emit,
  ) async {
    final recentSearches = [...state.recentSearches];
    if (!recentSearches.any((s) => s.id == event.station.id)) {
      recentSearches.add(event.station);
    }
    emit(state.copyWith(recentSearches: recentSearches));
  }

  Future<void> _onClearRecentSearches(
    ClearRecentSearchesEvent event,
    Emitter<StationsState> emit,
  ) async {
    emit(state.copyWith(recentSearches: []));
  }

  Future<void> _onClearSearchQuery(
    ClearSearchQueryEvent event,
    Emitter<StationsState> emit,
  ) async {
    emit(state.copyWith(searchQuery: ''));
  }

  Future<void> _onStationSelectedViaSearch(
    StationSelectedViaSearchEvent event,
    Emitter<StationsState> emit,
  ) async {
    mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(event.station.latitude, event.station.longitude),
        zoom: 16,
      ),
    ));
  }

  Future<void> _onCameraMove(
    OnCameraMoveEvent event,
    Emitter<StationsState> emit,
  ) async {
    emit(state.copyWith(cameraPosition: event.cameraPosition));
  }
}
