import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_flight_ops_dashboard_frontedn/models/aircraft_state.dart';
import 'package:live_flight_ops_dashboard_frontedn/models/geographic_bounds.dart';
import 'package:live_flight_ops_dashboard_frontedn/widgets/geographic_bounds_map.dart';

void main() {
  testWidgets('draws only aircraft with positions inside the map bounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: AircraftMapScope(
            aircraft: [
              _aircraft(icao24: 'inside', latitude: 52, longitude: 13),
              _aircraft(icao24: 'outside', latitude: 40, longitude: 13),
              _aircraft(icao24: 'unknown', latitude: null, longitude: null),
            ],
            child: const GeographicBoundsMap(
              bounds: GeographicBounds(
                latitudeMin: 47,
                latitudeMax: 55,
                longitudeMin: 5,
                longitudeMax: 15,
              ),
              aircraftCount: 3,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('aircraft-inside')), findsOneWidget);
    expect(find.byKey(const ValueKey('aircraft-outside')), findsNothing);
    expect(find.byKey(const ValueKey('aircraft-unknown')), findsNothing);
    expect(find.byIcon(Icons.navigation), findsOneWidget);
    expect(find.bySemanticsLabel('TEST123 • 10000 m'), findsOneWidget);
  });
}

AircraftState _aircraft({
  required String icao24,
  required double? latitude,
  required double? longitude,
}) {
  return AircraftState(
    icao24: icao24,
    callSign: 'TEST123',
    originCountry: 'Germany',
    timePosition: null,
    lastContact: null,
    longitude: longitude,
    latitude: latitude,
    barometricAltitude: 10000,
    onGround: false,
    velocity: 220,
    trueTrack: 90,
    verticalRate: null,
    sensors: null,
    geometricAltitude: null,
    squawk: null,
    spi: false,
    positionSource: 0,
    category: 0,
  );
}
