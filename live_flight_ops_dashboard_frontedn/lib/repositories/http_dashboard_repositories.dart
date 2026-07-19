import '../models/flight_states.dart';
import '../models/geographic_bounds.dart';
import '../services/flight_states_service.dart';
import '../services/geographic_bounds_service.dart';
import '../services/refresh_interval_service.dart';
import 'dashboard_repositories.dart';

class HttpFlightStatesRepository implements FlightStatesRepository {
  HttpFlightStatesRepository(this._service);

  final FlightStatesService _service;

  @override
  Future<FlightStates> getFlightStates() => _service.getFlightStates();

  @override
  void close() => _service.close();
}

class HttpGeographicBoundsRepository implements GeographicBoundsRepository {
  HttpGeographicBoundsRepository(this._service);

  final GeographicBoundsService _service;

  @override
  Future<GeographicBounds> getGeographicBounds() =>
      _service.getGeographicBounds();

  @override
  void close() => _service.close();
}

class HttpRefreshIntervalRepository implements RefreshIntervalRepository {
  HttpRefreshIntervalRepository(this._service);

  final RefreshIntervalService _service;

  @override
  Future<Duration> getRefreshInterval() => _service.getRefreshInterval();

  @override
  Future<void> updateRefreshInterval(Duration interval) =>
      _service.updateRefreshInterval(interval);

  @override
  void close() => _service.close();
}
