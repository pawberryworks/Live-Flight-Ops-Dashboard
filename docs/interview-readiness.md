# Live Flight Ops Dashboard: Interview Preparation Playbook

**Use this document as a rehearsal script, not as a claim that every production
concern is already solved.** It is tailored to the code in this repository and
separates implemented behavior from deliberate trade-offs and proposed next
steps.

## 1. Your 60-second introduction

> I built a full-stack operations dashboard for viewing aircraft-state data in
> a configurable geographic region. The Flutter client is responsible for the
> operator experience: map, list, table, selection, settings, and visible
> failure feedback. The ASP.NET Core service owns the integration with OpenSky.
> It polls the provider in a hosted background worker, validates and caches the
> latest successful snapshot, and exposes a small API to the client.
>
> I made two deliberate boundary decisions. First, browsers do not call the
> provider directly: one backend poll serves every dashboard client, which
> reduces provider traffic and gives all views a consistent snapshot. Second,
> UI widgets do not own HTTP orchestration: a controller coordinates loading,
> polling, selection, and lifecycle behavior through repository interfaces.
>
> For resilience, the last known good snapshot remains visible during a
> provider failure, while the user receives an error notification. Configuration
> is validated at startup and when changed at runtime. The demo deliberately
> keeps settings and cache process-local; for production I would add identity,
> durable/shared storage, observability, and integration coverage.

**Do not memorize every word.** Deliver the narrative naturally, then pause so
the interviewer can choose which design decision to explore.

## 2. System map and request flow

```text
OpenSky provider
    │ GET states/all?configured-bounds
    ▼
FlightStatesBackgroundService (ASP.NET Core hosted worker)
    │ validate/decode; only publish successful payloads
    ▼
IMemoryCache ──► FlightStatesService ──► /api/flightStates
    ▲                                                │
    │                                                ▼
RuntimeFlightSettings ◄── settings APIs      Flutter HTTP repositories
    │                                                │
    └── worker reads the latest values               ▼
                                      DashboardController ──► widgets
```

### Explain each boundary in one sentence

| Boundary | What it owns | Why it exists |
| --- | --- | --- |
| Hosted worker → cache | Provider polling and the latest successful response | API requests do not block on an external provider and clients avoid duplicate polling. |
| Cache → API service | Retrieval of the current snapshot | Controllers stay thin and do not know cache-key details. |
| Runtime settings → worker/controllers | Validated mutable bounds and refresh interval | A lock provides a consistent in-process setting snapshot. |
| Flutter service → repository | HTTP/JSON behavior behind an application-facing contract | Controller tests can use fakes and are not coupled to HTTP. |
| Controller → widgets | Loading, ready/failure, polling, selection, and error events | Rendering components remain focused on presentation and interaction. |

## 3. What to demonstrate live (five to seven minutes)

### Before the interview

1. Start the backend, wait for the first provider snapshot, and open the web
   app. Keep a terminal ready for the health endpoint.
2. Confirm the map has usable data before screen sharing. Do **not** depend on
   a live external-provider outage as your only failure demonstration.
3. Prepare a short fallback: screenshots or a recorded run showing the loading
   and error states if the provider is unavailable.
4. Know the configured geographic bounds and refresh interval so you can
   explain the data that appears.

### Demo sequence and narration

| Time | Action | Say this |
| --- | --- | --- |
| 0:00 | Open the map. | “The dashboard presents one cached provider snapshot across map, list, and table views.” |
| 0:45 | Select an aircraft on the map, then show the list. | “Selection belongs to the dashboard controller, so interactions remain coordinated across views.” |
| 1:30 | Open flight details from the list or table. | “The views reuse the same loaded model rather than requesting details independently.” |
| 2:15 | Open settings and enter an invalid interval such as `4`. | “The UI gives immediate feedback, and the backend enforces the same five-second lower bound so the API remains authoritative.” |
| 3:00 | Show `/health` and `/health/ready`. | “Liveness means the process can answer; readiness also means a snapshot has been obtained recently.” |
| 4:00 | Describe a provider failure. | “The worker logs the failure and preserves the last successful snapshot. The UI retains useful data and surfaces a notification instead of blanking the operator’s screen.” |
| 5:00 | Show the controller and worker source. | “These are the two places where the important asynchronous behavior lives; widgets do not perform the orchestration.” |
| 6:00 | Conclude with limitations. | “This is intentionally a single-process demo. Here is the production migration path I would take.” |

## 4. Technical deep dive: answers you should own

### Data freshness and reliability

**Question: Why does the backend cache flight states instead of proxying each
browser request to OpenSky?**

**Answer:** A backend poller puts a fixed upper bound on outbound provider
traffic regardless of browser count. It also makes the map, list, and table
start from the same response instead of racing independent upstream calls. The
trade-off is freshness: data is polling-based rather than streaming, and can
be older during an upstream failure.

**Question: What happens before the first successful provider request?**

**Answer:** There is no valid snapshot to represent as an empty flight set, so
the API returns `503 Service Unavailable`. That distinguishes “no aircraft in
this region” from “the dashboard is not ready.” The readiness health check is
also unhealthy until a snapshot exists.

