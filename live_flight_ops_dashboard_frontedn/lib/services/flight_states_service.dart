import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/flight_states.dart';

class FlightStatesService {
  FlightStatesService({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _flightStatesUri = Uri.https(
    'localhost:7002',
    '/api/flightStates',
  );

  final http.Client _client;

  void close() => _client.close();

  Future<FlightStates> getFlightStates() async {
    final response = await _client.get(
      _flightStatesUri,
      headers: const {'Accept': 'application/json'},
    );

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
