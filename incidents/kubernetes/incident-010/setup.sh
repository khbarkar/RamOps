#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="ramops-exposed-secrets"
SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Exposed Database Credentials ==="
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
echo "Deploying application with exposed credentials..."
kubectl apply -f "$SCENARIO_DIR/manifests/app.yaml"

echo ""
echo "Waiting for pod to start..."
kubectl wait --for=condition=ready --timeout=60s pod -l app=web-app

echo ""
echo "============================================"
echo "  SCENARIO ACTIVE"
echo "  A security audit has flagged this deployment."
echo ""
echo "  Your task: Find and fix the security vulnerability."
echo ""
echo "  Investigation commands:"
echo "    kubectl get configmaps"
echo "    kubectl describe configmap app-config"
echo "    kubectl get secrets"
echo "    kubectl get deployment web-app -o yaml"
echo ""
echo "  Fix commands:"
echo "    kubectl create secret generic <name> --from-literal=..."
echo "    kubectl edit deployment web-app"
echo "============================================"
echo ""
echo "Run verify.sh when you think you've fixed it."
