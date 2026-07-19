import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_configuration.dart';

class RefreshIntervalService {
  RefreshIntervalService({
    http.Client? client,
    ApiConfiguration? configuration,
    Duration requestTimeout = const Duration(seconds: 15),
  })
    : _client = client ?? http.Client(),
      _refreshIntervalUri =
          (configuration ?? ApiConfiguration.fromEnvironment()).endpoint(
            '/api/refreshInterval',
          ),
      _requestTimeout = requestTimeout;

  final http.Client _client;
  final Uri _refreshIntervalUri;
  final Duration _requestTimeout;

  void close() => _client.close();

  Future<Duration> getRefreshInterval() async {
    late http.Response response;
    try {
      response = await _client
          .get(
            _refreshIntervalUri,
            headers: const {'Accept': 'application/json'},
          )
          .timeout(_requestTimeout);
    } on TimeoutException catch (error) {
      throw RefreshIntervalException(
        'Timed out while loading the refresh interval.',
        error,
      );
    }

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

  Future<void> updateRefreshInterval(Duration interval) async {
    final seconds = interval.inSeconds;
    if (seconds <= 0 || interval != Duration(seconds: seconds)) {
      throw const RefreshIntervalException(
        'The refresh interval must be a positive whole number of seconds.',
      );
    }

    late http.Response response;
    try {
      response = await _client
          .put(
            _refreshIntervalUri.replace(
              path: '${_refreshIntervalUri.path}/$seconds',
            ),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(_requestTimeout);
    } on TimeoutException catch (error) {
      throw RefreshIntervalException(
        'Timed out while updating the refresh interval.',
        error,
      );
    }

    if (response.statusCode != 204) {
      throw RefreshIntervalException(
        'Could not update the refresh interval (HTTP ${response.statusCode}).',
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
