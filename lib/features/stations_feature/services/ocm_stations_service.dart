import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/ocm_station.dart';

const String _ocmBaseUrl = 'https://api.openchargemap.io/v3/poi';

// Read from --dart-define OCM_API_KEY (configured in secrets/dev.json)
const String _ocmApiKey = String.fromEnvironment('OCM_API_KEY');

Future<List<OcmStation>> fetchOcmStationsNearby({
  required double latitude,
  required double longitude,
  double distanceKm = 10,
}) async {
  final uri = Uri.parse(
    '$_ocmBaseUrl'
    '?output=json'
    '&key=$_ocmApiKey'
    '&latitude=$latitude'
    '&longitude=$longitude'
    '&distance=$distanceKm'
    '&distanceunit=KM',
  );

  print('OCM URL: $uri');

  final resp = await http.get(
    uri,
    headers: {
      'User-Agent': 'EvolveEVApp/1.0 (julian.florentino@tup.edu.ph)',
    },
  );

  if (resp.statusCode != 200) {
    throw Exception(
      'Failed to load OCM stations: ${resp.statusCode} ${resp.body}',
    );
  }

  final List<dynamic> raw = json.decode(resp.body) as List<dynamic>;
  return raw.whereType<Map<String, dynamic>>().map(OcmStation.fromJson).toList();
}
