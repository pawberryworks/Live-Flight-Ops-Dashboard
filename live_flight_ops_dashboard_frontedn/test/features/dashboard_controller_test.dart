import 'package:flutter_test/flutter_test.dart';
import 'package:live_flight_ops_dashboard_frontedn/features/dashboard/dashboard_controller.dart';
import 'package:live_flight_ops_dashboard_frontedn/models/aircraft_state.dart';
import 'package:live_flight_ops_dashboard_frontedn/models/flight_states.dart';
import 'package:live_flight_ops_dashboard_frontedn/models/geographic_bounds.dart';
import 'package:live_flight_ops_dashboard_frontedn/repositories/dashboard_repositories.dart';

void main() {
  test('loads dashboard data through repositories and exposes ready state', () async {
    final flightStates = _flightStates('abc123');
    final controller = DashboardController(
      flightStatesRepository: _FlightStatesRepository(flightStates),
      geographicBoundsRepository: _GeographicBoundsRepository(),
      refreshIntervalRepository: _RefreshIntervalRepository(),
    );

    await controller.load();

    expect(controller.state.isReady, isTrue);
    expect(controller.state.flightStates, same(flightStates));
    expect(controller.state.refreshInterval, const Duration(seconds: 10));

    controller.selectAircraft('abc123');
    expect(controller.state.selectedAircraftIcao24, 'abc123');
    controller.clearAircraftSelection();
    expect(controller.state.selectedAircraftIcao24, isNull);
    controller.dispose();
  });

  test('updates the repository and restarts state with the selected interval', () async {
    final refreshRepository = _RefreshIntervalRepository();
    final controller = DashboardController(
      flightStatesRepository: _FlightStatesRepository(_flightStates('abc123')),
      geographicBoundsRepository: _GeographicBoundsRepository(),
      refreshIntervalRepository: refreshRepository,
    );
    await controller.load();

    await controller.updateRefreshInterval(const Duration(seconds: 20));

    expect(refreshRepository.updatedInterval, const Duration(seconds: 20));
    expect(controller.state.refreshInterval, const Duration(seconds: 20));
    controller.dispose();
  });
}

class _FlightStatesRepository implements FlightStatesRepository {
  _FlightStatesRepository(this.value);

  final FlightStates value;

  @override
  void close() {}

  @override
  Future<FlightStates> getFlightStates() async => value;
}

class _GeographicBoundsRepository implements GeographicBoundsRepository {
  @override
  void close() {}

  @override
  Future<GeographicBounds> getGeographicBounds() async => const GeographicBounds(
    latitudeMin: 47,
    latitudeMax: 55,
    longitudeMin: 5,
    longitudeMax: 15,
  );
}

class _RefreshIntervalRepository implements RefreshIntervalRepository {
  Duration? updatedInterval;

  @override
  void close() {}

  @override
  Future<Duration> getRefreshInterval() async => const Duration(seconds: 10);

  @override
  Future<void> updateRefreshInterval(Duration interval) async {
    updatedInterval = interval;
  }
}

FlightStates _flightStates(String icao24) => FlightStates(
  time: 1,
  states: [
    AircraftState(
      icao24: icao24,
      callSign: 'TEST',
      originCountry: 'Germany',
      timePosition: null,
      lastContact: null,
      longitude: 13,
      latitude: 52,
      barometricAltitude: null,
      onGround: false,
      velocity: null,
      trueTrack: null,
      verticalRate: null,
      sensors: null,
      geometricAltitude: null,
      squawk: null,
      spi: false,
      positionSource: 0,
      category: 0,
    ),
  ],
);
