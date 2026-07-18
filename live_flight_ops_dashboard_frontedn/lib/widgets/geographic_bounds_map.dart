import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/aircraft_state.dart';
import '../models/geographic_bounds.dart';
import 'outlined_icon.dart';

const double _tileSize = 256;

class AircraftMapScope extends InheritedWidget {
  const AircraftMapScope({
    required this.aircraft,
    required this.selectedAircraftIcao24,
    required this.onAircraftSelected,
    required this.onAircraftDeselected,
    required super.child,
    super.key,
  });

  final List<AircraftState> aircraft;
  final String? selectedAircraftIcao24;
  final ValueChanged<String> onAircraftSelected;
  final VoidCallback onAircraftDeselected;

  static AircraftMapScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AircraftMapScope>();
  }

  @override
  bool updateShouldNotify(AircraftMapScope oldWidget) {
    return aircraft != oldWidget.aircraft ||
        selectedAircraftIcao24 != oldWidget.selectedAircraftIcao24 ||
        onAircraftSelected != oldWidget.onAircraftSelected ||
        onAircraftDeselected != oldWidget.onAircraftDeselected;
  }
}

class GeographicBoundsMap extends StatelessWidget {
  const GeographicBoundsMap({
    required this.bounds,
    required this.aircraftCount,
    super.key,
  });

  final GeographicBounds bounds;

