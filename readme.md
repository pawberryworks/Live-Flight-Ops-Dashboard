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

The ASP.NET Core backend separates API delivery from data ingestion. A hosted
worker polls OpenSky with a named `HttpClient`, converts OpenSky's positional
state arrays into backend DTOs, and stores the latest successful response in
memory. Controllers read that snapshot, so dashboard clients never invoke the
external provider directly.

```text
OpenSky API → FlightStatesBackgroundService → IMemoryCache
                                             ↓
Flutter client ← API controllers ← application services
```

`OpenSkyOptions` validates the startup URL, refresh interval, and geographic
bounds. `RuntimeFlightSettings` owns validated, thread-safe runtime updates to
the interval and bounds; these updates are intentionally process-local and are
reset when the backend restarts. Deploy a shared durable settings store and a
distributed flight-state cache before running multiple backend instances.

Refresh intervals must be at least five seconds, both in startup configuration
and through the runtime update endpoint.

The backend exposes `/health` for liveness checks. The OpenSky HTTP client has
a bounded timeout, and the worker logs request, timeout, and payload failures
while retaining the last successful snapshot.

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
