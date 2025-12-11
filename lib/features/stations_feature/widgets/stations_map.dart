import 'package:flutter/material.dart';
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
  bool _ocmLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadUserLocationAndStations();
  }

  @override
  void didUpdateWidget(covariant StationsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userLocation != null &&
        widget.userLocation != oldWidget.userLocation &&
        _controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(widget.userLocation!, 14),
      );
    }
  }

  Future<void> _loadUserLocationAndStations() async {
    if (_ocmLoadedOnce) return;
    _ocmLoadedOnce = true;
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

      final stations = await fetchOcmStationsNearby(
        latitude: userLatLng.latitude,
        longitude: userLatLng.longitude,
      );

      _updateMarkers(stations);

      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(userLatLng, 13),
      );
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
  }

  void _updateMarkers(List<OcmStation> stations) {
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

    // After markers are loaded, center on user (if available) with a closer zoom.
    if (widget.userLocation != null) {
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(widget.userLocation!, 15),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    widget.onMapCreated?.call(controller);
    if (widget.userLocation != null) {
      _controller!.moveCamera(
        CameraUpdate.newLatLngZoom(widget.userLocation!, 14),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: widget.userLocation ?? _initialCenter,
        zoom: 12,
      ),
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: true,
      markers: _markers,
      polylines: widget.polylines,
      zoomControlsEnabled: false,
    );
  }
}
