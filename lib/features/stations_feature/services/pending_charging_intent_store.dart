import 'package:flutter/foundation.dart';

class PendingChargingIntent {
  final String stationId;
  final String stationName;
  final String coordinates;
  final double latitude;
  final double longitude;
  final String? address;
  final String connectorLabel;
  final double tariffPerKwh;
  final double chargingSpeed;
  final double amperage;
  final double voltage;

  const PendingChargingIntent({
    required this.stationId,
    required this.stationName,
    required this.coordinates,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.connectorLabel,
    required this.tariffPerKwh,
    required this.chargingSpeed,
    required this.amperage,
    required this.voltage,
  });
}

class PendingChargingIntentStore {
  PendingChargingIntentStore._();
  static final PendingChargingIntentStore instance =
      PendingChargingIntentStore._();

  final ValueNotifier<PendingChargingIntent?> notifier =
      ValueNotifier<PendingChargingIntent?>(null);

  void setIntent(PendingChargingIntent intent) {
    notifier.value = intent;
  }

  void clear() {
    notifier.value = null;
  }
}
