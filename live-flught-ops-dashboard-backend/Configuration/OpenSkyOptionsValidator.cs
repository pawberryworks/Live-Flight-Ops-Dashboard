using LiveFlightOpsDashboardBackend.Services;
using Microsoft.Extensions.Options;

namespace LiveFlightOpsDashboardBackend.Configuration;

public sealed class OpenSkyOptionsValidator : IValidateOptions<OpenSkyOptions>
{
    public ValidateOptionsResult Validate(string? name, OpenSkyOptions options)
    {
        var failures = new List<string>();

        if (!Uri.TryCreate(options.ApiUrl, UriKind.Absolute, out var apiUrl)
            || (apiUrl.Scheme != Uri.UriSchemeHttp && apiUrl.Scheme != Uri.UriSchemeHttps))
        {
            failures.Add("OpenSkyConfig:ApiUrl must be an absolute HTTP or HTTPS URL.");
        }

        if (options.RefreshIntervalInSeconds < RuntimeFlightSettings.MinimumRefreshIntervalInSeconds)
        {
            failures.Add(
                $"OpenSkyConfig:RefreshIntervalInSeconds must be at least {RuntimeFlightSettings.MinimumRefreshIntervalInSeconds} seconds.");
        }

        if (!RuntimeFlightSettings.AreValidBounds(
                options.LatitudeMin,
                options.LatitudeMax,
                options.LongitudeMin,
                options.LongitudeMax,
                out var boundsError))
        {
            failures.Add(boundsError);
        }

        return failures.Count == 0
            ? ValidateOptionsResult.Success
            : ValidateOptionsResult.Fail(failures);
    }
}
