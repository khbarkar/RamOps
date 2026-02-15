#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLUSTER_NAME="sidechannel-attack"

echo "=== RamOps: Side-Channel Attack via CPU Cache Timing ==="
echo ""

if ! command -v kind &> /dev/null; then
  echo "ERROR: kind is not installed."
  echo "Install with: brew install kind"
  exit 1
fi

echo "Creating Kind cluster..."
kind create cluster --name "$CLUSTER_NAME" --wait 60s --quiet

echo "Deploying victim and attacker pods..."
kubectl apply -f "$SCENARIO_DIR/manifests/"

echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=victim --timeout=60s
kubectl wait --for=condition=ready pod -l app=attacker --timeout=60s

echo ""
echo "============================================"
echo "  SCENARIO: Side-Channel Attack"
echo "  SETUP COMPLETE"
echo ""
echo "  Attacker pod performing cache timing attack"
echo "  Attempting to leak secrets from victim pod"
echo ""
echo "  Investigate with:"
echo "    kubectl get pods"
echo "    kubectl exec -it attacker -- cat /proc/cpuinfo"
echo "    kubectl exec -it attacker -- cat /sys/devices/system/cpu/vulnerabilities/*"
echo ""
echo "  Monitor attack:"
echo "    kubectl exec -it attacker -- perf stat -e cache-misses,cache-references sleep 5"
echo ""
echo "  WARNING: This is an expert-level scenario"
echo "  Requires understanding of CPU architecture"
echo "============================================"
