#!/usr/bin/env bash
set -euo pipefail

echo "=== RamOps: Verifying fix ==="
echo ""

POD=$(kubectl get pods -l app=web-frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD" ]; then
  echo "FAIL: No pod found with label app=web-frontend"
  exit 1
fi

# Check that the pod is Running and Ready
PHASE=$(kubectl get pod "$POD" -o jsonpath='{.status.phase}')
READY=$(kubectl get pod "$POD" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
RESTARTS=$(kubectl get pod "$POD" -o jsonpath='{.status.containerStatuses[0].restartCount}')

echo "Pod:      $POD"
echo "Phase:    $PHASE"
echo "Ready:    $READY"
echo "Restarts: $RESTARTS"
echo ""

if [ "$PHASE" != "Running" ] || [ "$READY" != "True" ]; then
  echo "FAIL: Pod is not Running/Ready yet. Keep debugging!"
  exit 1
fi

# Wait a bit and check restarts haven't increased
echo "Watching for stability (15s)..."
sleep 15
NEW_RESTARTS=$(kubectl get pod "$POD" -o jsonpath='{.status.containerStatuses[0].restartCount}')

if [ "$NEW_RESTARTS" -gt "$RESTARTS" ]; then
  echo "FAIL: Pod restarted again during verification. The fix isn't stable."
  exit 1
fi

echo ""
echo "============================================"
echo "  PASSED"
echo "  The pod is running and stable."
echo "============================================"
