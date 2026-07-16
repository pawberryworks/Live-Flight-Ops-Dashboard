namespace LiveFlightOpsDashboardBackend.Services;

public interface IRefreshIntervalService
{
    int GetRefreshIntervalInSeconds();

    void SetRefreshIntervalInSeconds(int refreshIntervalInSeconds);

}
