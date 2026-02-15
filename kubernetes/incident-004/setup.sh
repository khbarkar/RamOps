#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="ramops-incident-004"
SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Incident-004 ==="
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
echo "Deploying log processor application..."
kubectl apply -f "$SCENARIO_DIR/manifests/app.yaml"

echo ""
echo "Waiting for pod to start filling disk (30s)..."
sleep 30

echo ""
echo "============================================"
echo "  SCENARIO ACTIVE"
echo "  The 'log-processor' pod is experiencing issues."
echo ""
echo "  User report:"
echo "    'The log processor keeps crashing with weird errors.'"
echo "    'Sometimes it works, then crashes again after a few minutes.'"
echo ""
echo "  Your task: figure out what's wrong and fix it"
echo ""
echo "  Debug commands:"
echo "    kubectl get pods"
echo "    kubectl describe pod <pod-name>"
echo "    kubectl logs <pod-name>"
echo "============================================"
echo ""
echo "Run verify.sh when you think you've fixed it."
