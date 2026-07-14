namespace LiveFlughtOpsDashboardBackend.Services;

public class RefreshIntervalService: IRefreshIntervalService
{
    private readonly IConfiguration _configuration;

    public RefreshIntervalService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public int GetRefreshIntervalInSeconds()
    {
        return _configuration.GetValue<int>("OpenSkyConfig:RefreshIntervalInSeconds");
    }

    public void SetRefreshIntervalInSeconds(int refreshIntervalInSeconds)
    {
        _configuration["OpenSkyConfig:RefreshIntervalInSeconds"] = refreshIntervalInSeconds.ToString();
    }
}
