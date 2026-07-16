using LiveFlightOpsDashboardBackend.DTO;
using Microsoft.Extensions.Caching.Memory;

namespace LiveFlightOpsDashboardBackend.Services;

public sealed class FlightStatesService : IFlightStatesService
{
    private readonly IMemoryCache _memoryCache;

    public FlightStatesService(IMemoryCache memoryCache)
    {
        _memoryCache = memoryCache;
    }

    public FlightStatesResponse? GetFlightStates()
    {
        return _memoryCache.Get<FlightStatesResponse>(
            FlightStatesBackgroundService.FlightStatesCacheKey);
    }
}
