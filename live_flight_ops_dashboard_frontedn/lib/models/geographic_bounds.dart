class GeographicBounds {
  const GeographicBounds({
    required this.latitudeMin,
    required this.latitudeMax,
    required this.longitudeMin,
    required this.longitudeMax,
  });

  factory GeographicBounds.fromJson(Map<String, dynamic> json) {
    return GeographicBounds(
      latitudeMin: (json['latitudeMin'] as num).toDouble(),
      latitudeMax: (json['latitudeMax'] as num).toDouble(),
      longitudeMin: (json['longitudeMin'] as num).toDouble(),
      longitudeMax: (json['longitudeMax'] as num).toDouble(),
    );
  }

  final double latitudeMin;
  final double latitudeMax;
  final double longitudeMin;
  final double longitudeMax;
}
