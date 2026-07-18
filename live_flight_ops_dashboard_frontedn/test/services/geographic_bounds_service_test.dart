import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:live_flight_ops_dashboard_frontedn/services/geographic_bounds_service.dart';

void main() {
  test('loads geographic bounds from the backend', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        '''{
          "latitudeMin": 47.1,
          "latitudeMax": 55.2,
          "longitudeMin": 5.8,
          "longitudeMax": 15.0
        }''',
        200,
      );
    });
    final service = GeographicBoundsService(client: client);

    final bounds = await service.getGeographicBounds();

    expect(capturedRequest.method, 'GET');
    expect(
      capturedRequest.url,
      Uri.parse('https://localhost:7002/api/geographicBounds'),
    );
    expect(capturedRequest.headers['Accept'], 'application/json');
    expect(bounds.latitudeMin, 47.1);
    expect(bounds.latitudeMax, 55.2);
    expect(bounds.longitudeMin, 5.8);
    expect(bounds.longitudeMax, 15.0);
  });

  test('reports a non-successful backend response', () async {
    final service = GeographicBoundsService(
      client: MockClient((_) async => http.Response('Unavailable', 503)),
    );

    expect(
      service.getGeographicBounds(),
      throwsA(
        isA<GeographicBoundsException>().having(
          (error) => error.message,
          'message',
          contains('HTTP 503'),
        ),
      ),
    );
  });
}
