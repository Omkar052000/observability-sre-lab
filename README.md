# Observability & SLO Monitoring Lab

A hands-on observability lab on Kubernetes: metrics, logs and traces for a microservices app, a golden-signals dashboard, SLO-based alerting, and three documented failure-injection incidents.

Demo app: [Google Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo). Cluster: local `kind`.

## Architecture

```
Online Boutique pods
   |-- traces (OTLP) --> OpenTelemetry Collector (contrib) --> Tempo
   |                          |-- spanmetrics --> Prometheus
   |-- logs --> Grafana Alloy --> Loki
Prometheus (kube-prometheus-stack) --> Alertmanager
Grafana: dashboards, Explore, trace-to-logs links
```

## Stack

| Signal | Tools |
|---|---|
| Metrics | Prometheus, kube-prometheus-stack, OTel spanmetrics connector |
| Logs | Loki, Grafana Alloy |
| Traces | OpenTelemetry Collector (contrib), Tempo |
| Dashboards | Grafana |
| Alerting | PrometheusRule, Alertmanager |

## What is in this repo

- `helm-values/` - Helm values and manifests (Loki, Alloy, Tempo, Collector, ServiceMonitor, SLO rules and alerts)
- `dashboards/` - Grafana dashboard JSON (golden signals + SLO panels)
- `scripts/` - helper scripts (enable tracing)
- `docs/` - screenshots and incident write-ups

## SLOs

- **Availability:** 99% of requests succeed (error budget 1%)
- **Latency:** 95% of requests complete in under 100 ms

Recording rules compute error and slow ratios over 5m and 1h windows. Burn-rate alerts require both windows to agree, which avoids false alarms on brief spikes. Short-window demo alerts (`slo-demo-alerts.yaml`) were added so alerts fire within a few minutes during experiments.

## Failure-injection incidents

| # | Incident | Key finding |
|---|---|---|
| 1 | [Latency spike](docs/incident-1-latency-spike.md) | A single slow downstream call (ListProducts, ~502 ms) found via a Tempo trace; availability stayed 100% |
| 2 | [Wrong Redis address](docs/incident-2-bad-redis-config.md) | Pod stayed Running/Ready while ~30% of requests failed; only SLO metrics caught it |
| 3 | [Bad deploy (missing image tag)](docs/incident-3-bad-deploy.md) | Rolling update protected users; the stuck rollout was visible only via `rollout status` and pod events |

## Troubleshooting notes

- The `k8s` Collector build lacks the Prometheus exporter, so the contrib distribution is used.
- Some services appear as `unknown_service` because they do not set a service name.
- `emailservice` crashed with tracing enabled, so tracing is not enabled for it.
- The kind control-plane alerts (`kube-system`) are expected and ignored.
- Tempo persistence is off, so traces are lost on restart.

## Run it

1. `kind create cluster --name obs-lab`
2. Deploy Online Boutique into the `boutique` namespace.
3. Install kube-prometheus-stack, Loki, Alloy, Tempo and the Collector with the files in `helm-values/`.
4. Apply `servicemonitor-otel.yaml`, `slo-rules.yaml`, `slo-alerts.yaml` and `slo-demo-alerts.yaml`.
5. Run `scripts/enable-tracing.sh`, then import `dashboards/boutique-golden-signals.json` into Grafana.
