#!/usr/bin/env bash
set -euo pipefail

echo "=== RamOps: Verifying fix ==="
echo ""

POD=$(kubectl get pods -l app=log-processor -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD" ]; then
  echo "FAIL: No pod found with label app=log-processor"
  exit 1
fi

# Check that the pod is Running and Ready
PHASE=$(kubectl get pod "$POD" -o jsonpath='{.status.phase}')
READY=$(kubectl get pod "$POD" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')

echo "Pod:   $POD"
echo "Phase: $PHASE"
echo "Ready: $READY"
echo ""

if [ "$PHASE" != "Running" ] || [ "$READY" != "True" ]; then
  echo "FAIL: Pod is not Running/Ready yet. Keep debugging!"
  exit 1
fi

# Check disk space inside the pod
echo "Checking disk space inside pod..."
DISK_USAGE=$(kubectl exec "$POD" -- df -h /data | tail -1 | awk '{print $5}' | sed 's/%//')

echo "Disk usage on /data: ${DISK_USAGE}%"

if [ "$DISK_USAGE" -gt 90 ]; then
  echo "FAIL: /data is still $DISK_USAGE% full. Clean up files or increase volume size."
  exit 1
fi

# Wait and verify pod stays stable
echo ""
echo "Watching for stability (20s)..."
sleep 20

NEW_PHASE=$(kubectl exec "$POD" -- echo "ok" 2>/dev/null || echo "fail")

if [ "$NEW_PHASE" != "ok" ]; then
  echo "FAIL: Pod became unhealthy during verification."
  exit 1
fi

echo ""
echo "============================================"
echo "  PASSED"
echo "  The log-processor pod is running stably."
echo "  Disk usage is under control."
echo "============================================"
