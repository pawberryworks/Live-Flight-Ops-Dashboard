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

  testWidgets('marks the flight selected on the map', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlightStatesList(
            states: [_aircraft(icao24: 'abc123', originCountry: 'Germany')],
            selectedAircraftIcao24: 'abc123',
          ),
        ),
      ),
    );

    final tile = tester.widget<ListTile>(
      find.byKey(const ValueKey('flight-abc123')),
    );
    expect(tile.selected, isTrue);
    expect(tile.selectedTileColor, isNotNull);
  });

  testWidgets('reports the flight selected from the list', (tester) async {
    String? selectedAircraft;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlightStatesList(
            states: [_aircraft(icao24: 'abc123', originCountry: 'Germany')],
            onAircraftSelected: (icao24) => selectedAircraft = icao24,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('flight-abc123')));

    expect(selectedAircraft, 'abc123');
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
