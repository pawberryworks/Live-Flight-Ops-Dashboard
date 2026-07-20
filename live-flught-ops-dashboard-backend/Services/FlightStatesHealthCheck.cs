using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace LiveFlightOpsDashboardBackend.Services;

/// <summary>Reports whether the cached provider snapshot is recent enough to serve operators.</summary>
public sealed class FlightStatesHealthCheck : IHealthCheck
{
    private readonly IMemoryCache _memoryCache;
    private readonly RuntimeFlightSettings _settings;

    public FlightStatesHealthCheck(IMemoryCache memoryCache, RuntimeFlightSettings settings)
    {
        _memoryCache = memoryCache;
        _settings = settings;
    }

    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        if (!_memoryCache.TryGetValue(FlightStatesBackgroundService.FlightStatesFetchedAtCacheKey,
                out DateTimeOffset fetchedAt))
        {
            return Task.FromResult(HealthCheckResult.Unhealthy(
                "Flight states have not been loaded yet."));
        }

        var maximumAge = TimeSpan.FromSeconds(_settings.GetRefreshIntervalInSeconds() * 2);
        var age = DateTimeOffset.UtcNow - fetchedAt;
        var data = new Dictionary<string, object>
        {
            ["snapshotAgeSeconds"] = Math.Max(0, age.TotalSeconds),
            ["maximumAgeSeconds"] = maximumAge.TotalSeconds
        };

        return Task.FromResult(age <= maximumAge
            ? HealthCheckResult.Healthy("Flight state snapshot is current.", data)
            : HealthCheckResult.Degraded("Flight state snapshot is stale.", null, data));
    }
}
