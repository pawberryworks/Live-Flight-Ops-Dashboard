using LiveFlightOpsDashboardBackend.DTO;
using LiveFlightOpsDashboardBackend.Services;
using Microsoft.AspNetCore.Mvc;

namespace LiveFlightOpsDashboardBackend.Controllers;

[ApiController]
[Route("api/geographicBounds")]
public sealed class GeographicBoundsController : ControllerBase
{
    private readonly IGeographicBoundsService _geographicBoundsService;

    public GeographicBoundsController(IGeographicBoundsService geographicBoundsService)
    {
        _geographicBoundsService = geographicBoundsService;
    }

    [HttpGet]
    public async Task<ActionResult<GeographicBounds>> GetGeographicBounds()
    {
        return Ok(_geographicBoundsService.GetGeographicBounds());
    }

    [HttpPut]
    public async Task<IActionResult> PutGeographicBounds(GeographicBounds geographicBounds)
    {
        _geographicBoundsService.SetGeographicBounds(geographicBounds);
        return NoContent();
    }
}
