import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/geographic_bounds.dart';

class GeographicBoundsMap extends StatelessWidget {
  const GeographicBoundsMap({required this.bounds, super.key});

  final GeographicBounds bounds;

  @override
  Widget build(BuildContext context) {
    final mapBounds = LatLngBounds(
      LatLng(bounds.latitudeMin, bounds.longitudeMin),
      LatLng(bounds.latitudeMax, bounds.longitudeMax),
    );

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: mapBounds,
              padding: const EdgeInsets.all(48),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.live_flight_ops_dashboard',
            ),
            PolygonLayer(
              polygons: [
                Polygon(
                  points: [
                    LatLng(bounds.latitudeMin, bounds.longitudeMin),
                    LatLng(bounds.latitudeMin, bounds.longitudeMax),
                    LatLng(bounds.latitudeMax, bounds.longitudeMax),
                    LatLng(bounds.latitudeMax, bounds.longitudeMin),
                  ],
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.16),
                  borderColor: Theme.of(context).colorScheme.primary,
                  borderStrokeWidth: 3,
                ),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                const TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          top: 20,
          left: 20,
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      ],
    );
  }
}