**Question: What happens if OpenSky returns an error, times out, or sends bad
JSON?**

**Answer:** The worker catches request, timeout, and JSON failures and logs
them. It does not replace the cache on failure, so a previous valid snapshot
remains available. This is a deliberate availability-over-perfect-freshness
choice, and the readiness check becomes degraded once the snapshot is older
than two configured refresh intervals.

**Question: Is this truly real time?**

**Answer:** No. It is a polling dashboard. The normal freshness target is one
polling interval, but users must treat retained data as potentially older when
the provider is unavailable. I would expose server-observed snapshot age in
the dashboard API and UI before making stronger freshness claims.

**Question: What reliability improvements would you make?**

**Answer:** First add metrics for poll duration, success/failure, response
size, and snapshot age; then add bounded exponential backoff with jitter for
transient provider failures. I would define an explicit stale-data policy and
make that status visible in the UI. For multiple instances, I would use a
single coordinated ingestion worker or a lease, plus a shared cache.

### Frontend state and asynchronous behavior

**Question: Why use a controller instead of making HTTP calls in widgets?**

**Answer:** A widget should render state and forward user intent. The
controller gives one owner to initial loading, periodic refresh, selection,
error events, and disposal. Repository contracts make that behavior testable
with fakes and keep services at the infrastructure edge.

**Important wording:** The controller **coordinates** HTTP-backed work; it
does not implement HTTP itself. It asks repository interfaces for flight
states, bounds, and refresh settings. The HTTP repositories delegate transport,
timeouts, status handling, JSON decoding, and client cleanup to focused
services. This distinction prevents the controller from becoming a transport
layer while still putting the multi-request user workflow in one testable
place.

**Why this is better than HTTP calls in widgets:**

| Concern | Widget-owned HTTP | Controller-coordinated HTTP |
| --- | --- | --- |
| Rendering | Build methods must also account for request timing and transient failures. | Widgets receive loading, ready, or failure state and render it. |
| Cross-view consistency | Each map/list/table interaction can accidentally create its own request and state. | One controller owns the selected aircraft and the shared dashboard snapshot. |
| Lifecycle safety | Timers and late responses can outlive a widget or update the wrong screen. | The controller cancels its timer, invalidates older loads, and ignores work after disposal. |
| Testing | Widget tests need to simulate transport details to test workflow rules. | Controller tests use repository fakes to test workflow rules without HTTP. |
| Change isolation | A changed endpoint or JSON rule can force presentation changes. | Services absorb transport changes as long as repository contracts stay stable. |

**Trade-off:** This is not automatically better for every screen. A tiny,
one-shot widget with no shared state may be simpler with a local future. The
dashboard has coordinated views, recurring refresh, retry/failure behavior,
and lifecycle rules, so a controller is justified. If the controller grows
well beyond this feature, split it by use case or introduce a more explicit
state-management solution rather than letting it become a “god object.”

**Question: How do you avoid stale responses overwriting newer state?**

**Answer:** Initial loads use an incrementing generation. A result is ignored
if another load began after it. Disposal increments the generation too, so
in-flight work cannot update a closed controller.

**Question: Can refresh requests overlap?**

**Answer:** No. The periodic callback checks `_refreshInProgress` before it
starts a new flight-state request and clears the flag when the request
finishes. This protects a slow API from accumulating concurrent refreshes.

**Question: Why keep the previous data when a refresh fails?**

**Answer:** Replacing a usable snapshot with an empty/error view harms an
operator during a transient failure. The controller preserves the existing
ready state and emits a distinct error event, so the user has both continuity
and visibility of the problem.

**Question: What state is intentionally local to widgets?**

**Answer:** Presentation-only details such as table filtering, sorting,
pagination, dialogs, selected navigation tab, and theme control. They do not
need to be global or persisted by the backend-facing controller.

### API and backend design

**Question: How is configuration validated?**

**Answer:** Options validation rejects a non-HTTP(S) provider URL, invalid
latitude/longitude ranges or ordering, and an unsafe refresh interval during
startup. `RuntimeFlightSettings` validates updates again, so HTTP callers
cannot bypass the rules after startup.

**Question: Why are runtime settings protected by a lock?**

**Answer:** Controllers and the background worker can access settings at the
same time. The lock ensures each read sees a fully published bounds value or
interval, rather than a partially updated configuration.

**Question: Why use a named `HttpClient`?**

**Answer:** It centralizes the provider base URL and timeout while using
`IHttpClientFactory` to manage handler lifetime. The worker obtains the named
client rather than constructing `HttpClient` per poll.

**Question: Why separate liveness and readiness endpoints?**

**Answer:** A process can be healthy enough to serve an HTTP response while
still having no useful flight data. `/health` checks liveness; `/health/ready`
includes snapshot freshness so orchestration can make a better traffic or
alerting decision.

## 5. Interview question bank

Practice answering these out loud in 45–90 seconds. Start with the direct
answer, give one repository-specific example, and end with a trade-off.

