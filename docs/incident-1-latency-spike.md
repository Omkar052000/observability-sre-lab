# Incident 1: Latency spike in productcatalogservice

## Timeline (2026-11-07)
- ~18:13  Injected fault: `EXTRA_LATENCY=500ms` on productcatalogservice
- ~18:15  `boutique:slow_ratio:rate5m` rose above 0.2
- Alert fired:   `DemoHighLatency` alert fired
- Fault removed:    Fault removed (`EXTRA_LATENCY` unset, deployment rolled out)
- ~19:29  p95 latency back to normal; alert resolved

## Symptoms
- p95 latency rose from about 20 ms to about 800 ms for the frontend and checkout services.
- `boutique:slow_ratio:rate5m` rose from about 0.001 to about 0.6.
- Availability stayed at 100%, so users got correct answers, only slowly.
- Error rate showed a brief bump to about 0.05%.
- Request rate was unchanged, so the cause was not extra traffic.

## Diagnosis
1. The dashboard showed latency up at the frontend and checkout, with no change in traffic or CPU.
2. In Tempo, a search for traces over 400 ms showed a root request of about 535 ms.
3. The waterfall showed `ProductCatalogService/ListProducts` took about 502 ms, around 94% of the request. Other spans took a few milliseconds.
4. The span status was OK, so the call was slow, not failing.

## Root cause
`productcatalogservice` added about 500 ms to every call (injected with the `EXTRA_LATENCY` setting).

## Fix
Removed the `EXTRA_LATENCY` environment variable and let the deployment roll out.

## Lessons learned
- Availability alone showed nothing wrong, so a latency SLO and alert are needed alongside the availability SLO.
- Traces found the culprit quickly: the slow span was a child of the root, invisible from the dashboard alone.
- Alerting on `rate[5m]` is slow to fire and slow to clear. The dashboard lagged the fix by 5 to 10 minutes.
- Several services appear as `unknown_service` because they don't set a service name.

## Evidence
- `incident-1-slow-ratio.png`: slow ratio jumping from 0 to about 0.6
- `incident-1-dashboard-during.png`: dashboard during the incident (latency up, availability 100%)
- `incident-1-trace.png`: slow trace, ListProducts took 502 ms of 536 ms
- `incident-1-dashboard-recovered.png`: dashboard after the fix
- `incident-1-recovery-alert.png`: DemoHighLatency back to Inactive
