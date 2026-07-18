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
      icao24: _string(json[0]),
      callSign: _string(json[1]).trim(),
      originCountry: _string(json[2]),
      timePosition: _int(json[3]),
      lastContact: _int(json[4]),
      longitude: _double(json[5]),
      latitude: _double(json[6]),
      barometricAltitude: _double(json[7]),
      onGround: _bool(json[8]),
      velocity: _double(json[9]),
      trueTrack: _double(json[10]),
      verticalRate: _double(json[11]),
      sensors: _intList(json[12]),
      geometricAltitude: _double(json[13]),
      squawk: _nullableString(json[14]),
      spi: _bool(json[15]),
      positionSource: _int(json[16]) ?? 0,
      category: _int(json[17]) ?? 0,
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

String _string(Object? value) => value is String ? value : '';

String? _nullableString(Object? value) => value is String ? value : null;

int? _int(Object? value) => value is num ? value.toInt() : null;

double? _double(Object? value) => value is num ? value.toDouble() : null;

bool _bool(Object? value) => value is bool ? value : false;

List<int>? _intList(Object? value) {
  if (value is! List<dynamic>) return null;
  return value
      .whereType<num>()
      .map((item) => item.toInt())
      .toList(growable: false);
}
