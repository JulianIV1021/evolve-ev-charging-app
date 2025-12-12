import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/ocm_station.dart';
import '../services/ocm_stations_service.dart';

class StationsMap extends StatefulWidget {
  final bool myLocationEnabled;
  final LatLng? userLocation;
  final ValueChanged<OcmStation>? onStationSelected;
  final Set<Polyline> polylines;
  final ValueChanged<GoogleMapController>? onMapCreated;

  const StationsMap({
    Key? key,
    this.myLocationEnabled = false,
    this.userLocation,
    this.onStationSelected,
    this.polylines = const {},
    this.onMapCreated,
  }) : super(key: key);

  @override
  State<StationsMap> createState() => _StationsMapState();
}

class _StationsMapState extends State<StationsMap> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  LatLng _initialCenter = const LatLng(14.5995, 120.9842);
  bool _isLoading = false;
  LatLng? _lastFetchCenter;
  List<int> _lastStationIds = [];
  Timer? _cameraDebounce;
  CameraPosition? _lastCameraPosition;
  double _lastZoom = 15;
  bool _ocmLoadedOnce = false;
  bool _initialCentered = false;
  bool _userInteracted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserLocationAndStations();
    });
  }

  @override
  void didUpdateWidget(covariant StationsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _loadUserLocationAndStations() async {
    if (_isLoading || _ocmLoadedOnce) return;
    _isLoading = true;
    try {
      LatLng userLatLng;
      if (widget.userLocation != null) {
        userLatLng = widget.userLocation!;
      } else {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        userLatLng = LatLng(pos.latitude, pos.longitude);
      }

      setState(() {
        _initialCenter = userLatLng;
      });

      await _fetchStationsForCenter(userLatLng);
      if (!_initialCentered) {
        _controller?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 15));
        _initialCentered = true;
      }
    } catch (e) {
      debugPrint('Error loading OCM stations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Charging station data temporarily unavailable. Please try again later.',
            ),
          ),
        );
      }
    }
    _isLoading = false;
  }

  double _radiusForZoom(double zoom) {
    if (zoom >= 15) return 2;
    if (zoom >= 13) return 5;
    if (zoom >= 11) return 10;
    return 20;
  }

  Future<void> _fetchStationsForCenter(LatLng center) async {
    if (_isLoading) return;
    final radiusKm = _radiusForZoom(_lastZoom);

    _isLoading = true;
    try {
      final stations = await fetchOcmStationsNearby(
        latitude: center.latitude,
        longitude: center.longitude,
        distanceKm: radiusKm,
      );
      _lastFetchCenter = center;
      _ocmLoadedOnce = true;
      _updateMarkers(stations);
    } catch (e) {
      debugPrint('Error loading OCM stations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Charging station data temporarily unavailable. Please try again later.',
            ),
          ),
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  void _updateMarkers(List<OcmStation> stations) {
    // Skip rebuild if station set hasn't changed (prevents expensive JNI uploads).
    final ids = stations.map((s) => s.id).toList()..sort();
    if (listEquals(ids, _lastStationIds)) {
      return;
    }
    _lastStationIds = ids;

    final Set<Marker> markers = {};

    for (final station in stations) {
      markers.add(
        Marker(
          markerId: MarkerId('ocm_${station.id}'),
          position: station.latLng,
          infoWindow: const InfoWindow(title: ''),
          onTap: () {
            widget.onStationSelected?.call(station);
          },
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _markers = markers;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    widget.onMapCreated?.call(controller);
    if (!_initialCentered && widget.userLocation != null) {
      _controller!.moveCamera(
        CameraUpdate.newLatLngZoom(widget.userLocation!, 15),
      );
      _initialCentered = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      onCameraMoveStarted: () {
        _userInteracted = true;
      },
      onCameraMove: (position) {
        _lastZoom = position.zoom;
        _lastCameraPosition = position;
      },
      onCameraIdle: _onCameraIdle,
      initialCameraPosition: CameraPosition(
        target: widget.userLocation ?? _initialCenter,
        zoom: 15,
      ),
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: true,
      markers: _markers,
      polylines: widget.polylines,
      zoomControlsEnabled: false,
    );
  }

  void _onCameraIdle() {
    _cameraDebounce?.cancel();
    _cameraDebounce = Timer(const Duration(milliseconds: 500), () {
      final target = _lastCameraPosition?.target ?? _initialCenter;
      _fetchStationsForCenter(target);
    });
  }

  @override
  void dispose() {
    _cameraDebounce?.cancel();
    super.dispose();
  }
}
