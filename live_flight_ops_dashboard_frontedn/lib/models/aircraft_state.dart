class AircraftState {
  const AircraftState({
    required this.icao24,
    required this.callSign,
    required this.originCountry,
    required this.timePosition,
    required this.lastContact,
    required this.longitude,
    required this.latitude,
    required this.barometricAltitude,
    required this.onGround,
    required this.velocity,
    required this.trueTrack,
    required this.verticalRate,
    required this.sensors,
    required this.geometricAltitude,
    required this.squawk,
    required this.spi,
    required this.positionSource,
    required this.category,
  });

  factory AircraftState.fromJson(List<dynamic> json) {
    if (json.length < 18) {
      throw const FormatException('An aircraft state must have 18 fields.');
    }

    return AircraftState(
      icao24: json[0] as String? ?? '',
      callSign: (json[1] as String? ?? '').trim(),
      originCountry: json[2] as String? ?? '',
      timePosition: (json[3] as num?)?.toInt(),
      lastContact: (json[4] as num?)?.toInt(),
      longitude: (json[5] as num?)?.toDouble(),
      latitude: (json[6] as num?)?.toDouble(),
      barometricAltitude: (json[7] as num?)?.toDouble(),
      onGround: json[8] as bool? ?? false,
      velocity: (json[9] as num?)?.toDouble(),
      trueTrack: (json[10] as num?)?.toDouble(),
      verticalRate: (json[11] as num?)?.toDouble(),
      sensors: (json[12] as List<dynamic>?)
          ?.map((sensor) => (sensor as num).toInt())
          .toList(growable: false),
      geometricAltitude: (json[13] as num?)?.toDouble(),
      squawk: json[14] as String?,
      spi: json[15] as bool? ?? false,
      positionSource: (json[16] as num?)?.toInt() ?? 0,
      category: (json[17] as num?)?.toInt() ?? 0,
    );
  }

  final String icao24;
  final String callSign;
  final String originCountry;
  final int? timePosition;
  final int? lastContact;
  final double? longitude;
  final double? latitude;
  final double? barometricAltitude;
  final bool onGround;
  final double? velocity;
  final double? trueTrack;
  final double? verticalRate;
  final List<int>? sensors;
  final double? geometricAltitude;
  final String? squawk;
  final bool spi;
  final int positionSource;
  final int category;
}
