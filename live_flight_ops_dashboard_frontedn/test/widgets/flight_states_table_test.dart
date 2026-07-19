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
    expect(
      tester.widget<DataTable>(find.byType(DataTable)).showCheckboxColumn,
      isFalse,
    );

    await tester.enterText(
      find.byKey(const ValueKey('filter-origin-country')),
      'germ',
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('flight-row-abc123')), findsOneWidget);
    expect(find.byKey(const ValueKey('flight-row-def456')), findsNothing);
    expect(find.text('1 of 2'), findsOneWidget);
  });

  testWidgets('opens a flight details dialog when a row is selected', (
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

    await tester.tap(find.byKey(const ValueKey('flight-row-abc123')));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('DLH123 flight details'), findsOneWidget);
    expect(find.text('Time position'), findsOneWidget);
    expect(find.text('Altitude'), findsOneWidget);
    expect(find.text('10000.0 m'), findsOneWidget);
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

  testWidgets('supports horizontal scrolling through all columns', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: FlightStatesTable(
              bounds: bounds,
              states: [_aircraft('abc123', 'DLH123', 'Germany')],
            ),
          ),
        ),
      ),
    );

    final scrollbar = tester.widget<Scrollbar>(
      find.byKey(const ValueKey('flight-table-horizontal-scrollbar')),
    );
    expect(scrollbar.thumbVisibility, isTrue);
    expect(scrollbar.trackVisibility, isTrue);
    expect(scrollbar.interactive, isTrue);

    final scrollFinder = find.byKey(
      const ValueKey('flight-table-horizontal-scroll'),
    );
    final scrollView = tester.widget<SingleChildScrollView>(scrollFinder);
    expect(scrollView.controller!.position.maxScrollExtent, greaterThan(0));

    await tester.drag(scrollFinder, const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(scrollView.controller!.offset, greaterThan(0));
  });

  testWidgets('sorts each data column in ascending and descending order', (
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

    expect(find.byIcon(Icons.keyboard_arrow_up), findsNWidgets(6));
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNWidgets(6));

    await tester.tap(find.byTooltip('Sort Origin country ascending'));
    await tester.pump();

    var table = tester.widget<DataTable>(find.byType(DataTable));
    expect(find.byIcon(Icons.keyboard_arrow_up), findsNWidgets(6));
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNWidgets(5));
    expect(
      table.rows.map((row) => row.key),
      [
        const ValueKey('flight-row-def456'),
        const ValueKey('flight-row-abc123'),
      ],
    );

    await tester.tap(
      find.byTooltip('Sorted Origin country ascending; sort descending'),
    );
    await tester.pump();

    table = tester.widget<DataTable>(find.byType(DataTable));
    expect(find.byIcon(Icons.keyboard_arrow_up), findsNWidgets(5));
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNWidgets(6));
    expect(
      table.rows.map((row) => row.key),
      [
        const ValueKey('flight-row-abc123'),
        const ValueKey('flight-row-def456'),
      ],
    );
  });

  testWidgets('sorts numeric columns by their numeric values', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlightStatesTable(
            bounds: bounds,
            states: [
              _aircraft('high', 'HIGH', 'Germany', longitude: 10000),
              _aircraft('low', 'LOW', 'France', longitude: 900),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Sort Longitude ascending'));
    await tester.pump();

    final table = tester.widget<DataTable>(find.byType(DataTable));
    expect(
      table.rows.map((row) => row.key),
      [const ValueKey('flight-row-low'), const ValueKey('flight-row-high')],
    );
  });
}

AircraftState _aircraft(
  String icao24,
  String callSign,
  String country, {
  double longitude = 13.4,
}) {
  return AircraftState(
    icao24: icao24,
    callSign: callSign,
    originCountry: country,
    timePosition: null,
    lastContact: null,
    longitude: longitude,
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
