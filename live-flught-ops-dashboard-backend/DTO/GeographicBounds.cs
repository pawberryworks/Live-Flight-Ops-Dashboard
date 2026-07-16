namespace LiveFlightOpsDashboardBackend.DTO;

public sealed record GeographicBounds(
    double LatitudeMin,
    double LatitudeMax,
    double LongitudeMin,
    double LongitudeMax);
