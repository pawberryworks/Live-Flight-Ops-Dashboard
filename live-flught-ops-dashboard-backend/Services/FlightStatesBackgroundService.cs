using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;

using LiveFlightOpsDashboardBackend.DTO;

namespace LiveFlightOpsDashboardBackend.Services;

public sealed class FlightStatesBackgroundService : BackgroundService
{
    public const string FlightStatesCacheKey = "FlightStates";

    private const string HttpClientName = "OpenSky";
    private const string FlightStatesPath = "states/all";

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<FlightStatesBackgroundService> _logger;
    private readonly IMemoryCache _memoryCache;
    private readonly RuntimeFlightSettings _settings;

    public FlightStatesBackgroundService(
        IHttpClientFactory httpClientFactory,
        ILogger<FlightStatesBackgroundService> logger,
        IMemoryCache memoryCache,
        RuntimeFlightSettings settings)
    {
        _httpClientFactory = httpClientFactory;
        _logger = logger;
        _memoryCache = memoryCache;
        _settings = settings;
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
                flightStates.States?.Count ?? 0);

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
        catch (OperationCanceledException exception)
        {
            _logger.LogError(exception, "The flight states request timed out.");
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
            _settings.GetRefreshIntervalInSeconds();

        return TimeSpan.FromSeconds(refreshIntervalInSeconds);
    }

    private string FlightStatesPathWithParameters()
    {
        return $"{FlightStatesPath}?{GetParametersOfLatitudesAndLongitudes()}";
    }

    private string GetParametersOfLatitudesAndLongitudes()
    {
        var bounds = _settings.GetBounds();

        return FormattableString.Invariant(
            $"lamin={bounds.LatitudeMin}&lomin={bounds.LongitudeMin}&lamax={bounds.LatitudeMax}&lomax={bounds.LongitudeMax}");
    }
}
