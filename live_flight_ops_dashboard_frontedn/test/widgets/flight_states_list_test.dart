import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_flight_ops_dashboard_frontedn/models/aircraft_state.dart';
import 'package:live_flight_ops_dashboard_frontedn/widgets/flight_states_list.dart';

void main() {
  testWidgets('shows every tracked flight and its count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlightStatesList(
            states: [
              _aircraft(callSign: 'DLH123', originCountry: 'Germany'),
              _aircraft(icao24: 'abc456', originCountry: 'France'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Tracked flights'), findsOneWidget);
    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('DLH123'), findsOneWidget);
    expect(find.text('ABC456'), findsOneWidget);
    expect(find.textContaining('Germany'), findsOneWidget);
    expect(find.textContaining('France'), findsOneWidget);
  });

  testWidgets('shows an empty state when no flights are tracked', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FlightStatesList(states: [])),
      ),
    );

    expect(find.text('No flights are currently tracked.'), findsOneWidget);
  });
}

AircraftState _aircraft({
  String icao24 = 'abc123',
  String callSign = '',
  required String originCountry,
}) {
  return AircraftState(
    icao24: icao24,
    callSign: callSign,
    originCountry: originCountry,
    timePosition: null,
    lastContact: null,
    longitude: 13.4,
    latitude: 52.5,
    barometricAltitude: 10000,
    onGround: false,
    velocity: 220,
    trueTrack: null,
    verticalRate: null,
    sensors: null,
    geometricAltitude: null,
    squawk: null,
    spi: false,
    positionSource: 0,
    category: 0,
  );
}
