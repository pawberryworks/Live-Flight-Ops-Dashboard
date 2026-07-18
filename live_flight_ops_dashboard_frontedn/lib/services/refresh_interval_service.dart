import 'dart:convert';

import 'package:http/http.dart' as http;

class RefreshIntervalService {
  RefreshIntervalService({http.Client? client})
    : _client = client ?? http.Client();

  static final Uri _refreshIntervalUri = Uri.https(
    'localhost:7002',
    '/api/refreshInterval',
  );

  final http.Client _client;

  void close() => _client.close();

  Future<Duration> getRefreshInterval() async {
    final response = await _client.get(
      _refreshIntervalUri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw RefreshIntervalException(
        'Could not load the refresh interval (HTTP ${response.statusCode}).',
      );
    }

    try {
      final seconds = jsonDecode(response.body) as int;
      if (seconds <= 0) {
        throw const FormatException('The refresh interval must be positive.');
      }
      return Duration(seconds: seconds);
    } on FormatException catch (error) {
      throw RefreshIntervalException(
        'The backend returned an invalid refresh interval.',
        error,
      );
    } on TypeError catch (error) {
      throw RefreshIntervalException(
        'The backend returned an invalid refresh interval.',
        error,
      );
    }
  }
}

class RefreshIntervalException implements Exception {
  const RefreshIntervalException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
