import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:live_flight_ops_dashboard_frontedn/services/refresh_interval_service.dart';

void main() {
  test('loads the refresh interval from the backend', () async {
    late http.Request capturedRequest;
    final service = RefreshIntervalService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('10', 200);
      }),
    );

    final interval = await service.getRefreshInterval();

    expect(capturedRequest.method, 'GET');
    expect(
      capturedRequest.url,
      Uri.parse('https://localhost:7002/api/refreshInterval'),
    );
    expect(capturedRequest.headers['Accept'], 'application/json');
    expect(interval, const Duration(seconds: 10));
  });

  test('reports a non-successful backend response', () async {
    final service = RefreshIntervalService(
      client: MockClient((_) async => http.Response('Unavailable', 503)),
    );

    expect(
      service.getRefreshInterval(),
      throwsA(
        isA<RefreshIntervalException>().having(
          (error) => error.message,
          'message',
          contains('HTTP 503'),
        ),
      ),
    );
  });

  for (final invalidResponse in ['0', '-1', '"10"', '{}']) {
    test('reports invalid refresh interval $invalidResponse', () async {
      final service = RefreshIntervalService(
        client: MockClient((_) async => http.Response(invalidResponse, 200)),
      );

      expect(
        service.getRefreshInterval(),
        throwsA(isA<RefreshIntervalException>()),
      );
    });
  }
}
