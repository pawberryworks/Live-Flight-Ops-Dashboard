using LiveFlightOpsDashboardBackend.Services;
using Microsoft.AspNetCore.Mvc;

namespace LiveFlightOpsDashboardBackend.Controllers;

[ApiController]
[Route("api/refreshInterval")]
public sealed class RefreshIntervalController : ControllerBase
{
    private readonly IRefreshIntervalService _refreshService;

    public RefreshIntervalController(IRefreshIntervalService refreshService)
    {
        _refreshService = refreshService;
    }

    [HttpGet()]
    public ActionResult<int> GetRefreshIntervalValue()
    {
        return _refreshService.GetRefreshIntervalInSeconds();
    }

    [HttpPut("{refreshIntervalInSeconds:int}")]
    public IActionResult PutRefreshValue(int refreshIntervalInSeconds)
    {
        try
        {
            _refreshService.SetRefreshIntervalInSeconds(refreshIntervalInSeconds);
        }
        catch (ArgumentOutOfRangeException exception)
        {
            ModelState.AddModelError(nameof(refreshIntervalInSeconds), exception.Message);
            return ValidationProblem(ModelState);
        }

        return NoContent();
    }
}