### Architecture and trade-offs

1. Draw the architecture and identify the dependency direction.
2. Why did you choose this controller/repository approach over Provider,
   Bloc, Riverpod, Redux, or a state machine library?
3. Which decisions were driven by the product problem and which by the demo
   scope?
4. What would break if 1,000 clients opened the dashboard at once?
5. How would you split ingestion from the read API if this grew into a larger
   system?
6. How would you version this API without breaking the Flutter client?
7. Why is an in-memory cache acceptable here, and when is it not?
8. What are the consequences of serving a last-known-good response?

### Concurrency and failure handling

9. Explain the load generation and name the race condition it prevents.
10. What happens when the user retries while an initial load is still in
    flight?
11. What happens when the page is disposed while a request is in flight?
12. Why prevent overlapping periodic refreshes? What if a request takes longer
    than the interval?
13. How would you test timeout, malformed JSON, `503`, and a provider outage?
14. How would you choose a retry policy without overwhelming the provider?
15. How would you inform an operator that displayed data is stale?
16. What errors are user-facing, what errors are logged, and what information
    should never be shown to a user?

### Security and operations

17. What are the security issues with the settings endpoints today?
18. How would you design authorization for changing bounds versus viewing
    flights?
19. What does the development-only CORS policy protect, and what would change
    in production?
20. Which health checks, metrics, logs, and alerts would you add first?
21. How would you manage OpenSky credentials or rate limits if required?
22. How would you deploy this with multiple backend replicas?
23. What data-retention or privacy questions would you ask before production?

### Testing and quality

24. Which behavior has unit/widget coverage and which important behavior lacks
    integration coverage?
25. What would an API integration test prove that a unit test cannot?
26. How would you test the hosted worker without calling the real provider?
27. How would you make time-based tests deterministic?
28. What quality gates are present in CI, and what would you add to them?
29. How would you test accessibility for keyboard and screen-reader users?
30. How would you evaluate and improve the dashboard’s performance with a much
    larger aircraft collection?

## 6. Honest gap analysis and prioritized roadmap

Use this section when asked, “What would you do next?” A strong answer is
specific, ordered, and honest about why the work was not included.

| Priority | Improvement | Why it is next | First concrete increment |
| --- | --- | --- | --- |
| P0 | Explicit stale-data status | The user can see provider time but does not receive a clear server-side freshness state in the flight API/UI. | Return fetched-at/age and a freshness flag; render a warning when stale. |
| P0 | API integration tests | Current tests exercise important units, but controller routing/status/serialization should be verified together. | Use an in-memory test host to cover first-snapshot `503`, settings validation, and readiness transitions. |
| P1 | Observability and retry policy | Logs alone are insufficient to diagnose an upstream dependency. | Add structured poll metrics, correlation-friendly logs, and bounded backoff with jitter. |
| P1 | Authentication and authorization | Runtime settings mutate shared operational behavior. | Add identity, roles, audit logs, and endpoint policies. |
| P1 | Production deployment model | Process-local cache/settings do not coordinate replicas or survive restarts. | Move configuration and snapshots to durable/shared infrastructure; coordinate ingestion. |
| P2 | Load and accessibility testing | A demo dataset and manual UI checks do not establish operational scale or inclusive access. | Define target data volume, profile rendering, and add keyboard/screen-reader acceptance tests. |

### Phrase risky areas accurately

- Say **“polling-based live operational view”**, not “guaranteed real-time
  flight tracking.”
- Say **“local-development CORS policy”**, not “production CORS security.”
- Say **“last successful snapshot is retained”**, not “data is always current.”
- Say **“a deliberately small single-process deployment model”**, not
  “horizontally scalable.”
- Say **“the API is unauthenticated in this demo and needs protection before
  production”**, rather than avoiding the subject.

## 7. Rehearsal checklist

### The day before

- [ ] Read the README architecture and this playbook, then explain the system
      without looking at either document.
- [ ] Run backend tests and Flutter analysis/tests on a machine with the
      required SDKs.
- [ ] Rehearse the 60-second introduction, then the seven-minute demo.
- [ ] Prepare a fallback screenshot/video and sample failure explanation.
- [ ] Check that the provider, local certificate, and browser setup work.

### Immediately before the interview

- [ ] Start the backend early and confirm a first snapshot exists.
- [ ] Open `/health` and `/health/ready`; understand why their results differ.
- [ ] Refresh the browser and confirm the loading-to-ready path works.
- [ ] Have these files open in tabs: `Program.cs`,
      `FlightStatesBackgroundService.cs`, `DashboardController`, and the test
      directories.
- [ ] Be ready to state one trade-off you would keep and one you would change.

### If you do not know an answer

Use this structure instead of guessing: **clarify the requirement → state the
current behavior → identify the risk → propose a measured next step.** For
example: “For multiple replicas, the current in-memory design would not share
snapshots. I would first clarify consistency and cost requirements, then use a
shared cache and coordinate the ingest worker. I would validate that design
with load and failure tests.”
