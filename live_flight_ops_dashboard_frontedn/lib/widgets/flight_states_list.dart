import 'package:flutter/material.dart';

import '../models/aircraft_state.dart';
import 'flight_details_dialog.dart';

class FlightStatesList extends StatefulWidget {
  const FlightStatesList({
    required this.states,
    this.selectedAircraftIcao24,
    this.onAircraftSelected,
    this.onAircraftDeselected,
    super.key,
  });

  final List<AircraftState> states;
  final String? selectedAircraftIcao24;
  final ValueChanged<String>? onAircraftSelected;
  final VoidCallback? onAircraftDeselected;

  @override
  State<FlightStatesList> createState() => _FlightStatesListState();
}

class _FlightStatesListState extends State<FlightStatesList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<AircraftState> get _filteredStates {
    final query = _searchQuery;
    if (query.isEmpty) return widget.states;

    return widget.states.where((state) {
      return state.callSign.toLowerCase().contains(query) ||
          state.originCountry.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredStates = _filteredStates;
    final selectAircraft = widget.onAircraftSelected;
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
                Badge.count(count: widget.states.length),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: TextField(
              key: const ValueKey('tracked-flights-search'),
              controller: _searchController,
              onChanged: (value) => setState(
                () => _searchQuery = value.trim().toLowerCase(),
              ),
              decoration: InputDecoration(
                labelText: 'Search flights',
                hintText: 'Call sign or country',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.states.isEmpty
                ? const Center(child: Text('No flights are currently tracked.'))
                : filteredStates.isEmpty
                ? const Center(child: Text('No flights match your search.'))
                : ListView.separated(
                    itemCount: filteredStates.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) => _FlightListItem(
                      state: filteredStates[index],
                      isSelected:
                          filteredStates[index].icao24 ==
                          widget.selectedAircraftIcao24,
                      onTap: selectAircraft == null
                          ? null
                          : () => selectAircraft(filteredStates[index].icao24),
                      onDoubleTap: widget.onAircraftDeselected,
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
    required this.onDoubleTap,
  });

  final AircraftState state;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

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
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: ListTile(
          key: ValueKey('flight-${state.icao24}'),
          selected: isSelected,
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
          leading: Icon(
            state.onGround ? Icons.flight_land : Icons.flight,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            callSign,
            style: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface
            ),
          ),
          subtitle: Text(
            [
              state.originCountry,
              if (altitude != null) '${altitude.toStringAsFixed(0)} m',
              if (velocity != null) '${velocity.toStringAsFixed(0)} m/s',
            ].join('  •  '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: ValueKey('flight-details-${state.icao24}'),
                tooltip: 'Flight details',
                onPressed: () => showFlightDetailsDialog(context, state),
                icon: Icon(
                  Icons.info_outline, 
                  size: 20, 
                  color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
