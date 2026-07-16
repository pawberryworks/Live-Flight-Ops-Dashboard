using LiveFlightOpsDashboardBackend.DTO;

namespace LiveFlightOpsDashboardBackend.Services;

public interface IGeographicBoundsService
{
    GeographicBounds GetGeographicBounds();

    void SetGeographicBounds(GeographicBounds geographicBounds);
}
