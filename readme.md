# Live Flight Ops Dashboard

A full-stack dashboard for viewing live aircraft state data within configured
geographic bounds. The repository contains two independently runnable
applications:

| Application | Location | Responsibility |
| --- | --- | --- |
| Flutter frontend | `live_flight_ops_dashboard_frontedn/` | Dashboard UI, user interaction, and periodic presentation updates. |
| ASP.NET Core backend | `live-flught-ops-dashboard-backend/` | Flight-state retrieval, refresh configuration, and HTTP APIs consumed by the frontend. |

> The existing directory names are retained for compatibility, including their
> original spelling.

## Architecture

The frontend follows a lightweight layered architecture. Dependencies point
inward: widgets depend on application state and repository contracts, while
HTTP details remain at the outer edge.

```text
Flutter widgets
    │  render state / dispatch user actions
    ▼
DashboardController
    │  coordinates loading, polling, selection, and refresh updates
    ▼
Repository contracts
    │  FlightStatesRepository / GeographicBoundsRepository /
    │  RefreshIntervalRepository
    ▼
HTTP repository adapters
    ▼
HTTP services + ApiConfiguration
    ▼
ASP.NET Core API
```

### Frontend layers

| Layer | Key code | Decision |
| --- | --- | --- |
| Presentation | `lib/main.dart`, `lib/widgets/` | Widgets render controller state and invoke callbacks. They do not create or call HTTP services directly. |
| Application | `lib/features/dashboard/dashboard_controller.dart` | One controller owns dashboard loading, selection, refresh scheduling, and lifecycle transitions. |
| Repository contracts | `lib/repositories/dashboard_repositories.dart` | Stable interfaces prevent the application layer from depending on a transport implementation. |
| Data/infrastructure | `lib/repositories/http_dashboard_repositories.dart`, `lib/services/` | HTTP adapters delegate to focused services that decode backend responses and normalize service errors. |
| Configuration | `lib/core/api_configuration.dart` | The backend base URL is provided at build/run time rather than hard-coded into UI code. |

## Key Decisions

### Controller-owned dashboard state

`DashboardController` is the source of truth for loaded bounds, flight states,
refresh interval, selected aircraft, loading state, and load failures. This
keeps asynchronous workflow and polling logic out of the widget tree, enables
repository fakes in tests, and ensures map, list, table, and settings views use
the same dashboard state.

### Safe refresh and lifecycle behavior

Initial loads use a monotonically increasing generation number. If a newer
load starts, results from earlier requests are ignored. The controller also
cancels its periodic timer and invalidates in-flight loads during disposal.
Polling prevents overlapping flight-state requests and keeps the most recent
successful data visible if a periodic refresh fails.

### Repository contracts and resource ownership

Repository contracts describe data operations only. `Disposable` is separate
because resource cleanup is an infrastructure concern, not a domain operation.
The composition root in `main.dart` creates the HTTP-backed repositories and
passes their disposable resources to the controller it owns.

### Runtime API configuration

The default development API is `https://localhost:7002`. Override it without
changing source code by supplying a Dart define:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

All frontend HTTP requests have a configurable 15-second timeout. Services
convert timeout, HTTP-status, and malformed-response failures into
feature-specific exceptions so presentation code can show an appropriate
message without interpreting transport details.

### Map boundary

The current map widget contains OpenStreetMap tile URL and projection logic to
keep the application dependency footprint small. If the product needs offline
maps, provider switching, advanced caching, or richer geospatial features,
extract a map tile provider behind an interface (or adopt a dedicated map
package) before extending that feature further.

## Data Flow

1. `DashboardPage` constructs the configured HTTP repositories and
   `DashboardController`.
2. The controller retrieves the refresh interval, geographic bounds, and
   current flight states.
3. The controller publishes a ready, loading, or failure state to the UI.
4. The UI renders the same flight-state collection in the map, list, and table.
5. A periodic timer refreshes flight states using the configured interval.
6. Updating the interval applies it to the backend runtime settings and restarts
   frontend polling only after the update succeeds.

## Backend Architecture

The ASP.NET Core backend is a small read-model service between the dashboard
and OpenSky. It separates ingestion of provider data from API delivery: a
hosted worker polls OpenSky, converts the provider payload into backend DTOs,
and publishes the latest successful snapshot to an in-memory cache. API
controllers read that snapshot, so dashboard clients never invoke the external
provider directly or wait for an upstream request on every screen refresh.

```text
OpenSky API
    │  named HttpClient, 15-second timeout
    ▼
FlightStatesBackgroundService
    │  validates/deserializes provider response
    ▼
IMemoryCache (latest successful FlightStatesResponse)
    │
    ▼
FlightStatesService ──► FlightStatesController ──► GET /api/flightStates

RuntimeFlightSettings ◄── RefreshIntervalService / GeographicBoundsService
    │                         │                         │
    └──────── worker reads ───┴── API controllers ──────┘
```

### Components and responsibilities

