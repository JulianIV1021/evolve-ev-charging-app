import 'package:flutter/foundation.dart';

import '../models/ocm_station.dart';

/// Simple bridge to request the map screen to focus on a station.
class StationFocusBus {
  StationFocusBus._();

  static final StationFocusBus instance = StationFocusBus._();

  /// When set to a station, the map screen should center + open sheet, then clear.
  final ValueNotifier<OcmStation?> target = ValueNotifier<OcmStation?>(null);

  void focus(OcmStation station) {
    target.value = station;
  }

  void clear() {
    target.value = null;
  }
}
