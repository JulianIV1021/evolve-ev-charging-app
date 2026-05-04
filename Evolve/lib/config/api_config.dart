/// Central configuration for external API keys.
///
/// SETUP REQUIRED:
/// 1. Replace [googleMapsApiKey] with your key from Google Cloud Console.
///    Enabled APIs: Maps SDK for Android/iOS, Directions API.
/// 2. Add the same key to android/app/src/main/AndroidManifest.xml
///    and ios/Runner/AppDelegate.swift (GMSServices.provideAPIKey).
class ApiConfig {
  ApiConfig._();

  /// Google Maps / Directions API key.
  static const String googleMapsApiKey = 'AIzaSyCPO7HTBbv9b_FwGVUQylLJCnSIXehulhg';

  /// Directions API base URL.
  static const String directionsBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  /// EV energy consumption default (Wh/km) — used when vehicle profile
  /// doesn't provide a more specific value.
  static const double defaultConsumptionWhPerKm = 180.0;

  /// CO₂ grid emission factor (g/kWh) — Philippine grid average.
  static const double co2GramsPerKwh = 400.0;

  /// Minimum arrival SoC buffer enforced by green routing (10%).
  static const double minArrivalSocPercent = 0.10;
}
