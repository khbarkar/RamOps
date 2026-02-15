#!/usr/bin/env bash
set -euo pipefail

echo "=== RamOps: Verifying fix ==="
echo ""

NOT_READY=$(kubectl get nodes --no-headers | grep -c "NotReady" || true)

if [ "$NOT_READY" -gt 0 ]; then
  echo "FAIL: $NOT_READY node(s) still NotReady."
  kubectl get nodes
  exit 1
fi

TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l | tr -d ' ')
READY_NODES=$(kubectl get nodes --no-headers | grep -c " Ready" || true)

echo "Nodes: $READY_NODES/$TOTAL_NODES Ready"

if [ "$READY_NODES" -ne "$TOTAL_NODES" ]; then
  echo "FAIL: Not all nodes are Ready."
  exit 1
fi

echo ""
echo "Checking pod health..."
NOT_RUNNING=$(kubectl get pods --no-headers | grep -cv "Running" || true)

if [ "$NOT_RUNNING" -gt 0 ]; then
  echo "WARN: Some pods are not Running yet. Give them a moment."
  kubectl get pods -o wide
  exit 1
fi

echo ""
echo "============================================"
echo "  PASSED"
echo "  All nodes are Ready and pods are running."
echo "============================================"
