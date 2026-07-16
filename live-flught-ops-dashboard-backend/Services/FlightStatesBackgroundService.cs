using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;

using LiveFlightOpsDashboardBackend.DTO;

namespace LiveFlightOpsDashboardBackend.Services;

public sealed class FlightStatesBackgroundService : BackgroundService
{
    public const string FlightStatesCacheKey = "FlightStates";

    private const string HttpClientName = "OpenSky";
    private const string FlightStatesPath = "states/all";

    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<FlightStatesBackgroundService> _logger;
    private readonly IMemoryCache _memoryCache;

    public FlightStatesBackgroundService(
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory,
        ILogger<FlightStatesBackgroundService> logger,
        IMemoryCache memoryCache)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
        _logger = logger;
        _memoryCache = memoryCache;
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
            using var response = await client.GetAsync(FlightStatesPathWithParameters(), stoppingToken);
            response.EnsureSuccessStatusCode();

            var flightStates = await response.Content.ReadFromJsonAsync<FlightStatesResponse>(
                cancellationToken: stoppingToken);

            if (flightStates is null)
            {
                _logger.LogWarning("The flight states API returned an empty response.");
                return;
            }

            _logger.LogInformation("Fetched flight states from the external API with count {Count}.",
                flightStates.States.Count());

            _memoryCache.Set(FlightStatesCacheKey, flightStates);

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

    private String FlightStatesPathWithParameters() {
        return $"{FlightStatesPath}?{GetParametersOfLatitudesAndLongitutes()}";
    }

    private String GetParametersOfLatitudesAndLongitutes()
    {
        var minimalLatitude =
            _configuration.GetValue<float>("OpenSkyConfig:LatitudeMin");

        var minimalLongitude =
            _configuration.GetValue<float>("OpenSkyConfig:LongitudeMin");

        var maximalLatitude =
            _configuration.GetValue<float>("OpenSkyConfig:LatitudeMax");

        var maximalLongitude =
            _configuration.GetValue<float>("OpenSkyConfig:LongitudeMax");

        return $"lamin={minimalLatitude}&lomin={minimalLongitude}&lamax={maximalLatitude}&lomax={maximalLongitude}";
    }
}
