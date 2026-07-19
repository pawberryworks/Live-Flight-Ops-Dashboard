using LiveFlightOpsDashboardBackend.Configuration;
using LiveFlightOpsDashboardBackend.DTO;
using Microsoft.Extensions.Options;

namespace LiveFlightOpsDashboardBackend.Services;

/// <summary>Provides a validated, process-local snapshot of mutable dashboard settings.</summary>
public sealed class RuntimeFlightSettings
{
    public const int MinimumRefreshIntervalInSeconds = 5;

    private readonly object _sync = new();
    private GeographicBounds _bounds;
    private int _refreshIntervalInSeconds;

    public RuntimeFlightSettings(IOptions<OpenSkyOptions> options)
    {
        var value = options.Value;
        _bounds = new GeographicBounds(
            value.LatitudeMin, value.LatitudeMax, value.LongitudeMin, value.LongitudeMax);
        _refreshIntervalInSeconds = value.RefreshIntervalInSeconds;
    }

    public GeographicBounds GetBounds()
    {
        lock (_sync)
            return _bounds;
    }

    public int GetRefreshIntervalInSeconds()
    {
        lock (_sync)
            return _refreshIntervalInSeconds;
    }

    public void SetBounds(GeographicBounds bounds)
    {
        if (!AreValidBounds(
                bounds.LatitudeMin, bounds.LatitudeMax, bounds.LongitudeMin, bounds.LongitudeMax,
                out var error))
        {
            throw new ArgumentException(error, nameof(bounds));
        }

        lock (_sync)
            _bounds = bounds;
    }

    public void SetRefreshIntervalInSeconds(int refreshIntervalInSeconds)
    {
        if (refreshIntervalInSeconds < MinimumRefreshIntervalInSeconds)
        {
            throw new ArgumentOutOfRangeException(
                nameof(refreshIntervalInSeconds),
                $"The refresh interval must be at least {MinimumRefreshIntervalInSeconds} seconds.");
        }

        lock (_sync)
            _refreshIntervalInSeconds = refreshIntervalInSeconds;
    }

    public static bool AreValidBounds(
        double latitudeMin,
        double latitudeMax,
        double longitudeMin,
        double longitudeMax,
        out string error)
    {
        if (latitudeMin is < -90 or > 90 || latitudeMax is < -90 or > 90)
        {
            error = "Latitude values must be between -90 and 90.";
            return false;
        }

        if (longitudeMin is < -180 or > 180 || longitudeMax is < -180 or > 180)
        {
            error = "Longitude values must be between -180 and 180.";
            return false;
        }

        if (latitudeMin >= latitudeMax || longitudeMin >= longitudeMax)
        {
            error = "Minimum geographic bounds must be less than their corresponding maximums.";
            return false;
        }

        error = string.Empty;
        return true;
    }
}
