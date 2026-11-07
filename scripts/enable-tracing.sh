#!/bin/bash
for d in frontend checkoutservice productcatalogservice recommendationservice currencyservice paymentservice shippingservice; do
  kubectl set env -n boutique deploy/$d \
    ENABLE_TRACING=1 \
    COLLECTOR_SERVICE_ADDR=otel-collector.monitoring.svc.cluster.local:4317
done
