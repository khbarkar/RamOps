#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="openram-crashloop"
SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== openRam: Single Pod Crashloop ==="
echo ""

# Check prerequisites
for cmd in kind kubectl; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: '$cmd' is required but not installed."
    exit 1
  fi
done

# Create cluster (delete existing if present)
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster '${CLUSTER_NAME}' already exists. Deleting..."
  kind delete cluster --name "$CLUSTER_NAME"
fi

echo "Creating Kind cluster '${CLUSTER_NAME}'..."
kind create cluster --name "$CLUSTER_NAME" --wait 60s

echo ""
echo "Deploying broken workload..."
kubectl apply -f "$SCENARIO_DIR/manifests/deployment.yaml"

echo ""
echo "Waiting for pod to enter CrashLoopBackOff (this takes ~30s)..."
sleep 30

echo ""
echo "============================================"
echo "  SCENARIO ACTIVE"
echo "  The 'web-frontend' deployment is unhealthy."
echo "  Your task: figure out why and fix it."
echo ""
echo "  Hints:"
echo "    kubectl get pods"
echo "    kubectl describe pod <pod-name>"
echo "    kubectl logs <pod-name>"
echo "============================================"
echo ""
echo "Run verify.sh when you think you've fixed it."
