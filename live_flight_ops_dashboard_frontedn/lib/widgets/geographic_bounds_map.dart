import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/aircraft_state.dart';
import '../models/geographic_bounds.dart';

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

class GeographicBoundsMap extends StatefulWidget {
  const GeographicBoundsMap({
    required this.bounds,
    required this.aircraftCount,
    super.key,
  });

  final GeographicBounds bounds;

  // Keep this field on the const widget for Flutter hot-reload compatibility.
  final int aircraftCount;

  @override
  State<GeographicBoundsMap> createState() => _GeographicBoundsMapState();
}

class _GeographicBoundsMapState extends State<GeographicBoundsMap> {
  Size? _layoutSize;
  GeographicBounds? _layoutBounds;
  _MapLayout? _layout;

  _MapLayout _layoutFor(Size size) {
    final bounds = widget.bounds;
    if (_layout == null ||
        _layoutSize != size ||
        !_sameBounds(_layoutBounds, bounds)) {
      _layoutSize = size;
      _layoutBounds = bounds;
      _layout = _MapLayout.forBounds(bounds, size);
    }
    return _layout!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, available) {
        final northWest = _project(
          widget.bounds.latitudeMax,
          widget.bounds.longitudeMin,
          0,
        );
        final southEast = _project(
          widget.bounds.latitudeMin,
          widget.bounds.longitudeMax,
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
                final layout = _layoutFor(
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
                                  bounds: widget.bounds,
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
                                '${widget.bounds.latitudeMin.toStringAsFixed(2)}°–${widget.bounds.latitudeMax.toStringAsFixed(2)}° N  •  '
                                '${widget.bounds.longitudeMin.toStringAsFixed(2)}°–${widget.bounds.longitudeMax.toStringAsFixed(2)}° E',
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
    AircraftState? aircraftAt(Offset point) {
      AircraftState? closest;
      var closestDistance = 18.0;
      for (final state in aircraft) {
        final position = layout.positionFor(state, bounds);
        if (position == null) continue;
        final distance = (position - point).distance;
        if (distance < closestDistance) {
          closest = state;
          closestDistance = distance;
        }
      }
      return closest;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: scope == null
          ? null
          : (details) {
              final state = aircraftAt(details.localPosition);
              if (state != null) scope.onAircraftSelected(state.icao24);
            },
      onDoubleTapDown: scope == null
          ? null
          : (details) {
              if (aircraftAt(details.localPosition) != null) {
                scope.onAircraftDeselected();
              }
            },
      child: RepaintBoundary(
        child: CustomPaint(
          key: const ValueKey('aircraft-marker-layer'),
          painter: _AircraftPainter(
            aircraft: aircraft,
            layout: layout,
            bounds: bounds,
            selectedAircraftIcao24: scope?.selectedAircraftIcao24,
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
            onAircraftSelected: scope?.onAircraftSelected,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _AircraftPainter extends CustomPainter {
  _AircraftPainter({
    required this.aircraft,
    required this.layout,
    required this.bounds,
    required this.selectedAircraftIcao24,
    required this.selectedColor,
    required this.onAircraftSelected,
  });

  final List<AircraftState> aircraft;
  final _MapLayout layout;
  final GeographicBounds bounds;
  final String? selectedAircraftIcao24;
  final Color selectedColor;
  final ValueChanged<String>? onAircraftSelected;

  static final Path _plane = Path()
    ..moveTo(0, -11)
    ..lineTo(3, -3)
    ..lineTo(10, 1)
    ..lineTo(10, 4)
    ..lineTo(3, 2)
    ..lineTo(2, 8)
    ..lineTo(5, 10)
    ..lineTo(5, 12)
    ..lineTo(0, 10)
    ..lineTo(-5, 12)
    ..lineTo(-5, 10)
    ..lineTo(-2, 8)
    ..lineTo(-3, 2)
    ..lineTo(-10, 4)
    ..lineTo(-10, 1)
    ..lineTo(-3, -3)
    ..close();

  Iterable<({AircraftState state, Offset position})> get _visible sync* {
    for (final state in aircraft) {
      final position = layout.positionFor(state, bounds);
      if (position != null) yield (state: state, position: position);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..style = PaintingStyle.fill;

    for (final marker in _visible) {
      canvas.save();
      canvas.translate(marker.position.dx, marker.position.dy);
      canvas.rotate((marker.state.trueTrack ?? 0) * math.pi / 180);
      fill.color = marker.state.icao24 == selectedAircraftIcao24
          ? selectedColor
          : Colors.yellow;
      canvas.drawPath(_plane, outline);
      canvas.drawPath(_plane, fill);
      canvas.restore();
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) => [
    for (final marker in _visible)
      CustomPainterSemantics(
        rect: Rect.fromCircle(center: marker.position, radius: 14),
        properties: SemanticsProperties(
          label: _aircraftLabel(marker.state),
          button: true,
          selected: marker.state.icao24 == selectedAircraftIcao24,
          onTap: onAircraftSelected == null
              ? null
              : () => onAircraftSelected!(marker.state.icao24),
        ),
      ),
  ];

  @override
  bool shouldRepaint(_AircraftPainter oldDelegate) =>
      aircraft != oldDelegate.aircraft ||
      layout != oldDelegate.layout ||
      selectedAircraftIcao24 != oldDelegate.selectedAircraftIcao24 ||
      selectedColor != oldDelegate.selectedColor;

  @override
  bool shouldRebuildSemantics(_AircraftPainter oldDelegate) =>
      shouldRepaint(oldDelegate) ||
      onAircraftSelected != oldDelegate.onAircraftSelected;
}

class _MapLayout {
  const _MapLayout({
    required this.tiles,
    required this.boundsRectangle,
    required this.zoom,
    required this.northWest,
    required this.displayScale,
  });

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
      zoom: zoom,
      northWest: northWest,
      displayScale: displayScale,
    );
  }

  final List<_MapTile> tiles;
  final Rect boundsRectangle;
  final int zoom;
  final Offset northWest;
  final double displayScale;

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

    // The viewport transform is shared by every marker. It is calculated once
    // in [forBounds] rather than recalculating the zoom and bounds for every
    // aircraft whenever live flight data refreshes.
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

bool _sameBounds(GeographicBounds? first, GeographicBounds second) {
  return first?.latitudeMin == second.latitudeMin &&
      first?.latitudeMax == second.latitudeMax &&
      first?.longitudeMin == second.longitudeMin &&
      first?.longitudeMax == second.longitudeMax;
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
