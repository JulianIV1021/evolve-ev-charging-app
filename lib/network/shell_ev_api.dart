import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class ShellEvApi {
  final Dio _dio;

  ShellEvApi(this._dio);

  // TODO: Move secrets out of the app for production use.
  static const String _clientId = 'G3FcYRxkeMu26P8UTWHHjw1lNCBJaeAE';
  static const String _clientSecret = '3NDs7bax4o63ekKK';

  static const String _authUrl = 'https://api-test.shell.com/v1/oauth/token';
  static const String _baseLocationsUrl =
      'https://api-test.shell.com/locations/v1';

  /// Get OAuth2 access token from Shell using client_credentials.
  Future<String> _getAccessToken() async {
    final response = await _dio.post(
      _authUrl,
      data: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'grant_type': 'client_credentials',
      },
      options: Options(
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      if (token == null) {
        throw Exception('Shell token response missing access_token');
      }
      return token;
    } else {
      throw Exception(
        'Failed to get Shell access token: '
        '${response.statusCode} ${response.statusMessage}',
      );
    }
  }

  /// Call /ev/nearby to get stations near a given lat/lng.
  Future<List<dynamic>> getNearbyLocations({
    required double latitude,
    required double longitude,
  }) async {
    final token = await _getAccessToken();
    final requestId = const Uuid().v4(); // unique per request

    final response = await _dio.get(
      '$_baseLocationsUrl/ev/nearby',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'RequestId': requestId,
          'Accept': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      final body = response.data as Map<String, dynamic>;
      if (body['status'] != 'SUCCESS') {
        throw Exception('Shell EV API returned status: ${body['status']}');
      }
      final data = body['data'] as List<dynamic>?;

      return data ?? <dynamic>[];
    } else {
      throw Exception(
        'Failed to fetch Shell EV locations: '
        '${response.statusCode} ${response.statusMessage}',
      );
    }
  }
}
