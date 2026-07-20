# Interview Readiness Review

**Assessment date:** 2026-07-20
**Overall readiness:** **strong for a full-stack take-home or junior-to-mid
level technical interview (7.5/10).** The project has a clear user outcome,
separated frontend and backend responsibilities, defensive configuration, and
automated checks. The strongest demonstration is the end-to-end operator flow:
inspect live aircraft, select an aircraft, adjust the refresh interval, and
explain what happens when the upstream provider fails.

## What to lead with

1. **State the problem and scope.** This is an operations dashboard over a
   configured geographic area, not a flight tracker intended to be a source of
   truth for safety-critical decisions.
2. **Explain the data boundary.** The backend, rather than every browser,
   polls OpenSky and publishes its last successful snapshot. That limits
   provider traffic and keeps a consistent dataset across dashboard views.
3. **Walk through the controller.** `DashboardController` coordinates the
   initial parallel data load, selection, periodic refresh, failure
   notification, and disposal. This makes the UI a rendering layer rather than
   a place for HTTP orchestration.
4. **Show operational thinking.** Startup options are validated; settings are
   validated again at runtime; the backend distinguishes liveness from
   readiness; and the repository has CI for backend tests plus Flutter analysis
   and tests.
5. **Close with trade-offs.** The system deliberately uses process-local
   mutable settings and an in-memory cache to keep the demo small. Explain the
   production migration path instead of presenting those choices as complete.

## Evidence to point out

| Interview signal | Evidence | Why it matters |
| --- | --- | --- |
| Intentional frontend boundaries | Widget, controller, repository, service, and configuration layers are documented and implemented. | Shows dependency direction and testability without introducing a heavy state-management framework. |
| Async correctness | Loads use a generation counter; polling prevents overlap; disposal cancels the timer and ignores obsolete work. | Demonstrates awareness of common UI race and lifecycle problems. |
| Failure behavior | Failed refreshes retain the last successful data and generate a visible error event; initial-load failures show a retry state. | Gives a concrete answer to “what happens when a dependency is down?” |
| Configuration safety | Provider URL, bounds, and minimum polling interval are validated at startup and before runtime mutation. | Makes invalid inputs fail predictably rather than becoming delayed operational defects. |
| Operational visibility | `/health` is liveness-only, while `/health/ready` evaluates snapshot freshness. | Communicates the difference between a running process and usable data. |
| Quality gates | GitHub Actions runs backend tests, Flutter analysis, and Flutter tests. | Demonstrates repeatable verification rather than relying solely on manual testing. |

## Questions to prepare for

### Why cache on the backend?

Polling once per configured interval bounds outbound requests to OpenSky and
means every client receives the same recent snapshot. The trade-off is data
age: a provider failure leaves last-known-good data available. Readiness turns
degraded once the snapshot is older than two refresh intervals.

### Why not put all state in widgets?

The controller centralizes backend-facing lifecycle concerns and is exercised
with repository fakes. Widget-local state is limited to presentation concerns
such as table filtering, sorting, and dialogs, which avoids making domain state
global without a need.

### How would this scale beyond a demo?

Move the snapshot and mutable configuration to shared infrastructure, run a
single ingestion worker or coordinate workers, protect update endpoints with
authenticated role-based authorization, and add a production CORS policy.

### What would you improve next?

Prioritize these items in this order:

1. Add API-level integration tests that cover controller contracts, `503`
   before the first snapshot, and readiness transitions.
2. Make snapshot freshness explicit in the flight-state API/UI rather than
   showing only the provider timestamp; the sidebar currently presents an
   “Operations online” message even when retained data may be stale.
3. Add bounded retry/backoff and metrics for provider request duration,
   success/failure, and snapshot age.
4. Add authenticated, role-scoped settings changes and a durable/shared store
   before introducing multiple backend instances.

## Demo checklist

Before an interview, run the backend and Flutter web app, then verify the
following manually:

- The initial dashboard moves from loading to map/list/table data.
- Selecting a flight on the map or list keeps selection coordinated.
- The flight details dialog works from both list and table flows.
- A refresh interval below five seconds is rejected in the UI.
- A temporary backend outage leaves the last successful data visible and shows
  the backend-error notification.
- `/health` returns healthy while `/health/ready` becomes healthy only after a
  successful provider snapshot.

Also run the repository checks documented in the README. If local SDKs are
unavailable, say so plainly and use CI results rather than claiming a local
green run.

## Presentation cautions

- Do not overclaim “real time”: the data is polling-based and can be as old as
  the refresh interval (or older during a provider outage).
- Do not describe the demo’s local-development CORS policy, in-memory cache,
  or unauthenticated settings endpoints as production-ready.
- Be ready to explain the existing directory-name spelling as a compatibility
  choice, not an overlooked detail.
