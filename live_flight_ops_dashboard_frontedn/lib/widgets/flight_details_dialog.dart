import 'package:flutter/material.dart';

import '../models/aircraft_state.dart';
import '../models/geographic_bounds.dart';
import '../helpers/timestamp_helpers.dart';
import 'geographic_bounds_map.dart';

const _detailColumns = <String>[
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

Future<void> showFlightDetailsDialog(
  BuildContext context,
  AircraftState state,
) {
  final identifier = state.callSign.isEmpty
      ? state.icao24.toUpperCase()
      : state.callSign;
  final values = flightDetailValues(state);
  final mapBounds = flightDetailMapBoundsFor(state);
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
              if (mapBounds != null) ...[
                SizedBox(
                  height: 220,
                  child: AircraftMapScope(
                    aircraft: [state],
                    selectedAircraftIcao24: state.icao24,
                    onAircraftSelected: (_) {},
                    onAircraftDeselected: () {},
                    child: GeographicBoundsMap(
                      key: const ValueKey('flight-details-map'),
                      bounds: mapBounds,
                      aircraftCount: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ] else
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Flight position is unavailable.'),
                ),
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

List<String> flightDetailValues(AircraftState state) => [
  state.icao24.toUpperCase(),
  state.callSign,
  state.originCountry,
  timestampToString(state.timePosition),
  timestampToString(state.lastContact),
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

GeographicBounds? flightDetailMapBoundsFor(AircraftState state) {
  final latitude = state.latitude;
  final longitude = state.longitude;
  if (latitude == null || longitude == null) return null;

  // A compact viewport keeps the selected aircraft centered while retaining
  // useful geographical context in the details dialog.
  const halfSpanLatitude = 0.1;
  const halfSpanLongitude = 0.4;
  const maximumMapLatitude = 85.05112878;
  final centeredLatitude = latitude.clamp(
    -maximumMapLatitude + halfSpanLongitude,
    maximumMapLatitude - halfSpanLongitude,
  ).toDouble();
  return GeographicBounds(
    latitudeMin: centeredLatitude - halfSpanLatitude,
    latitudeMax: centeredLatitude + halfSpanLatitude,
    longitudeMin: longitude - halfSpanLongitude,
    longitudeMax: longitude + halfSpanLongitude,
  );
}

String _number(double? value, {String suffix = ''}) =>
    value == null ? '—' : '${value.toStringAsFixed(1)}$suffix';
