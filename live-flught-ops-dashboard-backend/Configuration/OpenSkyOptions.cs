namespace LiveFlightOpsDashboardBackend.Configuration;

public sealed class OpenSkyOptions
{
    public const string SectionName = "OpenSkyConfig";

    public string ApiUrl { get; init; } = string.Empty;

    public int RefreshIntervalInSeconds { get; init; }

    public double LatitudeMin { get; init; }

    public double LatitudeMax { get; init; }

    public double LongitudeMin { get; init; }

    public double LongitudeMax { get; init; }
}
