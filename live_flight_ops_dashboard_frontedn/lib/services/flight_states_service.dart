import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_configuration.dart';
import '../models/flight_states.dart';

class FlightStatesService {
  factory FlightStatesService({
    http.Client? client,
    ApiConfiguration? configuration,
    Duration requestTimeout = const Duration(seconds: 15),
  }) => FlightStatesService._(
    client ?? http.Client(),
    (configuration ?? ApiConfiguration.fromEnvironment()).endpoint(
      '/api/flightStates',
    ),
    requestTimeout,
  );

  FlightStatesService._(
    this._client,
    this._flightStatesUri,
    this._requestTimeout,
  );

  final http.Client _client;
  final Uri _flightStatesUri;
  final Duration _requestTimeout;

  void close() => _client.close();

  Future<FlightStates> getFlightStates() async {
    late http.Response response;
    try {
      response = await _client
          .get(_flightStatesUri, headers: const {'Accept': 'application/json'})
          .timeout(_requestTimeout);
    } on TimeoutException catch (error) {
      throw FlightStatesException('Timed out while loading flight states.', error);
    }

    if (response.statusCode != 200) {
      throw FlightStatesException(
        'Could not load flight states (HTTP ${response.statusCode}).',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return FlightStates.fromJson(json);
    } on FormatException catch (error) {
      throw FlightStatesException(
        'The backend returned invalid flight states.',
        error,
      );
    } on TypeError catch (error) {
      throw FlightStatesException(
        'The backend returned invalid flight states.',
        error,
      );
    }
  }
}

class FlightStatesException implements Exception {
  const FlightStatesException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
