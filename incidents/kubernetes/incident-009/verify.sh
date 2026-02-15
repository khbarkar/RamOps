#!/usr/bin/env bash
set -euo pipefail

echo "=== RamOps: Verifying fix ==="
echo ""

POD=$(kubectl get pods -l app=data-processor -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD" ]; then
  echo "FAIL: No pod found with label app=data-processor"
  exit 1
fi

# Check that the pod is Running
PHASE=$(kubectl get pod "$POD" -o jsonpath='{.status.phase}')
RESTARTS=$(kubectl get pod "$POD" -o jsonpath='{.status.containerStatuses[0].restartCount}')

echo "Pod:      $POD"
echo "Phase:    $PHASE"
echo "Restarts: $RESTARTS"
echo ""

if [ "$PHASE" != "Running" ]; then
  echo "FAIL: Pod is not Running. Keep debugging!"
  exit 1
fi

# Get current memory usage
echo "Checking memory usage over time..."
INITIAL_MEM=$(kubectl top pod "$POD" 2>/dev/null | tail -1 | awk '{print $3}')
echo "Initial memory: $INITIAL_MEM"

# Wait and check memory hasn't grown unbounded or caused OOMKill
echo "Watching for stability (60s)..."
for i in {1..6}; do
  sleep 10
  CURRENT_PHASE=$(kubectl get pod "$POD" -o jsonpath='{.status.phase}' 2>/dev/null)
  CURRENT_RESTARTS=$(kubectl get pod "$POD" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)
  LAST_STATE=$(kubectl get pod "$POD" -o jsonpath='{.status.containerStatuses[0].lastState.reason}' 2>/dev/null)

  if [ "$CURRENT_PHASE" != "Running" ] || [ "$CURRENT_RESTARTS" -gt "$RESTARTS" ]; then
    echo ""
    echo "FAIL: Pod restarted during verification."
    if [ "$LAST_STATE" = "OOMKilled" ]; then
      echo "Reason: OOMKilled - The memory limit is still being exceeded."
      echo "Hint: Either fix the memory leak in the code or increase the memory limit."
    else
      echo "Reason: $LAST_STATE"
    fi
    exit 1
  fi
  echo "  Check $i/6: Pod still running, no restarts"
done

FINAL_MEM=$(kubectl top pod "$POD" 2>/dev/null | tail -1 | awk '{print $3}' || echo "N/A")
echo "Final memory: $FINAL_MEM"

echo ""
echo "============================================"
echo "  PASSED"
echo "  The pod is stable and not being OOMKilled."
echo "============================================"
echo ""
echo "Note: In production, you would also:"
echo "  - Fix the memory leak in application code"
echo "  - Set up proper memory monitoring and alerting"
echo "  - Configure horizontal pod autoscaling"
echo "  - Review resource requests and limits"
