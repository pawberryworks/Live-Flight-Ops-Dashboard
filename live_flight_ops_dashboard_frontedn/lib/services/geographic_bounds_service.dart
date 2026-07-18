import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/geographic_bounds.dart';

class GeographicBoundsService {
  GeographicBoundsService({http.Client? client})
    : _client = client ?? http.Client();

  static final Uri _geographicBoundsUri = Uri.https(
    'localhost:7002',
    '/api/geographicBounds',
  );

  final http.Client _client;

  void close() => _client.close();

  Future<GeographicBounds> getGeographicBounds() async {
    final response = await _client.get(
      _geographicBoundsUri,
      headers: const {'Accept': 'application/json'},
    );

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
