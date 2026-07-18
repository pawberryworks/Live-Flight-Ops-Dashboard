import 'package:flutter/material.dart';

import '../models/aircraft_state.dart';

class FlightStatesList extends StatelessWidget {
  const FlightStatesList({
    required this.states,
    this.selectedAircraftIcao24,
    this.onAircraftSelected,
    super.key,
  });

  final List<AircraftState> states;
  final String? selectedAircraftIcao24;
  final ValueChanged<String>? onAircraftSelected;

  @override
  Widget build(BuildContext context) {
    final selectAircraft = onAircraftSelected;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tracked flights',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Badge.count(count: states.length),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: states.isEmpty
                ? const Center(child: Text('No flights are currently tracked.'))
                : ListView.separated(
                    itemCount: states.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) => _FlightListItem(
                      state: states[index],
                      isSelected:
                          states[index].icao24 == selectedAircraftIcao24,
                      onTap: selectAircraft == null
                          ? null
                          : () => selectAircraft(states[index].icao24),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FlightListItem extends StatelessWidget {
  const _FlightListItem({
    required this.state,
    required this.isSelected,
    required this.onTap,
  });

  final AircraftState state;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final callSign = state.callSign.isEmpty
        ? state.icao24.toUpperCase()
        : state.callSign;
    final altitude = state.barometricAltitude;
    final velocity = state.velocity;

    return Semantics(
      label: 'Flight $callSign from ${state.originCountry}',
      selected: isSelected,
      child: ListTile(
        key: ValueKey('flight-${state.icao24}'),
        selected: isSelected,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
        onTap: onTap,
        leading: Icon(
          state.onGround ? Icons.flight_land : Icons.flight,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(callSign),
        subtitle: Text(
          [
            state.originCountry,
            if (altitude != null) '${altitude.toStringAsFixed(0)} m',
            if (velocity != null) '${velocity.toStringAsFixed(0)} m/s',
          ].join('  •  '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: state.onGround
            ? const Tooltip(
                message: 'On ground',
                child: Icon(Icons.circle, size: 10),
              )
            : null,
      ),
    );
  }
}
