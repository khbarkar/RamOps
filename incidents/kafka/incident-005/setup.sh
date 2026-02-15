#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLUSTER_NAME="kafka-disk-bound"

echo "=== RamOps: Kafka Disk-Bound Brokers (Kind) ==="
echo ""

if ! command -v kind &> /dev/null; then
  echo "ERROR: kind is not installed."
  echo "Install with: brew install kind"
  exit 1
fi

if ! command -v kubectl &> /dev/null; then
  echo "ERROR: kubectl is not installed."
  exit 1
fi

echo "Creating Kind cluster..."
kind create cluster --name "$CLUSTER_NAME" --wait 60s --quiet

echo "Deploying Kafka cluster..."
kubectl apply -f "$SCENARIO_DIR/manifests/zookeeper.yaml"
sleep 10

kubectl apply -f "$SCENARIO_DIR/manifests/kafka.yaml"
echo "Waiting for Kafka brokers to be ready..."
kubectl wait --for=condition=ready pod -l app=kafka -n kafka --timeout=180s

echo "Deploying monitoring..."
kubectl apply -f "$SCENARIO_DIR/manifests/monitoring.yaml"
kubectl wait --for=condition=ready pod -l app=prometheus -n kafka --timeout=60s
kubectl wait --for=condition=ready pod -l app=grafana -n kafka --timeout=60s

echo ""
echo "============================================"
echo "  SCENARIO: Kafka Disk-Bound Brokers"
echo "  SETUP COMPLETE"
echo ""
echo "  Access monitoring:"
echo "    kubectl port-forward -n kafka svc/grafana 3000:3000"
echo "    kubectl port-forward -n kafka svc/prometheus 9090:9090"
echo ""
echo "  Then open:"
echo "    Grafana: http://localhost:3000 (admin/admin)"
echo "    Prometheus: http://localhost:9090"
echo ""
echo "  Kafka brokers are experiencing slow disk I/O"
echo "  Consumer lag is growing despite available CPU"
echo ""
echo "  Debug with:"
echo "    kubectl get pods -n kafka"
echo "    kubectl logs -n kafka kafka-0"
echo "============================================"
