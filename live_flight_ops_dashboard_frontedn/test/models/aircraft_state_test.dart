import 'package:flutter_test/flutter_test.dart';
import 'package:live_flight_ops_dashboard_frontedn/models/aircraft_state.dart';

void main() {
  test('maps the nullable backend aircraft state contract', () {
    final state = AircraftState.fromJson([
      'abc123',
      ' TEST123 ',
      'Germany',
      null,
      null,
      null,
      null,
      null,
      false,
      null,
      null,
      null,
      null,
      null,
      null,
      false,
      0,
      0,
    ]);

    expect(state.icao24, 'abc123');
    expect(state.callSign, 'TEST123');
    expect(state.originCountry, 'Germany');
    expect(state.timePosition, isNull);
    expect(state.lastContact, isNull);
    expect(state.longitude, isNull);
    expect(state.latitude, isNull);
    expect(state.barometricAltitude, isNull);
    expect(state.velocity, isNull);
    expect(state.trueTrack, isNull);
    expect(state.verticalRate, isNull);
    expect(state.sensors, isNull);
    expect(state.geometricAltitude, isNull);
    expect(state.squawk, isNull);
    expect(state.onGround, isFalse);
    expect(state.spi, isFalse);
    expect(state.positionSource, 0);
    expect(state.category, 0);
  });

  test('ignores invalid nullable values instead of failing the response', () {
    final state = AircraftState.fromJson([
      null,
      null,
      null,
      'invalid',
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      [1, null, 'invalid', 2.0],
      null,
      1234,
      null,
      null,
      null,
    ]);

    expect(state.icao24, isEmpty);
    expect(state.callSign, isEmpty);
    expect(state.originCountry, isEmpty);
    expect(state.timePosition, isNull);
    expect(state.sensors, [1, 2]);
    expect(state.squawk, isNull);
    expect(state.onGround, isFalse);
    expect(state.spi, isFalse);
    expect(state.positionSource, 0);
    expect(state.category, 0);
  });
}
