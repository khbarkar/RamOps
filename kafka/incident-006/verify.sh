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

# Check if network throttle is removed on brokers
THROTTLE_ACTIVE=0
for broker in kafka1 kafka2 kafka3; do
  THROTTLE=$(vagrant ssh "$broker" -c "sudo tc qdisc show dev eth1 | grep -c htb || echo 0" 2>/dev/null | tr -d '\r')
  if [ "$THROTTLE" -gt 0 ]; then
    echo "WARN: $broker still has network throttle active."
    THROTTLE_ACTIVE=1
  fi
done

if [ "$THROTTLE_ACTIVE" -eq 0 ]; then
  echo "[ok] Network throttle removed from all brokers."
else
  echo "HINT: Remove throttle with:"
  echo "  vagrant ssh kafka1 -c 'sudo tc qdisc del dev eth1 root'"
  echo ""
fi

echo ""
echo "Run a load test and check Grafana:"
echo "  python3 scripts/load-generator.py --duration 60"
echo ""
echo "Expected behavior after fix:"
echo "  - Consumer lag should stay low (< 10k messages)"
echo "  - Network throughput > 100 Mbit/s (no longer capped)"
echo "  - Request queue time < 50ms"
echo ""
echo "============================================"
echo "  Check metrics in Grafana:"
echo "  http://localhost:3000"
echo "============================================"
