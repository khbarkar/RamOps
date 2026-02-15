#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="ramops-memory-leak"
SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Memory Leak in Production ==="
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
echo "Deploying metrics-server for resource monitoring..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

echo ""
echo "Waiting for metrics-server to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/metrics-server -n kube-system

echo ""
echo "Deploying application with memory leak..."
kubectl apply -f "$SCENARIO_DIR/manifests/app.yaml"

echo ""
echo "Waiting for pod to start..."
sleep 10

echo ""
echo "============================================"
echo "  SCENARIO ACTIVE"
echo "  The 'data-processor' service is running but unstable."
echo ""
echo "  Your task: figure out why it keeps dying and fix it."
echo ""
echo "  Useful commands:"
echo "    kubectl get pods -w"
echo "    kubectl describe pod <pod-name>"
echo "    kubectl top pod <pod-name>"
echo "    kubectl logs <pod-name>"
echo "    kubectl edit deployment data-processor"
echo "============================================"
echo ""
echo "Run verify.sh when you think you've fixed it."
