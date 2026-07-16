using LiveFlightOpsDashboardBackend.DTO;

namespace LiveFlightOpsDashboardBackend.Services;

public interface IFlightStatesService
{
    FlightStatesResponse? GetFlightStates();
}
