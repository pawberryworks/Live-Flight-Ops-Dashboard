import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_flight_ops_dashboard_frontedn/models/aircraft_state.dart';
import 'package:live_flight_ops_dashboard_frontedn/models/geographic_bounds.dart';
import 'package:live_flight_ops_dashboard_frontedn/widgets/flight_states_table.dart';

void main() {
  const bounds = GeographicBounds(
    latitudeMin: 47,
    latitudeMax: 55,
    longitudeMin: 5,
    longitudeMax: 15,
  );

  testWidgets('shows all flights and filters individual columns', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlightStatesTable(
            bounds: bounds,
            states: [
              _aircraft('abc123', 'DLH123', 'Germany'),
              _aircraft('def456', 'AFR456', 'France'),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('flight-row-abc123')), findsOneWidget);
    expect(find.byKey(const ValueKey('flight-row-def456')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('filter-country')),
      'germ',
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('flight-row-abc123')), findsOneWidget);
    expect(find.byKey(const ValueKey('flight-row-def456')), findsNothing);
    expect(find.text('1 of 2'), findsOneWidget);
  });

  testWidgets('opens a map dialog containing only the selected flight', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlightStatesTable(
            bounds: bounds,
            states: [
              _aircraft('abc123', 'DLH123', 'Germany'),
              _aircraft('def456', 'AFR456', 'France'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('show-map-abc123')));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('DLH123 on map'), findsOneWidget);
    expect(find.byKey(const ValueKey('aircraft-abc123')), findsOneWidget);
    expect(find.byKey(const ValueKey('aircraft-def456')), findsNothing);
  });

  testWidgets('only builds the current page of a large flight list', (
    tester,
  ) async {
    final states = List.generate(
      30,
      (index) => _aircraft(
        'icao${index.toString().padLeft(2, '0')}',
        'CALL$index',
        'Germany',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlightStatesTable(bounds: bounds, states: states),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('flight-row-icao00')), findsOneWidget);
    expect(find.byKey(const ValueKey('flight-row-icao24')), findsOneWidget);
    expect(find.byKey(const ValueKey('flight-row-icao25')), findsNothing);
    expect(find.text('1–25 of 30'), findsOneWidget);

    await tester.tap(find.byTooltip('Next page'));
    await tester.pump();

    expect(find.byKey(const ValueKey('flight-row-icao00')), findsNothing);
    expect(find.byKey(const ValueKey('flight-row-icao25')), findsOneWidget);
    expect(find.text('26–30 of 30'), findsOneWidget);
  });
}

AircraftState _aircraft(String icao24, String callSign, String country) {
  return AircraftState(
    icao24: icao24,
    callSign: callSign,
    originCountry: country,
    timePosition: null,
    lastContact: null,
    longitude: 13.4,
    latitude: 52.5,
    barometricAltitude: 10000,
    onGround: false,
    velocity: 220,
    trueTrack: 90,
    verticalRate: 1.5,
    sensors: null,
    geometricAltitude: null,
    squawk: '1234',
    spi: false,
    positionSource: 0,
    category: 0,
  );
}
