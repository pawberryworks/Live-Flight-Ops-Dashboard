using LiveFlightOpsDashboardBackend.Services;
using Microsoft.AspNetCore.Mvc;

namespace LiveFlightOpsDashboardBackend.Controllers;

[ApiController]
[Route("api/refreshInterval")]
public class RefreshIntervalController : Controller
{
    private readonly IRefreshIntervalService _refreshService;

    public RefreshIntervalController(IRefreshIntervalService refreshService)
    {
        _refreshService = refreshService;
    }

    [HttpGet()]
    public ActionResult<int> GetRefresIntervalhValue()
    {
        return _refreshService.GetRefreshIntervalInSeconds();
    }

    [HttpPut("{refreshIntervalInSeconds:int}")]
    public IActionResult PutRefreshValue(int refreshIntervalInSeconds)
    {
        _refreshService.SetRefreshIntervalInSeconds(refreshIntervalInSeconds);
        return NoContent();
    }
}
