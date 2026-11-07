# Incident 3: Bad deploy (non-existent image tag)

## Timeline (2026-11-07)
- ~21:25  First attempt to deploy `currencyservice:v9.9.9` (pod rw9d7, deleted by a ReplicaSet scale-down)
- 21:34   Second attempt; new pod created (7zkv7), stuck in ErrImagePull then ImagePullBackOff
- TODO    Rolled back with `kubectl rollout undo`

## Symptoms
- `kubectl rollout status` timed out: "1 old replicas are pending termination".
- The new pod stayed `0/1` in `ErrImagePull`, then `ImagePullBackOff`.
- No user impact: availability stayed 100%, and latency and request rate did not change.
- The error budget panel was low only because of Incident 2 still inside the 1h window.

## Diagnosis
1. `rollout status` timed out.
2. `kubectl get pods` showed one `Running` pod (old) and one `ErrImagePull` pod (new).
3. `kubectl describe pod` Events showed `Failed to pull image ... v9.9.9: not found`.

## Root cause
The deployment referenced image tag `v9.9.9`, which does not exist in the registry.

## Fix
`kubectl rollout undo deploy/currencyservice`, restoring image `v0.10.7`.

## Lessons learned
- The rolling update kept the old pod serving, so users were protected.
- The SLO dashboard could not detect the stuck release. An alert on `kube_deployment_status_replicas_unavailable > 0` for 5 minutes would.
- A CI step that checks the image tag exists before deploying would have prevented it.
- The 1h error-budget window mixes the effects of separate incidents.

## Evidence
- `incident-3-events.png`: describe Events showing the pull failure
- `incident-3-dashboard.png`: dashboard during the stuck rollout
