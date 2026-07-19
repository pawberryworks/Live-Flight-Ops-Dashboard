import '../models/flight_states.dart';
import '../models/geographic_bounds.dart';

abstract interface class FlightStatesRepository {
  Future<FlightStates> getFlightStates();

  void close();
}

abstract interface class GeographicBoundsRepository {
  Future<GeographicBounds> getGeographicBounds();

  void close();
}

abstract interface class RefreshIntervalRepository {
  Future<Duration> getRefreshInterval();

  Future<void> updateRefreshInterval(Duration interval);

  void close();
}
