#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Verifying Fix ==="
echo ""

# Check if VMs are running
if ! vagrant status | grep -q "kafka1.*running"; then
  echo "FAIL: kafka1 VM is not running."
  exit 1
fi

echo "[ok] VMs are running."

# Check if I/O throttle is removed on brokers
THROTTLE_ACTIVE=0
for broker in kafka1 kafka2 kafka3; do
  THROTTLE=$(vagrant ssh "$broker" -c "cat /sys/fs/cgroup/blkio/blkio.throttle.write_bps_device 2>/dev/null || echo ''" 2>/dev/null | grep -c "8:32" || true)
  if [ "$THROTTLE" -gt 0 ]; then
    echo "WARN: $broker still has disk I/O throttle active."
    THROTTLE_ACTIVE=1
  fi
done

if [ "$THROTTLE_ACTIVE" -eq 0 ]; then
  echo "[ok] Disk I/O throttle removed from all brokers."
else
  echo "HINT: Remove throttle with:"
  echo "  vagrant ssh kafka1 -c 'echo \"\" | sudo tee /sys/fs/cgroup/blkio/blkio.throttle.write_bps_device'"
  echo ""
fi

echo ""
echo "Run a load test and check Grafana:"
echo "  python3 scripts/load-generator.py --duration 60"
echo ""
echo "Expected behavior after fix:"
echo "  - Consumer lag should stay low (< 10k messages)"
echo "  - Produce latency p99 < 100ms"
echo "  - Disk I/O wait < 20%"
echo ""
echo "============================================"
echo "  Check metrics in Grafana:"
echo "  http://localhost:3000"
echo "============================================"
