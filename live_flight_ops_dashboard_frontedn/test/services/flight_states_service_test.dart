import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:live_flight_ops_dashboard_frontedn/services/flight_states_service.dart';

void main() {
  test('loads flight states from the backend', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        '''{
          "time": 1721304000,
          "states": [[
            "abc123", " TEST123 ", "Germany", 1721303990, 1721303999,
            13.4, 52.5, 10000.5, false, 220.4, 91.2, -2.1,
            [1, 2], 10200.0, "7000", true, 1, 3
          ]]
        }''',
        200,
      );
    });
    final service = FlightStatesService(client: client);

    final flightStates = await service.getFlightStates();

    expect(capturedRequest.method, 'GET');
    expect(
      capturedRequest.url,
      Uri.parse('https://localhost:7002/api/flightStates'),
    );
    expect(capturedRequest.headers['Accept'], 'application/json');
    expect(flightStates.time, 1721304000);
    expect(flightStates.states, hasLength(1));
    final aircraft = flightStates.states.single;
    expect(aircraft.icao24, 'abc123');
    expect(aircraft.callSign, 'TEST123');
    expect(aircraft.longitude, 13.4);
    expect(aircraft.latitude, 52.5);
    expect(aircraft.sensors, [1, 2]);
    expect(aircraft.spi, isTrue);
    expect(aircraft.category, 3);
  });

  test('converts a null states collection to an empty list', () async {
    final service = FlightStatesService(
      client: MockClient(
        (_) async => http.Response('{"time": 1721304000, "states": null}', 200),
      ),
    );

    final flightStates = await service.getFlightStates();

    expect(flightStates.states, isEmpty);
  });

  test('reports a non-successful backend response', () async {
    final service = FlightStatesService(
      client: MockClient((_) async => http.Response('Unavailable', 503)),
    );

    expect(
      service.getFlightStates(),
      throwsA(
        isA<FlightStatesException>().having(
          (error) => error.message,
          'message',
          contains('HTTP 503'),
        ),
      ),
    );
  });

  test('reports malformed flight state data', () async {
    final service = FlightStatesService(
      client: MockClient(
        (_) async => http.Response('{"time": 1, "states": [["abc123"]]}', 200),
      ),
    );

    expect(service.getFlightStates(), throwsA(isA<FlightStatesException>()));
  });
}
