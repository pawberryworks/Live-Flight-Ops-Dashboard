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
            selectedAircraftIcao24: null,
            onAircraftSelected: (_) {},
            onAircraftDeselected: () {},
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

    expect(
      find.byKey(const ValueKey('aircraft-marker-layer')),
      findsOneWidget,
    );
    final overlay = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('map-dark-overlay')),
    );
    expect(overlay.color, Colors.black.withValues(alpha: 0.32));
    expect(find.bySemanticsLabel('TEST123 • 10000 m'), findsOneWidget);
  });

  testWidgets('reports the aircraft selected on the map', (tester) async {
    String? selectedAircraft;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: AircraftMapScope(
            aircraft: [
              _aircraft(icao24: 'abc123', latitude: 52, longitude: 13),
            ],
            selectedAircraftIcao24: null,
            onAircraftSelected: (icao24) => selectedAircraft = icao24,
            onAircraftDeselected: () {},
            child: const GeographicBoundsMap(
              bounds: GeographicBounds(
                latitudeMin: 47,
                latitudeMax: 55,
                longitudeMin: 5,
                longitudeMax: 15,
              ),
              aircraftCount: 1,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('TEST123 • 10000 m'));

    expect(selectedAircraft, 'abc123');
  });

  testWidgets('clears the selection when an aircraft is double tapped', (
    tester,
  ) async {
    var selectionCleared = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: AircraftMapScope(
            aircraft: [
              _aircraft(icao24: 'abc123', latitude: 52, longitude: 13),
            ],
            selectedAircraftIcao24: 'abc123',
            onAircraftSelected: (_) {},
            onAircraftDeselected: () => selectionCleared = true,
            child: const GeographicBoundsMap(
              bounds: GeographicBounds(
                latitudeMin: 47,
                latitudeMax: 55,
                longitudeMin: 5,
                longitudeMax: 15,
              ),
              aircraftCount: 1,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('TEST123 • 10000 m'));
    await tester.tap(find.bySemanticsLabel('TEST123 • 10000 m'));
    await tester.pumpAndSettle();

    expect(selectionCleared, isTrue);
  });

  testWidgets('keeps the map rendered while the app theme changes', (
    tester,
  ) async {
    var themeMode = ThemeMode.light;
    late StateSetter updateApp;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          updateApp = setState;
          return MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeMode,
            home: SizedBox(
              width: 800,
              height: 600,
              child: AircraftMapScope(
                aircraft: [
                  _aircraft(icao24: 'abc123', latitude: 52, longitude: 13),
                ],
                selectedAircraftIcao24: null,
                onAircraftSelected: (_) {},
                onAircraftDeselected: () {},
                child: const GeographicBoundsMap(
                  bounds: GeographicBounds(
                    latitudeMin: 47,
                    latitudeMax: 55,
                    longitudeMin: 5,
                    longitudeMax: 15,
                  ),
                  aircraftCount: 1,
                ),
              ),
            ),
          );
        },
      ),
    );

    updateApp(() => themeMode = ThemeMode.dark);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('TEST123 • 10000 m'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
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