  // Keep this field on the const widget for Flutter hot-reload compatibility.
  final int aircraftCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, available) {
        final northWest = _project(
          bounds.latitudeMax,
          bounds.longitudeMin,
          0,
        );
        final southEast = _project(
          bounds.latitudeMin,
          bounds.longitudeMax,
          0,
        );
        final aspectRatio = (southEast.dx - northWest.dx) /
            (southEast.dy - northWest.dy);
        var width = math.min(available.maxWidth, 1200.0);
        var height = width / aspectRatio;
        final maximumHeight = math.min(available.maxHeight, 760.0);
        if (height > maximumHeight) {
          height = maximumHeight;
          width = height * aspectRatio;
        }

        return Center(
          child: Container(
            width: width,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            foregroundDecoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = _MapLayout.forBounds(
                  bounds,
                  Size(constraints.maxWidth, constraints.maxHeight),
                );

                return Stack(
                  children: [
                    ClipRect(
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 8,
                        boundaryMargin: const EdgeInsets.all(300),
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: Stack(
                            children: [
                              for (final tile in layout.tiles)
                                Positioned(
                                  left: tile.left,
                                  top: tile.top,
                                  width: layout.tileDisplaySize,
                                  height: layout.tileDisplaySize,
                                  child: Image.network(
                                    tile.url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        ColoredBox(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                        ),
                                  ),
                                ),
                              Positioned.fill(
                                child: ColoredBox(
                                  key: const ValueKey('map-dark-overlay'),
                                  color: Colors.black.withValues(alpha: 0.32),
                                ),
                              ),
                              Positioned.fill(
                                child: _AircraftMarkers(
                                  layout: layout,
                                  bounds: bounds,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Operational area',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${bounds.latitudeMin.toStringAsFixed(2)}°–${bounds.latitudeMax.toStringAsFixed(2)}° N  •  '
                                '${bounds.longitudeMin.toStringAsFixed(2)}°–${bounds.longitudeMax.toStringAsFixed(2)}° E',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 8,
                      bottom: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(0xCCFFFFFF)),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            '© OpenStreetMap contributors',
                            style: TextStyle(fontSize: 10, color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _AircraftMarkers extends StatelessWidget {
  const _AircraftMarkers({required this.layout, required this.bounds});

  final _MapLayout layout;
  final GeographicBounds bounds;

  @override
  Widget build(BuildContext context) {
    final scope = AircraftMapScope.maybeOf(context);
    final aircraft = scope?.aircraft ?? const <AircraftState>[];
    return Stack(
      children: [
        for (final state in aircraft)
          if (layout.positionFor(state, bounds) case final position?)
            Positioned(
              key: ValueKey('aircraft-${state.icao24}'),
              left: position.dx - 14,
              top: position.dy - 14,
              width: 28,
              height: 28,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: scope == null
                    ? null
                    : () => scope.onAircraftSelected(state.icao24),
                onDoubleTap: scope?.onAircraftDeselected,
                child: Tooltip(
                  message: _aircraftLabel(state),
                  excludeFromSemantics: true,
                  child: Semantics(
                    button: true,
                    selected: scope?.selectedAircraftIcao24 == state.icao24,
                    label: _aircraftLabel(state),
                    child: Transform.rotate(
                      angle: (state.trueTrack ?? 0) * math.pi / 180,
                      child: OutlinedIcon(
                        Icons.airplanemode_active,
                        size: 21,
                        color: scope?.selectedAircraftIcao24 == state.icao24
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.yellow,
                        outlineColor: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _MapLayout {
  const _MapLayout({required this.tiles, required this.boundsRectangle});

  factory _MapLayout.forBounds(GeographicBounds bounds, Size viewport) {
    const padding = 0.0;
    final zoom = _zoomForBounds(bounds, viewport, padding);

    final northWest = _project(bounds.latitudeMax, bounds.longitudeMin, zoom);
    final southEast = _project(bounds.latitudeMin, bounds.longitudeMax, zoom);
    final displayScale = viewport.width / (southEast.dx - northWest.dx);
    final firstX = (northWest.dx / _tileSize).floor();
    final lastX = (southEast.dx / _tileSize).ceil();
    final firstY = (northWest.dy / _tileSize).floor();
    final lastY = (southEast.dy / _tileSize).ceil();
    final tileCount = 1 << zoom;
    final tiles = <_MapTile>[];

    for (
      var y = math.max(0, firstY);
      y < math.min(tileCount, lastY);
      y++
    ) {
      for (var x = firstX; x < lastX; x++) {
        final wrappedX = ((x % tileCount) + tileCount) % tileCount;
        tiles.add(
          _MapTile(
            left: (x * _tileSize - northWest.dx) * displayScale,
            top: (y * _tileSize - northWest.dy) * displayScale,
            url: 'https://tile.openstreetmap.org/$zoom/$wrappedX/$y.png',
          ),
        );
      }
    }

    return _MapLayout(
      tiles: tiles,
      // Keep the layout metrics in the existing field so changing the map
      // crop does not alter this const class's field shape during hot reload.
      boundsRectangle: Rect.fromLTWH(
        0,
        0,
        viewport.width,
        _tileSize * displayScale + 0.5,
      ),
    );
  }

  final List<_MapTile> tiles;
  final Rect boundsRectangle;

  double get tileDisplaySize => boundsRectangle.height;

  Offset? positionFor(AircraftState aircraft, GeographicBounds bounds) {
    final latitude = aircraft.latitude;
    final longitude = aircraft.longitude;
    if (latitude == null ||
        longitude == null ||
        latitude < bounds.latitudeMin ||
        latitude > bounds.latitudeMax ||
        longitude < bounds.longitudeMin ||
        longitude > bounds.longitudeMax) {
      return null;
    }

    final northWestAtWorldZoom = _project(
      bounds.latitudeMax,
      bounds.longitudeMin,
      0,
    );
    final southEastAtWorldZoom = _project(
      bounds.latitudeMin,
      bounds.longitudeMax,
      0,
    );
    final aspectRatio =
        (southEastAtWorldZoom.dx - northWestAtWorldZoom.dx) /
        (southEastAtWorldZoom.dy - northWestAtWorldZoom.dy);
    final viewport = Size(
      boundsRectangle.width,
      boundsRectangle.width / aspectRatio,
    );
    final zoom = _zoomForBounds(bounds, viewport, 0);
    final northWest = _project(bounds.latitudeMax, bounds.longitudeMin, zoom);
    final southEast = _project(bounds.latitudeMin, bounds.longitudeMax, zoom);
    final displayScale = viewport.width / (southEast.dx - northWest.dx);
    final projected = _project(latitude, longitude, zoom);
    return (projected - northWest) * displayScale;
  }
}

int _zoomForBounds(
  GeographicBounds bounds,
  Size viewport,
  double padding,
) {
  var zoom = 18;
  for (; zoom > 0; zoom--) {
    final northWest = _project(bounds.latitudeMax, bounds.longitudeMin, zoom);
    final southEast = _project(bounds.latitudeMin, bounds.longitudeMax, zoom);
    if (southEast.dx - northWest.dx <= viewport.width - padding * 2 &&
        southEast.dy - northWest.dy <= viewport.height - padding * 2) {
      break;
    }
  }
  return zoom;
}

class _MapTile {
  const _MapTile({
    required this.left,
    required this.top,
    required this.url,
  });

  final double left;
  final double top;
  final String url;
}

Offset _project(double latitude, double longitude, int zoom) {
  final scale = _tileSize * (1 << zoom);
  final latitudeRadians =
      latitude.clamp(-85.05112878, 85.05112878).toDouble() * math.pi / 180;
  return Offset(
    (longitude + 180) / 360 * scale,
    (1 -
            math.log(
                  math.tan(latitudeRadians) + 1 / math.cos(latitudeRadians),
                ) /
                math.pi) /
        2 *
        scale,
  );
}

String _aircraftLabel(AircraftState aircraft) {
  final identifier = aircraft.callSign.isNotEmpty
      ? aircraft.callSign
      : aircraft.icao24.toUpperCase();
  final altitude = aircraft.barometricAltitude;
  return altitude == null
      ? identifier
      : '$identifier • ${altitude.toStringAsFixed(0)} m';
}
