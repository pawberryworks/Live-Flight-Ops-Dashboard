import '../models/flight_states.dart';
import '../models/geographic_bounds.dart';

abstract interface class FlightStatesRepository {
  Future<FlightStates> getFlightStates();
}

abstract interface class GeographicBoundsRepository {
  Future<GeographicBounds> getGeographicBounds();
}

abstract interface class RefreshIntervalRepository {
  Future<Duration> getRefreshInterval();

  Future<void> updateRefreshInterval(Duration interval);
}

/// An infrastructure resource that needs explicit cleanup.
abstract interface class Disposable {
  void dispose();
}
