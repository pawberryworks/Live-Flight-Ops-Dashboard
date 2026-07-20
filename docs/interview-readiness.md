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

### Model answers for the question bank

These are concise answers to rehearse. Expand with the relevant code walkthrough
when the interviewer asks a follow-up; do not deliver all of the detail unless
it is useful.

#### Architecture and trade-offs

**1. Draw the architecture and identify the dependency direction.**

The Flutter presentation layer depends on `DashboardController`, which depends
on repository contracts. HTTP repository implementations depend on focused
services and API configuration. On the server, controllers depend on services,
while a hosted worker owns provider polling and publishes the cached snapshot.
The dependency direction keeps UI/application code independent of transport
details, so implementations can be changed or faked at the edge.

**2. Why choose this approach rather than Provider, Bloc, Riverpod, Redux, or
a state-machine library?**

The feature has one coherent dashboard workflow and can be expressed clearly
with `ChangeNotifier`, immutable state values, and repository contracts. That
keeps the dependency footprint small and the asynchronous rules visible. For a
larger app with many independently composed feature states, I would evaluate a
more structured state-management tool; the principle of separating UI from
workflow and transport would remain.

**3. Which decisions were product-driven versus demo-scoped?**

Backend polling, one shared snapshot, coordinated aircraft selection, and
retaining data during a transient failure are product-driven operational
decisions. Process-local settings, an in-memory cache, development-only CORS,
and unauthenticated settings endpoints are demo-scope choices that would not
be sufficient in production.

**4. What breaks with 1,000 clients?**

The provider is protected because the backend still polls once, not once per
client. The single process may instead become constrained by API throughput,
memory, connection handling, and rendering on clients. I would load-test the
API and UI, add horizontal replicas behind a load balancer, and replace
process-local state with shared storage and coordinated ingestion.

**5. How would you split ingestion from the read API?**

Make ingestion a separately deployed worker that polls the provider and writes
validated snapshots plus metadata to shared storage. The read API would only
serve that store and expose freshness. This allows each part to scale and fail
independently; worker coordination prevents duplicate provider polling.

**6. How would you version the API?**

Start with additive, backward-compatible fields and tolerant client parsing.
For a breaking contract, introduce an explicit versioned route or negotiated
media type, support both versions during migration, contract-test them, and
remove the old version only after consumers move.

**7. Why is the in-memory cache acceptable here, and when is it not?**

It is appropriate for a small single-instance demo because it is simple and
fast. It is not sufficient when snapshots must survive restarts, be consistent
between replicas, or be audited; then I would use a shared cache or data store.

**8. What are the consequences of last-known-good data?**

It preserves operational context during a short outage but risks users acting
on stale information. The mitigation is an explicit freshness indicator,
readiness degradation, clear operator messaging, and a defined point at which
stale data is no longer served or is prominently marked.

#### Concurrency and failure handling

**9. Explain the load generation and the race it prevents.**

Each initial load receives a monotonically increasing generation number. When
the request completes, the controller applies the result only if its generation
is still current. A slower old request therefore cannot overwrite the result of
a newer retry, and disposal invalidates outstanding generations as well.

**10. What happens if the user retries during the initial load?**

The retry starts a new generation and cancels the refresh timer. The original
request may still complete, but its result is ignored because its generation
does not match. The newer request is the only one permitted to publish state.

**11. What happens on disposal during a request?**

The controller marks itself disposed, increments the generation, cancels its
timer, disposes owned resources, and prevents later state notifications. The
network operation may complete, but it cannot update a dead UI owner.

**12. Why prevent overlapping periodic refreshes?**

Without the guard, a slow request could cause timer ticks to pile up, consume
connections, return out of order, and make the provider load worse. The
controller permits only one refresh at a time; when it completes, the next
timer tick can try again.

**13. How would you test timeouts, bad JSON, `503`, and an outage?**

Use fake or mock HTTP clients to return a delayed future, malformed payload,
and status response deterministically. Assert services normalize failures,
then use repository fakes to prove the controller retains ready data and emits
an error event. At API level, use an in-memory host and controlled cache to
verify the first-snapshot `503` and readiness results.

**14. How would you choose a retry policy?**

Classify errors first: do not retry validation failures, but retry selected
timeouts and transient HTTP failures. Use capped exponential backoff with
jitter, respect provider rate limits and `Retry-After`, expose attempt metrics,
and stop promptly on application shutdown.

**15. How would you show stale data to an operator?**

