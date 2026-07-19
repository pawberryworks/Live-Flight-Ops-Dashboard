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
    public ActionResult<GeographicBounds> GetGeographicBounds()
    {
        return Ok(_geographicBoundsService.GetGeographicBounds());
    }

    [HttpPut]
    public IActionResult PutGeographicBounds([FromBody] GeographicBounds geographicBounds)
    {
        try
        {
            _geographicBoundsService.SetGeographicBounds(geographicBounds);
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(nameof(geographicBounds), exception.Message);
            return ValidationProblem(ModelState);
        }

        return NoContent();
    }
}
