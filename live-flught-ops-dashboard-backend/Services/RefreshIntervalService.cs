namespace LiveFlightOpsDashboardBackend.Services;

public sealed class RefreshIntervalService : IRefreshIntervalService
{
    private readonly RuntimeFlightSettings _settings;

    public RefreshIntervalService(RuntimeFlightSettings settings)
    {
        _settings = settings;
    }

    public int GetRefreshIntervalInSeconds()
    {
        return _settings.GetRefreshIntervalInSeconds();
    }

    public void SetRefreshIntervalInSeconds(int refreshIntervalInSeconds)
    {
        _settings.SetRefreshIntervalInSeconds(refreshIntervalInSeconds);
    }
}
