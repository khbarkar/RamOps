#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="ramops-dns-outage"
SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: DNS Outage ==="
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
echo "Deploying application services..."
kubectl apply -f "$SCENARIO_DIR/manifests/app.yaml"

echo ""
echo "Waiting for baseline stability (20s)..."
sleep 20

echo ""
echo "Breaking CoreDNS configuration..."
kubectl apply -f "$SCENARIO_DIR/manifests/broken-coredns.yaml"

echo ""
echo "Restarting CoreDNS to pick up broken config..."
kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system --timeout=30s || true

echo ""
echo "Waiting for DNS failures to propagate (30s)..."
sleep 30

echo ""
echo "============================================"
echo "  SCENARIO ACTIVE"
echo "  DNS resolution is broken cluster-wide."
echo ""
echo "  Symptoms:"
echo "    - 'backend' pod cannot resolve 'database' service"
echo "    - DNS lookups timing out or failing"
echo "    - CoreDNS may be crash-looping"
echo ""
echo "  Your task: diagnose and fix the DNS system"
echo ""
echo "  Debug commands:"
echo "    kubectl get pods -n kube-system -l k8s-app=kube-dns"
echo "    kubectl logs -n kube-system -l k8s-app=kube-dns"
echo "    kubectl get configmap coredns -n kube-system -o yaml"
echo ""
echo "  Test DNS resolution:"
echo "    kubectl exec -it deploy/backend -- nslookup database"
echo "    kubectl exec -it deploy/backend -- nslookup kubernetes.default"
echo "============================================"
echo ""
echo "Run verify.sh when you think you've fixed it."
