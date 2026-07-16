using System.Text.Json.Serialization;

using LiveFlightOpsDashboardBackend.Converters;

namespace LiveFlightOpsDashboardBackend.DTO;

[JsonConverter(typeof(AircraftStateJsonConverter))]
public sealed class AircraftState
{
    public string Icao24 { get; init; } = string.Empty;
    public string CallSign { get; init; } = string.Empty;
    public string OriginCountry { get; init; } = string.Empty;

    public long? TimePosition { get; init; }
    public long? LastContact { get; init; }

    public double? Longitude { get; init; }
    public double? Latitude { get; init; }
    public double? BarometricAltitude { get; init; }

    public bool OnGround { get; init; }

    public double? Velocity { get; init; }
    public double? TrueTrack { get; init; }
    public double? VerticalRate { get; init; }

    public int[]? Sensors { get; init; }

    public double? GeometricAltitude { get; init; }
    public string? Squawk { get; init; }

    public bool Spi { get; init; }
    public int PositionSource { get; init; }
    public int Category { get; init; } 
}