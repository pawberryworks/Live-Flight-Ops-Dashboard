using LiveFlightOpsDashboardBackend.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddJsonFile("config.json", optional: true, reloadOnChange: true);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddMemoryCache();

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
    var configuration = serviceProvider.GetRequiredService<IConfiguration>();
    var apiUrl = configuration["OpenSkyConfig:ApiUrl"]
        ?? throw new InvalidOperationException("OpenSkyConfig:ApiUrl is not configured.");

    client.BaseAddress = new Uri($"{apiUrl.TrimEnd('/')}/");
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

app.Run();
