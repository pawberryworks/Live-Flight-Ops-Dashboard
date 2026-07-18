import 'package:flutter/material.dart';

import '../models/aircraft_state.dart';

class FlightStatesList extends StatelessWidget {
  const FlightStatesList({required this.states, super.key});

  final List<AircraftState> states;

  @override
  Widget build(BuildContext context) {
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
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FlightListItem extends StatelessWidget {
  const _FlightListItem({required this.state});

  final AircraftState state;

  @override
  Widget build(BuildContext context) {
    final callSign = state.callSign.isEmpty
        ? state.icao24.toUpperCase()
        : state.callSign;
    final altitude = state.barometricAltitude;
    final velocity = state.velocity;

    return Semantics(
      label: 'Flight $callSign from ${state.originCountry}',
      child: ListTile(
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
