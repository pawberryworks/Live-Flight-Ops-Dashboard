import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/flight_states.dart';
import '../../models/geographic_bounds.dart';
import '../../repositories/dashboard_repositories.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    required FlightStatesRepository flightStatesRepository,
    required GeographicBoundsRepository geographicBoundsRepository,
    required RefreshIntervalRepository refreshIntervalRepository,
    Iterable<Disposable> resources = const [],
  }) : _flightStatesRepository = flightStatesRepository,
       _geographicBoundsRepository = geographicBoundsRepository,
       _refreshIntervalRepository = refreshIntervalRepository,
       _resources = List.unmodifiable(resources);

  final FlightStatesRepository _flightStatesRepository;
  final GeographicBoundsRepository _geographicBoundsRepository;
  final RefreshIntervalRepository _refreshIntervalRepository;
  final List<Disposable> _resources;

  DashboardState _state = const DashboardState.loading();
  DashboardState get state => _state;

  Timer? _refreshTimer;
  bool _refreshInProgress = false;
  bool _isDisposed = false;
  int _loadGeneration = 0;
  int _errorNotificationId = 0;
  Object? _lastBackendError;

  /// Increments each time a request to the backend fails.
  ///
  /// The UI uses this as an event id so repeated failures with the same error
  /// still result in a visible notification.
  int get errorNotificationId => _errorNotificationId;
  Object? get lastBackendError => _lastBackendError;

  Future<void> load() async {
    final loadGeneration = ++_loadGeneration;
    _refreshTimer?.cancel();
    _setState(const DashboardState.loading());
    try {
      final refreshInterval = await _refreshIntervalRepository.getRefreshInterval();
      final results = await Future.wait<Object>([
        _geographicBoundsRepository.getGeographicBounds(),
        _flightStatesRepository.getFlightStates(),
      ]);
      if (_isDisposed || loadGeneration != _loadGeneration) return;

      _setState(
        DashboardState.ready(
          bounds: results[0] as GeographicBounds,
          flightStates: results[1] as FlightStates,
          refreshInterval: refreshInterval,
        ),
      );
      _startRefreshTimer(refreshInterval);
    } catch (error) {
      if (_isDisposed || loadGeneration != _loadGeneration) return;
      _recordBackendError(error);
      _setState(DashboardState.failure(error));
    }
  }

  Future<void> updateRefreshInterval(Duration interval) async {
    try {
      await _refreshIntervalRepository.updateRefreshInterval(interval);
    } catch (error) {
      _recordBackendError(error);
      rethrow;
    }
    if (_isDisposed || !_state.isReady) return;
    _setState(_state.copyWith(refreshInterval: interval));
    _startRefreshTimer(interval);
  }

  void selectAircraft(String icao24) {
    if (_state.isReady) _setState(_state.copyWith(selectedAircraftIcao24: icao24));
  }

  void clearAircraftSelection() {
    if (_state.isReady) {
      _setState(_state.copyWith(clearSelectedAircraft: true));
    }
  }

  void _startRefreshTimer(Duration interval) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => unawaited(_refreshFlightStates()));
  }

  Future<void> _refreshFlightStates() async {
    if (_isDisposed || !_state.isReady || _refreshInProgress) return;
    _refreshInProgress = true;
    try {
      final flightStates = await _flightStatesRepository.getFlightStates();
      if (!_isDisposed && _state.isReady) {
        _setState(_state.copyWith(flightStates: flightStates));
      }
    } catch (error) {
      // Retain the last successful response and try again at the next interval.
      _recordBackendError(error);
    } finally {
      _refreshInProgress = false;
    }
  }

  void _setState(DashboardState value) {
    if (_isDisposed) return;
    _state = value;
    notifyListeners();
  }

  void _recordBackendError(Object error) {
    if (_isDisposed) return;
    _lastBackendError = error;
    _errorNotificationId++;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadGeneration++;
    _refreshTimer?.cancel();
    for (final resource in _resources) {
      resource.dispose();
    }
    super.dispose();
  }
}

class DashboardState {
  const DashboardState._({
    required this.isLoading,
    this.bounds,
    this.flightStates,
    this.refreshInterval,
    this.selectedAircraftIcao24,
    this.error,
  });

  const DashboardState.loading() : this._(isLoading: true);

  const DashboardState.ready({
    required GeographicBounds bounds,
    required FlightStates flightStates,
    required Duration refreshInterval,
  }) : this._(
         isLoading: false,
         bounds: bounds,
         flightStates: flightStates,
         refreshInterval: refreshInterval,
       );

  const DashboardState.failure(Object error)
    : this._(isLoading: false, error: error);

  final bool isLoading;
  final GeographicBounds? bounds;
  final FlightStates? flightStates;
  final Duration? refreshInterval;
  final String? selectedAircraftIcao24;
  final Object? error;

  bool get isReady => bounds != null && flightStates != null && refreshInterval != null;

  DashboardState copyWith({
    FlightStates? flightStates,
    Duration? refreshInterval,
    String? selectedAircraftIcao24,
    bool clearSelectedAircraft = false,
  }) {
    return DashboardState._(
      isLoading: isLoading,
      bounds: bounds,
      flightStates: flightStates ?? this.flightStates,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      selectedAircraftIcao24: clearSelectedAircraft
          ? null
          : selectedAircraftIcao24 ?? this.selectedAircraftIcao24,
      error: error,
    );
  }
}
