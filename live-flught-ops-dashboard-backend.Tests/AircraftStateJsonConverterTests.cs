using System.Text.Json;
using LiveFlightOpsDashboardBackend.DTO;

namespace LiveFlightOpsDashboardBackend.Tests;

public sealed class AircraftStateJsonConverterTests
{
    [Fact]
    public void Deserialize_MapsTheOpenSkyArrayContract()
    {
        const string json = "[\"abc123\",\" TEST123 \",\"Austria\",100,101,16.3,48.2,9000,false,220,45,1.2,null,9100,\"1234\",false,0,3]";

        var state = JsonSerializer.Deserialize<AircraftState>(json);

        Assert.NotNull(state);
        Assert.Equal("abc123", state.Icao24);
        Assert.Equal("TEST123", state.CallSign);
        Assert.Equal(48.2, state.Latitude);
        Assert.Equal(3, state.Category);
    }

    [Fact]
    public void Deserialize_RejectsANonArrayValue()
    {
        Assert.Throws<JsonException>(() => JsonSerializer.Deserialize<AircraftState>("{}"));
    }
}
