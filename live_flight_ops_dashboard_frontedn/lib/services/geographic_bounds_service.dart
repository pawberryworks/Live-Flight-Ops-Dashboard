import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_configuration.dart';
import '../models/geographic_bounds.dart';

class GeographicBoundsService {
  factory GeographicBoundsService({
    http.Client? client,
    ApiConfiguration? configuration,
    Duration requestTimeout = const Duration(seconds: 15),
  }) => GeographicBoundsService._(
    client ?? http.Client(),
    (configuration ?? ApiConfiguration.fromEnvironment()).endpoint(
      '/api/geographicBounds',
    ),
    requestTimeout,
  );

  GeographicBoundsService._(
    this._client,
    this._geographicBoundsUri,
    this._requestTimeout,
  );

  final http.Client _client;
  final Uri _geographicBoundsUri;
  final Duration _requestTimeout;

  void close() => _client.close();

  Future<GeographicBounds> getGeographicBounds() async {
    late http.Response response;
    try {
      response = await _client
          .get(
            _geographicBoundsUri,
            headers: const {'Accept': 'application/json'},
          )
          .timeout(_requestTimeout);
    } on TimeoutException catch (error) {
      throw GeographicBoundsException(
        'Timed out while loading geographic bounds.',
        error,
      );
    }

    if (response.statusCode != 200) {
      throw GeographicBoundsException(
        'Could not load geographic bounds (HTTP ${response.statusCode}).',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return GeographicBounds.fromJson(json);
    } on FormatException catch (error) {
      throw GeographicBoundsException(
        'The backend returned invalid geographic bounds.',
        error,
      );
    } on TypeError catch (error) {
      throw GeographicBoundsException(
        'The backend returned invalid geographic bounds.',
        error,
      );
    }
  }
}

class GeographicBoundsException implements Exception {
  const GeographicBoundsException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
