# Incident 2: Wrong Redis address on cartservice

## Timeline (2026-11-07)
- ~20:44  Injected fault: `REDIS_ADDR=redis-wrong:6379` on cartservice
- ~20:45  Error rate and p95 latency started rising
- ~20:47  DemoHighErrorRate and DemoHighLatency firing
- 20:49  Fault removed (`REDIS_ADDR=redis-cart:6379`, deployment rolled out)
- ~20:57  Error rate back to 0, availability 100%; alerts resolved

## Symptoms
- Error rate rose to about 30%; availability fell to about 70%.
- p95 latency rose from about 20 ms to 8-10 s.
- Request rate fell from about 50 to about 10 req/s as failing users backed off.
- The pod stayed `Running` and `Ready` with 0 restarts, so pod status looked healthy.
- Only the short-window demo alerts fired. The Day 4 burn-rate alerts stayed Inactive because they need the 1-hour window to agree.

## Diagnosis
1. The dashboard showed errors and latency up, with request rate falling.
2. `kubectl get pods` showed every pod healthy. `kubectl describe` showed `REDIS_ADDR=redis-wrong:6379` and one liveness probe timeout.
3. `kubectl logs` showed `RedisConnectionException: UnableToConnect on redis-wrong:6379` and `FailedPrecondition: Can't access cart storage`.

## Root cause
A wrong `REDIS_ADDR` on cartservice. The hostname does not exist, so every cart call failed after a 5-second connection timeout.

## Fix
Set `REDIS_ADDR` back to `redis-cart:6379` and let the deployment roll out.

## Lessons learned
- The liveness and readiness probes check only the gRPC port, so a broken dependency went unnoticed. A readiness probe that checks Redis would keep a bad pod out of service.
- Pod status was green, so only user-facing SLO metrics caught the problem.
- 5-second dependency timeouts turned an error incident into a latency incident too. Shorter timeouts or a circuit breaker would limit this.
- The 1h error-budget panel lags recovery by up to an hour.
- I expected a crash loop, but the pod stayed Running. That is the more realistic failure.

## Evidence
- `incident-2-dashboard-during.png`: dashboard during the incident
- `incident-2-alerts-firing.png`: demo alerts firing
- `incident-2-alertmanager.png`: alerts in Alertmanager
- `incident-2-alerts-recovered.png`: alerts back to Inactive
- `incident-2-dashboard-recovered.png`: dashboard after the fix
