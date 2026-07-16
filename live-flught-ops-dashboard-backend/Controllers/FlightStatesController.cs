using LiveFlightOpsDashboardBackend.DTO;
using LiveFlightOpsDashboardBackend.Services;
using Microsoft.AspNetCore.Mvc;

namespace LiveFlightOpsDashboardBackend.Controllers;

[ApiController]
[Route("api/flightStates")]
public sealed class FlightStatesController : ControllerBase
{
    private readonly IFlightStatesService _flightStatesService;

    public FlightStatesController(IFlightStatesService flightStatesService)
    {
        _flightStatesService = flightStatesService;
    }

    [HttpGet]
    [ProducesResponseType<FlightStatesResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public ActionResult<FlightStatesResponse> GetFlightStates()
    {
        var flightStates = _flightStatesService.GetFlightStates();

        if (flightStates is null)
        {
            return Problem(
                statusCode: StatusCodes.Status503ServiceUnavailable,
                detail: "Flight states have not been loaded yet.");
        }

        return Ok(flightStates);
    }
}