| Component | Responsibility |
| --- | --- |
| `Program.cs` | Composes controllers, health checks, the memory cache, the named OpenSky HTTP client, runtime settings, scoped services, and the hosted worker. HTTPS redirection is enabled for all environments. |
| `OpenSkyOptions` and validator | Bind and validate startup configuration: an absolute HTTP(S) provider URL, valid latitude/longitude ordering and ranges, and a refresh interval of at least five seconds. Invalid startup configuration fails fast. |
| `RuntimeFlightSettings` | Holds the mutable geographic bounds and refresh interval behind a lock. It validates writes before publishing a new in-process value. |
| `FlightStatesBackgroundService` | Runs continuously, requests `states/all` with the current bounds, deserializes the response, logs failures, and only replaces the cached snapshot after a successful response. |
| Application services | Keep controllers thin: flight states are read from cache, while bounds and refresh interval delegate to the runtime settings owner. |
| Controllers | Expose the dashboard contract: `GET /api/flightStates`, `GET`/`PUT /api/geographicBounds`, and `GET`/`PUT /api/refreshInterval/{seconds}`. |

### Architecture decisions

#### 1. Poll OpenSky once in the backend, not once per dashboard client

**Decision.** A single `BackgroundService` performs the external request and
the dashboard API serves the cached result.

**Why.** This bounds outbound OpenSky traffic to the configured refresh rate,
avoids duplicate provider calls as clients scale, and gives every dashboard
view a consistent recent snapshot. It also keeps provider URL construction and
payload handling out of the Flutter application.

**Trade-off.** The returned data can be up to one polling interval old. Before
the first successful poll, `GET /api/flightStates` returns `503 Service
Unavailable` rather than an empty response so clients can distinguish a
not-ready backend from a valid empty flight set.

#### 2. Retain the last known good snapshot on provider failure

**Decision.** The worker writes to `IMemoryCache` only after it receives and
deserializes a successful response. Timeout, HTTP, malformed-JSON, and empty
payload conditions are logged without clearing the cache.

**Why.** Brief upstream failures do not make the dashboard suddenly lose useful
flight data. This favors operational continuity over forcing every caller to
handle an unavailable upstream service immediately.

**Trade-off.** The API does not currently expose snapshot age, so a client
cannot tell a recent snapshot from an older retained one. Add fetched-at
metadata and a staleness policy if the product needs that distinction.

#### 3. Keep mutable settings process-local and thread-safe

**Decision.** `RuntimeFlightSettings` is a singleton that owns validated
runtime changes to the refresh interval and geographic bounds, using a lock to
provide a consistent snapshot to controllers and the background worker.

**Why.** Operators can change the polling region or cadence without restarting
the service, while the worker cannot read partially updated bounds. The
five-second minimum protects the upstream API and avoids an accidental
tight-polling loop.

**Trade-off.** Changes are intentionally ephemeral: they reset when the
process restarts and are not shared across instances. Use a durable settings
store plus change notification for persistence, and a distributed cache (or a
separate ingestion service) before deploying multiple backend replicas.

#### 4. Validate configuration early and isolate external HTTP configuration

**Decision.** Startup configuration is bound to `OpenSkyOptions` and validated
on startup; the worker obtains a named `OpenSky` client from
`IHttpClientFactory`, with a base URL derived from those validated options and
a 15-second timeout.

**Why.** Bad endpoints, invalid coordinates, and unsafe polling intervals fail
at startup instead of causing a delayed production failure. The named client
centralizes the provider-specific URL and timeout while retaining the
framework-managed HTTP client lifetime.

#### 5. Limit browser access to local development

**Decision.** In Development, CORS accepts only absolute origins whose host is
`localhost`, with all request headers and methods allowed. Other environments
do not register this policy.

**Why.** This enables the local Flutter web application without publishing a
permissive cross-origin policy in deployed environments.

**Trade-off.** Production browser clients require an explicitly designed CORS
and authentication/authorization policy; the current API does not add an
application authentication scheme.

### Operational behavior

- `GET /health` is a liveness endpoint registered through ASP.NET Core health
  checks.
- The OpenSky client uses a 15-second timeout. The worker logs request,
  timeout, and payload failures while retaining the last successful snapshot.
- The current bounds are sent to OpenSky as `lamin`, `lomin`, `lamax`, and
  `lomax` query parameters. A changed bound takes effect on the next poll.
- A changed refresh interval is used for the next delay cycle. It must be at
  least five seconds both at startup and through the runtime update endpoint.

## Testing Strategy

- **Model tests** validate backend payload parsing.
- **Service tests** validate HTTP methods, response handling, and timeout
  normalization using mock HTTP clients.
- **Controller tests** validate dashboard loading, selection, refresh-interval
  updates, stale-request suppression, and disposal during in-flight work.
- **Widget tests** cover list, table, and map interaction behavior.

Run frontend checks from the Flutter project directory when Flutter is
available:

```bash
cd live_flight_ops_dashboard_frontedn
flutter test
flutter analyze
```
