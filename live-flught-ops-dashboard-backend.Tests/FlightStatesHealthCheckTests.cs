using LiveFlightOpsDashboardBackend.Configuration;
using LiveFlightOpsDashboardBackend.Services;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;

namespace LiveFlightOpsDashboardBackend.Tests;

public sealed class FlightStatesHealthCheckTests
{
    [Fact]
    public async Task CheckHealthAsync_IsUnhealthyBeforeTheFirstSnapshot()
    {
        using var cache = new MemoryCache(new MemoryCacheOptions());
        var healthCheck = new FlightStatesHealthCheck(cache, CreateSettings());

        var result = await healthCheck.CheckHealthAsync(new HealthCheckContext());

        Assert.Equal(HealthStatus.Unhealthy, result.Status);
    }

    [Fact]
    public async Task CheckHealthAsync_IsHealthyForARecentSnapshot()
    {
        using var cache = new MemoryCache(new MemoryCacheOptions());
        cache.Set(FlightStatesBackgroundService.FlightStatesFetchedAtCacheKey, DateTimeOffset.UtcNow);
        var healthCheck = new FlightStatesHealthCheck(cache, CreateSettings());

        var result = await healthCheck.CheckHealthAsync(new HealthCheckContext());

        Assert.Equal(HealthStatus.Healthy, result.Status);
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
