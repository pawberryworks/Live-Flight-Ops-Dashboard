using LiveFlightOpsDashboardBackend.Configuration;
using LiveFlightOpsDashboardBackend.Services;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddJsonFile("config.json", optional: true, reloadOnChange: true);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddMemoryCache();
builder.Services.AddHealthChecks()
    .AddCheck<FlightStatesHealthCheck>("flight-states", tags: ["ready"]);
builder.Services
    .AddOptions<OpenSkyOptions>()
    .Bind(builder.Configuration.GetSection(OpenSkyOptions.SectionName))
    .ValidateOnStart();
builder.Services.AddSingleton<IValidateOptions<OpenSkyOptions>, OpenSkyOptionsValidator>();
builder.Services.AddSingleton<RuntimeFlightSettings>();

if (builder.Environment.IsDevelopment())
{
    builder.Services.AddCors(options =>
    {
        options.AddPolicy("LocalFrontend", policy => policy
            .SetIsOriginAllowed(origin => Uri.TryCreate(origin, UriKind.Absolute, out var uri)
                && uri.Host.Equals("localhost", StringComparison.OrdinalIgnoreCase))
            .AllowAnyHeader()
            .AllowAnyMethod());
    });
}

builder.Services.AddHttpClient("OpenSky", (serviceProvider, client) =>
{
    var options = serviceProvider.GetRequiredService<IOptions<OpenSkyOptions>>().Value;

    client.BaseAddress = new Uri($"{options.ApiUrl.TrimEnd('/')}/");
    client.Timeout = TimeSpan.FromSeconds(15);
});

// Add services to the container.
builder.Services.AddScoped<IRefreshIntervalService, RefreshIntervalService>();
builder.Services.AddScoped<IGeographicBoundsService, GeographicBoundsService>();
builder.Services.AddScoped<IFlightStatesService, FlightStatesService>();

builder.Services.AddHostedService<FlightStatesBackgroundService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseCors("LocalFrontend");
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();
app.MapHealthChecks("/health", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = _ => false
});
app.MapHealthChecks("/health/ready", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});

app.Run();
