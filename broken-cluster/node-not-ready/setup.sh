#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="ramops-node-notready"
SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Node Goes NotReady ==="
echo ""

for cmd in kind kubectl docker; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: '$cmd' is required but not installed."
    exit 1
  fi
done

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster '${CLUSTER_NAME}' already exists. Deleting..."
  kind delete cluster --name "$CLUSTER_NAME"
fi

echo "Creating Kind cluster '${CLUSTER_NAME}' with 3 nodes..."
kind create cluster --name "$CLUSTER_NAME" --config "$SCENARIO_DIR/manifests/kind-config.yaml" --wait 60s

echo ""
echo "Deploying workload across nodes..."
kubectl apply -f "$SCENARIO_DIR/manifests/deployment.yaml"
kubectl rollout status deployment/backend-api --timeout=60s

echo ""
echo "All pods running. Now simulating node failure..."

# Pick one of the worker nodes and pause its container to simulate NotReady
WORKER_NODE=$(kubectl get nodes --no-headers -l '!node-role.kubernetes.io/control-plane' -o custom-columns=':metadata.name' | head -1)
WORKER_CONTAINER="${CLUSTER_NAME}-${WORKER_NODE##*-}"

# The Kind container name matches the node name
docker pause "$WORKER_NODE"

echo "Waiting for Kubernetes to detect the failure (~40s)..."
sleep 40

echo ""
echo "============================================"
echo "  SCENARIO ACTIVE"
echo "  One of the cluster nodes has gone NotReady."
echo "  Your tasks:"
echo "    1. Identify which node is down"
echo "    2. Understand the impact on running pods"
echo "    3. Recover the node"
echo ""
echo "  Start with:"
echo "    kubectl get nodes"
echo "    kubectl get pods -o wide"
echo "============================================"
echo ""
echo "Run verify.sh when all nodes are Ready again."
