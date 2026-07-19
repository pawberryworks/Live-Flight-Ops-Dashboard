using LiveFlightOpsDashboardBackend.DTO;

namespace LiveFlightOpsDashboardBackend.Services;

public sealed class GeographicBoundsService : IGeographicBoundsService
{
    private readonly RuntimeFlightSettings _settings;

    public GeographicBoundsService(RuntimeFlightSettings settings)
    {
        _settings = settings;
    }

    public GeographicBounds GetGeographicBounds()
    {
        return _settings.GetBounds();
    }

    public void SetGeographicBounds(GeographicBounds geographicBounds)
    {
        _settings.SetBounds(geographicBounds);
    }
}
