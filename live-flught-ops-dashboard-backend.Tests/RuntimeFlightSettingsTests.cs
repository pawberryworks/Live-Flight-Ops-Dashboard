using LiveFlightOpsDashboardBackend.Configuration;
using LiveFlightOpsDashboardBackend.DTO;
using LiveFlightOpsDashboardBackend.Services;
using Microsoft.Extensions.Options;

namespace LiveFlightOpsDashboardBackend.Tests;

public sealed class RuntimeFlightSettingsTests
{
    [Fact]
    public void SetBounds_RejectsInvalidCoordinates()
    {
        var settings = CreateSettings();

        var exception = Assert.Throws<ArgumentException>(() => settings.SetBounds(
            new GeographicBounds(48, 47, 16, 17)));

        Assert.Contains("Minimum geographic bounds", exception.Message);
    }

    [Fact]
    public void SetRefreshInterval_RejectsValuesBelowTheMinimum()
    {
        var settings = CreateSettings();

        Assert.Throws<ArgumentOutOfRangeException>(() =>
            settings.SetRefreshIntervalInSeconds(RuntimeFlightSettings.MinimumRefreshIntervalInSeconds - 1));
    }

    [Fact]
    public void SetBounds_PublishesTheValidatedBounds()
    {
        var settings = CreateSettings();
        var bounds = new GeographicBounds(47, 48, 15, 16);

        settings.SetBounds(bounds);

        Assert.Equal(bounds, settings.GetBounds());
    }

    private static RuntimeFlightSettings CreateSettings() => new(Options.Create(new OpenSkyOptions
    {
        ApiUrl = "https://example.test/api",
        RefreshIntervalInSeconds = 10,
        LatitudeMin = 47,
        LatitudeMax = 48,
        LongitudeMin = 15,
        LongitudeMax = 16
    }));
}
