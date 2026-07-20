using LiveFlightOpsDashboardBackend.Configuration;

namespace LiveFlightOpsDashboardBackend.Tests;

public sealed class OpenSkyOptionsValidatorTests
{
    [Fact]
    public void Validate_AcceptsACompleteValidConfiguration()
    {
        var result = new OpenSkyOptionsValidator().Validate(null, ValidOptions());

        Assert.True(result.Succeeded);
    }

    [Fact]
    public void Validate_RejectsInvalidProviderUrlAndPollingInterval()
    {
        var options = new OpenSkyOptions
        {
            ApiUrl = "not-a-url",
            RefreshIntervalInSeconds = 1,
            LatitudeMin = 47,
            LatitudeMax = 48,
            LongitudeMin = 15,
            LongitudeMax = 16
        };

        var result = new OpenSkyOptionsValidator().Validate(null, options);

        Assert.True(result.Failed);
        Assert.Contains(result.Failures!, failure => failure.Contains("ApiUrl"));
        Assert.Contains(result.Failures!, failure => failure.Contains("RefreshIntervalInSeconds"));
    }

    private static OpenSkyOptions ValidOptions() => new()
    {
        ApiUrl = "https://example.test/api",
        RefreshIntervalInSeconds = 10,
        LatitudeMin = 47,
        LatitudeMax = 48,
        LongitudeMin = 15,
        LongitudeMax = 16
    };
}
