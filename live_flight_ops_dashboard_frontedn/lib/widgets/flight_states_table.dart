import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/aircraft_state.dart';
import '../models/geographic_bounds.dart';

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
  static const _rowsPerPage = 25;
  static const _minimumTableWidth = 780.0;
  static const _detailColumns = <String>[
    'ICAO24',
    'Call sign',
    'Origin country',
    'Time position',
    'Last contact',
    'Latitude',
    'Longitude',
    'Altitude',
    'On ground',
    'Velocity',
    'Track',
    'Vertical rate',
    'Sensors',
    'Geometric altitude',
    'Squawk',
    'SPI',
    'Position source',
    'Category',
  ];
  static const _tableColumnIndexes = <int>[0, 1, 2, 6, 5, 8];

  final Map<int, String> _filters = {};
  final ScrollController _horizontalScrollController = ScrollController();
  int _page = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  List<String> _values(AircraftState state) => [
    state.icao24.toUpperCase(),
    state.callSign,
    state.originCountry,
    _integer(state.timePosition),
    _integer(state.lastContact),
    _number(state.latitude, suffix: '°'),
    _number(state.longitude, suffix: '°'),
    _number(state.barometricAltitude, suffix: ' m'),
    state.onGround ? 'On ground' : 'Airborne',
    _number(state.velocity, suffix: ' m/s'),
    _number(state.trueTrack, suffix: '°'),
    _number(state.verticalRate, suffix: ' m/s'),
    state.sensors?.join(', ') ?? '—',
    _number(state.geometricAltitude, suffix: ' m'),
    state.squawk ?? '—',
    state.spi ? 'Yes' : 'No',
    state.positionSource.toString(),
    state.category.toString(),
  ];

  List<AircraftState> get _filteredStates {
    final states = _filters.isEmpty
        ? widget.states.toList(growable: false)
        : widget.states.where((state) {
            final values = _values(state);
            return _filters.entries.every(
              (filter) =>
                  values[filter.key].toLowerCase().contains(filter.value),
            );
          }).toList(growable: false);

    final sortColumnIndex = _sortColumnIndex;
    if (sortColumnIndex != null) {
      states.sort((left, right) {
        final comparison = _compareSortValues(
          _sortValue(left, sortColumnIndex),
          _sortValue(right, sortColumnIndex),
        );
        if (comparison != 0) {
          return _sortAscending ? comparison : -comparison;
        }
        return left.icao24.compareTo(right.icao24);
      });
    }
    return states;
  }

  Object? _sortValue(AircraftState state, int columnIndex) =>
      switch (columnIndex) {
        0 => state.icao24.toLowerCase(),
        1 => state.callSign.toLowerCase(),
        2 => state.originCountry.toLowerCase(),
        3 => state.timePosition,
        4 => state.lastContact,
        5 => state.latitude,
        6 => state.longitude,
        7 => state.barometricAltitude,
        8 => state.onGround,
        9 => state.velocity,
        10 => state.trueTrack,
        11 => state.verticalRate,
        12 => state.sensors?.join(', '),
        13 => state.geometricAltitude,
        14 => state.squawk?.toLowerCase(),
        15 => state.spi,
        16 => state.positionSource,
        17 => state.category,
        _ => null,
      };

  @override
  void didUpdateWidget(FlightStatesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lastPage = _lastPageFor(_filteredStates.length);
    if (_page > lastPage) _page = lastPage;
  }

  @override
  Widget build(BuildContext context) {
    final filteredStates = _filteredStates;
    final lastPage = _lastPageFor(filteredStates.length);
    final page = _page > lastPage ? lastPage : _page;
    final firstRow = page * _rowsPerPage;
    final pageStates = filteredStates
        .skip(firstRow)
        .take(_rowsPerPage)
        .toList(growable: false);
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
                : Scrollbar(
                    key: const ValueKey('flight-table-horizontal-scrollbar'),
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    interactive: true,
                    scrollbarOrientation: ScrollbarOrientation.bottom,
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        key: const ValueKey('flight-table-horizontal-scroll'),
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: math.max(
                            constraints.maxWidth,
                            _minimumTableWidth,
                          ),
                          child: SingleChildScrollView(
                            child: DataTable(
                          showCheckboxColumn: false,
                          headingRowHeight: 76,
                          columns: [
                            for (final index in _tableColumnIndexes)
                              DataColumn(
                                label: _ColumnFilter(
                                  label: _detailColumns[index],
                                  sortAscending: _sortColumnIndex == index
                                      ? _sortAscending
                                      : null,
                                  onSortRequested: (ascending) => setState(() {
                                    _sortColumnIndex = index;
                                    _sortAscending = ascending;
                                    _page = 0;
                                  }),
                                  onChanged: (value) => setState(() {
                                    _page = 0;
                                    final filter = value.trim().toLowerCase();
                                    if (filter.isEmpty) {
                                      _filters.remove(index);
                                    } else {
                                      _filters[index] = filter;
                                    }
                                  }),
                                ),
                              ),
                          ],
                          rows: [
                            for (final state in pageStates)
                              DataRow(
                                key: ValueKey('flight-row-${state.icao24}'),
                                onSelectChanged: (_) => _showFlightDetails(state),
                                cells: [
                                  for (final index in _tableColumnIndexes)
                                    DataCell(Text(_values(state)[index])),
                                ],
                              ),
                          ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ),
          ),
          if (widget.states.isNotEmpty && filteredStates.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Center(child: Text('No flights match the filters.')),
            ),
          if (filteredStates.isNotEmpty)
            _TablePagination(
              firstRow: firstRow + 1,
              lastRow: firstRow + pageStates.length,
              totalRows: filteredStates.length,
              canGoBack: page > 0,
              canGoForward: page < lastPage,
              onBack: () => setState(() => _page = page - 1),
              onForward: () => setState(() => _page = page + 1),
            ),
        ],
      ),
    );
  }

  int _lastPageFor(int rowCount) {
    if (rowCount == 0) return 0;
    return (rowCount - 1) ~/ _rowsPerPage;
  }

  Future<void> _showFlightDetails(AircraftState state) {
    final identifier = state.callSign.isEmpty
        ? state.icao24.toUpperCase()
        : state.callSign;
    final values = _values(state);
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$identifier flight details',
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
                  child: ListView.separated(
                    itemCount: _detailColumns.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 170,
                            child: Text(
                              _detailColumns[index],
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          Expanded(child: Text(values[index])),
                        ],
                      ),
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

class _TablePagination extends StatelessWidget {
  const _TablePagination({
    required this.firstRow,
    required this.lastRow,
    required this.totalRows,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
  });

  final int firstRow;
  final int lastRow;
  final int totalRows;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('$firstRow–$lastRow of $totalRows'),
            const SizedBox(width: 16),
            IconButton(
              tooltip: 'Previous page',
              onPressed: canGoBack ? onBack : null,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Next page',
              onPressed: canGoForward ? onForward : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColumnFilter extends StatelessWidget {
  const _ColumnFilter({
    required this.label,
    required this.sortAscending,
    required this.onSortRequested,
    required this.onChanged,
  });

  final String label;
  final bool? sortAscending;
  final ValueChanged<bool> onSortRequested;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
              if (sortAscending == null) ...[
                _SortButton(
                  icon: Icons.keyboard_arrow_up,
                  tooltip: 'Sort $label ascending',
                  onPressed: () => onSortRequested(true),
                ),
                _SortButton(
                  icon: Icons.keyboard_arrow_down,
                  tooltip: 'Sort $label descending',
                  onPressed: () => onSortRequested(false),
                ),
              ] else
                _SortButton(
                  icon: sortAscending!
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  tooltip: sortAscending!
                      ? 'Sorted $label ascending; sort descending'
                      : 'Sorted $label descending; sort ascending',
                  onPressed: () => onSortRequested(!sortAscending!),
                ),
            ],
          ),
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

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 24, height: 24),
    );
  }
}

String _number(double? value, {required String suffix}) {
  if (value == null) return '—';
  return '${value.toStringAsFixed(1)}$suffix';
}

String _integer(int? value) => value?.toString() ?? '—';

int _compareSortValues(Object? left, Object? right) {
  if (identical(left, right)) return 0;
  if (left == null) return 1;
  if (right == null) return -1;
  if (left is num && right is num) return left.compareTo(right);
  if (left is bool && right is bool) {
    return (left ? 1 : 0).compareTo(right ? 1 : 0);
  }
  return left.toString().compareTo(right.toString());
}
