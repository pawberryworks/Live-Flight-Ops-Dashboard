using System.Text.Json.Serialization;

namespace LiveFlughtOpsDashboardBackend.DTO;

public sealed class FlightStatesResponse
{
    [JsonPropertyName("time")]
    public long Time { get; init; }

    [JsonPropertyName("states")]
    public List<AircraftState>? States { get; init; }
}

