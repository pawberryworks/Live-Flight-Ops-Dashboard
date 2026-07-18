import 'aircraft_state.dart';

class FlightStates {
  const FlightStates({required this.time, required this.states});

  factory FlightStates.fromJson(Map<String, dynamic> json) {
    final states = json['states'] as List<dynamic>?;
    return FlightStates(
      time: (json['time'] as num).toInt(),
      states: states == null
          ? const []
          : states
                .map(
                  (state) => AircraftState.fromJson(state as List<dynamic>),
                )
                .toList(growable: false),
    );
  }

  final int time;
  final List<AircraftState> states;
}
