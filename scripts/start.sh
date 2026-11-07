#!/bin/bash
docker start obs-lab-control-plane
echo "Waiting for pods..."
sleep 60
kubectl get pods -A | grep -vE "Running|Completed"
kubectl port-forward -n monitoring svc/kps-grafana 3000:80