Return the backend fetch time or computed age with the snapshot, compare it to
an agreed freshness threshold, and display an unmissable warning/badge with
the age and last successful update time. It should not rely only on a provider
timestamp because that does not prove when this backend successfully fetched
the response.

**16. Which errors are user-facing versus logged?**

Users receive a clear, actionable message such as “Flight data could not be
refreshed; showing the last update,” without internal URLs, stack traces, or
credentials. Logs and telemetry hold structured diagnostic details, status
codes, timings, and safe correlation identifiers; secrets and sensitive
payloads must be redacted.

#### Security and operations

**17. What is insecure about settings endpoints today?**

They change shared operational behavior and the demo does not have application
authentication or role-based authorization. An unauthorized caller could
change bounds or increase polling frequency. Production needs identity, roles,
auditing, validation/rate limits, and an intentional network exposure model.

**18. How would you authorize settings changes versus viewing flights?**

Define separate policies, for example a read-only operator/viewer role for
flight data and an operations-admin role for bounds and refresh settings. Use
server-enforced claims, record who changed what and when, and consider approval
or change-control requirements for high-impact settings.

**19. What does development CORS do, and what changes in production?**

The development policy allows absolute `localhost` origins so a local Flutter
web app can call the local API. It is not a production access-control system.
Production should use a specific allow-list of owned origins, HTTPS, identity,
and ideally same-origin hosting where practical.

**20. Which operational signals would you add first?**

Track provider poll duration, success/failure count by reason, snapshot age,
response size, API latency/error rate, and configuration changes. Alert on no
snapshot, sustained stale data, elevated provider failures, and abnormal poll
latency; keep health endpoints for orchestration rather than using them as the
only observability mechanism.

**21. How would you handle provider credentials or rate limits?**

Store credentials in a secret manager and inject them through configuration,
never in source or logs. Use a named client/auth handler, enforce the minimum
interval, observe provider quotas, respect rate-limit headers, and use the
retry/backoff policy to avoid turning errors into abusive traffic.

**22. How would you deploy multiple replicas?**

Put stateless read API replicas behind a load balancer, move snapshots and
configuration to shared durable infrastructure, and make only one worker poll
at a time through leader election, a distributed lock, or a separate ingestion
deployment. Test worker failover so ingestion resumes without duplicate bursts.

**23. What privacy/retention questions would you ask?**

Identify the data licence, allowed uses, whether aircraft/operator data is
personal or commercially sensitive in the relevant jurisdiction, retention
period, access logs, audit needs, and whether location history can be exported.
Collect only what the operator needs and document deletion/retention controls.

#### Testing and quality

**24. What is covered and what is missing?**

The repository has Flutter model, service, controller, and widget tests, plus
backend tests for settings validation, option validation, health checks, and
JSON conversion. The important missing layer is end-to-end API integration
coverage for routing, serialization, status behavior, and hosted-worker
interaction under controlled dependencies.

**25. What does an API integration test prove that a unit test cannot?**

It exercises the real application composition: dependency injection, routing,
model binding, response serialization, middleware, and HTTP status codes.
For example, it can prove an empty cache produces the documented `503` through
the actual route, not just that a service returns `null` in isolation.

**26. How would you test the hosted worker without the real provider?**

Inject a fake named HTTP message handler/client that returns controlled
responses and use a short, test-controlled interval or an extracted polling
operation. Assert the cache changes only after a valid response and remains
unchanged after failures. Avoid real time by injecting a clock or delay
abstraction if the loop itself is tested.

**27. How would you make time-based tests deterministic?**

Avoid wall-clock sleeps. Inject a clock for timestamps and a scheduler/timer or
delay abstraction for polling; then advance fake time in the test. This makes
freshness thresholds, retries, and periodic behavior fast and repeatable.

**28. What quality gates exist and what would you add?**

GitHub Actions runs backend tests and Flutter dependency installation,
analysis, and tests. I would add formatting checks, dependency/security
scanning, API integration tests, coverage trend reporting, and perhaps a
smoke test against a deployed non-production environment.

**29. How would you test accessibility?**

Start with semantic labels, keyboard navigation, focus order, contrast, text
scaling, and screen-reader announcements for selection and errors. Add widget
tests for semantics/focus where possible, then perform manual testing with
screen-reader and keyboard-only workflows on supported browsers.

**30. How would you handle much larger aircraft collections?**

Measure first: profile API payload size, JSON decode time, controller updates,
map marker painting, list/table build cost, memory, and frame time. Then use
server-side filtering/pagination or viewport queries, client-side lazy lists
and marker clustering/virtualization, response compression, and incremental
updates only if profiling proves they are needed.

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
