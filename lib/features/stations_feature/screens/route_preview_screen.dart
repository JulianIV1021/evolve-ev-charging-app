import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ocm_station.dart';
import '../services/pending_charging_intent_store.dart';

class RoutePreviewScreen extends StatefulWidget {
  final List<LatLng> polylinePoints;
  final String distanceText;
  final String durationText;
  final LatLng origin;
  final LatLng destination;
  final OcmStation? station;

  const RoutePreviewScreen({
    super.key,
    required this.polylinePoints,
    required this.distanceText,
    required this.durationText,
    required this.origin,
    required this.destination,
    this.station,
  });

  @override
  State<RoutePreviewScreen> createState() => _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends State<RoutePreviewScreen> {
  GoogleMapController? _controller;

  Future<void> _launchExternalNavigation() async {
    if (widget.station != null) {
      final station = widget.station!;
      PendingChargingIntentStore.instance.setIntent(
        PendingChargingIntent(
          stationId: station.id.toString(),
          stationName: station.name,
          coordinates:
              '${station.latitude.toStringAsFixed(4)}, ${station.longitude.toStringAsFixed(4)}',
          latitude: station.latitude,
          longitude: station.longitude,
          address: station.address,
          connectorLabel: station.connectorType ?? 'Type 2 AC',
          tariffPerKwh: _parseTariff(station.usageCost),
          chargingSpeed: station.powerKw ?? 50,
          amperage: 15,
          voltage: 150,
        ),
      );
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${widget.origin.latitude},${widget.origin.longitude}'
      '&destination=${widget.destination.latitude},${widget.destination.longitude}'
      '&travelmode=driving',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
      return;
    }
    // Return to previous screen so the pending intent card can surface there.
    Navigator.of(context).pop();
  }

  double _parseTariff(String usageCost) {
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(usageCost);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.blue,
      width: 6,
      points: widget.polylinePoints,
    );

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('origin'),
        position: widget.origin,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(markerId: const MarkerId('destination'), position: widget.destination),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: widget.origin, zoom: 12),
            polylines: {polyline},
            markers: markers,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) async {
              _controller = c;
              if (widget.polylinePoints.isNotEmpty) {
                LatLngBounds bounds = _computeBounds(widget.polylinePoints);
                bounds = _inflateBounds(bounds);
                final size = MediaQuery.of(context).size;
                final inset = (size.shortestSide * 0.25).clamp(80, 220).toDouble();
                try {
                  await _controller!.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, inset),
                  );
                } catch (_) {
                  await _controller!.animateCamera(
                    CameraUpdate.newLatLngZoom(widget.destination, 12),
                  );
                }
              }
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your location -> Destination',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              minChildSize: 0.12,
              maxChildSize: 0.3,
              initialChildSize: 0.18,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.durationText,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              widget.distanceText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Best route, typical traffic',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Leave later'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: Colors.lightBlueAccent,
                                  foregroundColor: Colors.black87,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _launchExternalNavigation,
                                child: const Text('Go now'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  LatLngBounds _computeBounds(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;

    for (final p in points) {
      if (minLat == null) {
        minLat = maxLat = p.latitude;
        minLng = maxLng = p.longitude;
      } else {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat!) maxLat = p.latitude;
        if (p.longitude < minLng!) minLng = p.longitude;
        if (p.longitude > maxLng!) maxLng = p.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  LatLngBounds _inflateBounds(LatLngBounds bounds) {
    final latDelta = bounds.northeast.latitude - bounds.southwest.latitude;
    final lngDelta = bounds.northeast.longitude - bounds.southwest.longitude;

    final minDelta = 0.01;
    final addLat = latDelta < minDelta ? (minDelta - latDelta) / 2 : 0;
    final addLng = lngDelta < minDelta ? (minDelta - lngDelta) / 2 : 0;

    return LatLngBounds(
      southwest: LatLng(bounds.southwest.latitude - addLat, bounds.southwest.longitude - addLng),
      northeast: LatLng(bounds.northeast.latitude + addLat, bounds.northeast.longitude + addLng),
    );
  }
}
