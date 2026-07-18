import 'package:flutter/material.dart';

import '../models/aircraft_state.dart';
import '../models/geographic_bounds.dart';
import 'geographic_bounds_map.dart';

class FlightStatesTable extends StatefulWidget {
  const FlightStatesTable({
    required this.states,
    required this.bounds,
    super.key,
  });

  final List<AircraftState> states;
  final GeographicBounds bounds;

  @override
  State<FlightStatesTable> createState() => _FlightStatesTableState();
}

class _FlightStatesTableState extends State<FlightStatesTable> {
  static const _columns = <String>[
    'ICAO24',
    'Call sign',
    'Country',
    'Latitude',
    'Longitude',
    'Altitude',
    'Status',
    'Velocity',
    'Track',
    'Vertical rate',
    'Squawk',
  ];

  final Map<int, String> _filters = {};

  List<String> _values(AircraftState state) => [
    state.icao24.toUpperCase(),
    state.callSign,
    state.originCountry,
    _number(state.latitude, suffix: '°'),
    _number(state.longitude, suffix: '°'),
    _number(state.barometricAltitude, suffix: ' m'),
    state.onGround ? 'On ground' : 'Airborne',
    _number(state.velocity, suffix: ' m/s'),
    _number(state.trueTrack, suffix: '°'),
    _number(state.verticalRate, suffix: ' m/s'),
    state.squawk ?? '—',
  ];

  List<AircraftState> get _filteredStates => widget.states.where((state) {
    final values = _values(state);
    return _filters.entries.every(
      (filter) => values[filter.key].toLowerCase().contains(filter.value),
    );
  }).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final filteredStates = _filteredStates;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'All flights',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text('${filteredStates.length} of ${widget.states.length}'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.states.isEmpty
                ? const Center(child: Text('No flights are currently tracked.'))
                : SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 76,
                        columns: [
                          for (var index = 0; index < _columns.length; index++)
                            DataColumn(label: _ColumnFilter(
                              label: _columns[index],
                              onChanged: (value) => setState(() {
                                final filter = value.trim().toLowerCase();
                                if (filter.isEmpty) {
                                  _filters.remove(index);
                                } else {
                                  _filters[index] = filter;
                                }
                              }),
                            )),
                          const DataColumn(label: Text('Map')),
                        ],
                        rows: [
                          for (final state in filteredStates)
                            DataRow(
                              key: ValueKey('flight-row-${state.icao24}'),
                              cells: [
                                for (final value in _values(state))
                                  DataCell(Text(value)),
                                DataCell(
                                  IconButton(
                                    key: ValueKey('show-map-${state.icao24}'),
                                    tooltip: 'Show flight on map',
                                    icon: const Icon(Icons.map_outlined),
                                    onPressed: () => _showFlightMap(state),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          if (widget.states.isNotEmpty && filteredStates.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Center(child: Text('No flights match the filters.')),
            ),
        ],
      ),
    );
  }

  Future<void> _showFlightMap(AircraftState state) {
    final identifier = state.callSign.isEmpty
        ? state.icao24.toUpperCase()
        : state.callSign;
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$identifier on map',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: state.latitude == null || state.longitude == null
                      ? const Center(
                          child: Text('This flight has no reported position.'),
                        )
                      : AircraftMapScope(
                          aircraft: [state],
                          selectedAircraftIcao24: state.icao24,
                          onAircraftSelected: (_) {},
                          onAircraftDeselected: () {},
                          child: GeographicBoundsMap(
                            bounds: widget.bounds,
                            aircraftCount: 1,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColumnFilter extends StatelessWidget {
  const _ColumnFilter({required this.label, required this.onChanged});

  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: TextField(
              key: ValueKey('filter-${label.toLowerCase().replaceAll(' ', '-')}'),
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _number(double? value, {required String suffix}) {
  if (value == null) return '—';
  return '${value.toStringAsFixed(1)}$suffix';
}
