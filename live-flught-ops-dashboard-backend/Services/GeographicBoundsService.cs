using System.Globalization;
using LiveFlightOpsDashboardBackend.DTO;

namespace LiveFlightOpsDashboardBackend.Services;

public sealed class GeographicBoundsService : IGeographicBoundsService
{
    private const string ConfigurationSection = "OpenSkyConfig";

    private readonly IConfiguration _configuration;

    public GeographicBoundsService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public GeographicBounds GetGeographicBounds()
    {
        return new GeographicBounds(
            GetValue("LatitudeMin"),
            GetValue("LatitudeMax"),
            GetValue("LongitudeMin"),
            GetValue("LongitudeMax"));
    }

    public void SetGeographicBounds(GeographicBounds geographicBounds)
    {
        SetValue("LatitudeMin", geographicBounds.LatitudeMin);
        SetValue("LatitudeMax", geographicBounds.LatitudeMax);
        SetValue("LongitudeMin", geographicBounds.LongitudeMin);
        SetValue("LongitudeMax", geographicBounds.LongitudeMax);
    }

    private double GetValue(string key)
    {
        return _configuration.GetValue<double>($"{ConfigurationSection}:{key}");
    }

    private void SetValue(string key, double value)
    {
        _configuration[$"{ConfigurationSection}:{key}"] =
            value.ToString(CultureInfo.InvariantCulture);
    }
}
