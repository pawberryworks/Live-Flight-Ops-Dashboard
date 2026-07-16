using System.Net.Http.Json;
using System.Text.Json;

using LiveFlughtOpsDashboardBackend.DTO;

namespace LiveFlughtOpsDashboardBackend.Services;

public sealed class FlightStatesBackgroundService : BackgroundService
{
    private const string HttpClientName = "OpenSky";
    private const string FlightStatesPath = "states/all";

    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<FlightStatesBackgroundService> _logger;

    public FlightStatesBackgroundService(
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory,
        ILogger<FlightStatesBackgroundService> logger)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await FetchFlightStatesAsync(stoppingToken);

            var refreshInterval = GetRefreshInterval();
            await Task.Delay(refreshInterval, stoppingToken);
        }
    }

    private async Task FetchFlightStatesAsync(CancellationToken stoppingToken)
    {
        try
        {
            var client = _httpClientFactory.CreateClient(HttpClientName);
            using var response = await client.GetAsync(FlightStatesPath, stoppingToken);
            response.EnsureSuccessStatusCode();

            var flightStates = await response.Content.ReadFromJsonAsync<FlightStatesResponse>(
                cancellationToken: stoppingToken);

            if (flightStates is null)
            {
                _logger.LogWarning("The flight states API returned an empty response.");
                return;
            }

            _logger.LogInformation(
                "Received {FlightStateCount} flight states at API timestamp {ApiTimestamp}.",
                flightStates.States?.Count ?? 0,
                flightStates.Time);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // The application is shutting down.
        }
        catch (HttpRequestException exception)
        {
            _logger.LogError(exception, "Failed to request flight states from the external API.");
        }
        catch (JsonException exception)
        {
            _logger.LogError(exception, "The flight states API returned invalid JSON.");
        }
    }

    private TimeSpan GetRefreshInterval()
    {
        var refreshIntervalInSeconds =
            _configuration.GetValue<int>("OpenSkyConfig:RefreshIntervalInSeconds");

        if (refreshIntervalInSeconds <= 0)
        {
            throw new InvalidOperationException(
                "OpenSkyConfig:RefreshIntervalInSeconds must be greater than zero.");
        }

        return TimeSpan.FromSeconds(refreshIntervalInSeconds);
    }
}
