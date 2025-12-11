import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsResult {
  final List<LatLng> polylinePoints;
  final String distanceText;
  final String durationText;

  DirectionsResult({
    required this.polylinePoints,
    required this.distanceText,
    required this.durationText,
  });
}

class DirectionsService {
  // Same key you pass via --dart-define=MAP_API_KEY=...
  static const _googleApiKey = String.fromEnvironment('MAP_API_KEY');

  static Future<DirectionsResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (_googleApiKey.isEmpty) {
      throw Exception('MAP_API_KEY is not set in dart-define.');
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=driving'
      '&key=$_googleApiKey',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Directions API failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    if (data['status'] != 'OK') {
      throw Exception('Directions API status: ${data['status']}');
    }

    final route = (data['routes'] as List).first;
    final leg = (route['legs'] as List).first;

    final distanceText = leg['distance']['text'] as String;
    final durationText = leg['duration']['text'] as String;

    final polyline = route['overview_polyline']['points'] as String;

    final points = PolylinePoints()
        .decodePolyline(polyline)
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return DirectionsResult(
      polylinePoints: points,
      distanceText: distanceText,
      durationText: durationText,
    );
  }
}
