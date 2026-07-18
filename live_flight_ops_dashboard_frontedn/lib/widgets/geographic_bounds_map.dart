import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/geographic_bounds.dart';

const double _tileSize = 256;

class GeographicBoundsMap extends StatelessWidget {
  const GeographicBoundsMap({required this.bounds, super.key});

  final GeographicBounds bounds;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
                          width: _tileSize,
                          height: _tileSize,
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
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _BoundsPainter(
                              rectangle: layout.boundsRectangle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
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
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
    );
  }
}

class _MapLayout {
  const _MapLayout({required this.tiles, required this.boundsRectangle});

  factory _MapLayout.forBounds(GeographicBounds bounds, Size viewport) {
    const padding = 48.0;
    var zoom = 18;
    for (; zoom > 0; zoom--) {
      final northWest = _project(bounds.latitudeMax, bounds.longitudeMin, zoom);
      final southEast = _project(bounds.latitudeMin, bounds.longitudeMax, zoom);
      if (southEast.dx - northWest.dx <= viewport.width - padding * 2 &&
          southEast.dy - northWest.dy <= viewport.height - padding * 2) {
        break;
      }
    }

    final northWest = _project(bounds.latitudeMax, bounds.longitudeMin, zoom);
    final southEast = _project(bounds.latitudeMin, bounds.longitudeMax, zoom);
    final offset = Offset(
      (viewport.width - (northWest.dx + southEast.dx)) / 2,
      (viewport.height - (northWest.dy + southEast.dy)) / 2,
    );
    final firstX = ((-offset.dx) / _tileSize).floor() - 1;
    final lastX = ((viewport.width - offset.dx) / _tileSize).ceil() + 1;
    final firstY = ((-offset.dy) / _tileSize).floor() - 1;
    final lastY = ((viewport.height - offset.dy) / _tileSize).ceil() + 1;
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
            left: x * _tileSize + offset.dx,
            top: y * _tileSize + offset.dy,
            url: 'https://tile.openstreetmap.org/$zoom/$wrappedX/$y.png',
          ),
        );
      }
    }

    return _MapLayout(
      tiles: tiles,
      boundsRectangle: Rect.fromPoints(northWest + offset, southEast + offset),
    );
  }

  final List<_MapTile> tiles;
  final Rect boundsRectangle;
}

class _MapTile {
  const _MapTile({required this.left, required this.top, required this.url});

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

class _BoundsPainter extends CustomPainter {
  const _BoundsPainter({required this.rectangle, required this.color});

  final Rect rectangle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      rectangle,
      Paint()
        ..color = color.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rectangle,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_BoundsPainter oldDelegate) =>
      rectangle != oldDelegate.rectangle || color != oldDelegate.color;
}
