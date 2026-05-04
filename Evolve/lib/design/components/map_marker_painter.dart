import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Loads pre-rendered marker PNGs from assets instead of painting at runtime,
/// eliminating GPU rasteriser calls (picture.toImage) that caused multi-second
/// frame freezes on first load.
class MapMarkerPainter {
  static Future<BitmapDescriptor> _load(String assetPath) {
    return BitmapDescriptor.asset(
      const ImageConfiguration(),
      assetPath,
      width: 48,
      height: 48,
    );
  }

  static Future<Map<String, BitmapDescriptor>> preloadAll() async {
    final results = await Future.wait([
      _load('assets/markers/marker_green.png'),
      _load('assets/markers/marker_orange.png'),
      _load('assets/markers/marker_grey.png'),
    ]);
    return {
      'available': results[0],
      'busy': results[1],
      'offline': results[2],
    };
  }
}
