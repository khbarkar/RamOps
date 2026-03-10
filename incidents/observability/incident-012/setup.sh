#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Alert Storm from Single Root Cause ==="
echo ""

if ! command -v limactl &> /dev/null; then
  echo "ERROR: Lima is not installed."
  echo "Install with: brew install lima"
  exit 1
fi

echo "Cleaning up previous run..."
limactl stop lima-alertmanager 2>/dev/null || true
limactl delete -f lima-alertmanager 2>/dev/null || true

echo ""
echo "Starting VM with Lima (this takes ~3 minutes)..."
limactl start --tty=false "$SCENARIO_DIR/lima-alertmanager.yaml"

echo ""
echo "Waiting for services to start..."
sleep 30

echo ""
echo "============================================"
echo ""
echo "  SCENARIO: Alert Storm"
echo ""
echo "  SETUP COMPLETE"
echo ""
echo "  Multiple alerts are now firing due to a"
echo "  single root cause. Your phone is buzzing"
echo "  non-stop at 3am."
echo ""
echo "  Access points:"
echo "    - Alertmanager: http://localhost:9093"
echo "    - Prometheus: http://localhost:9090"
echo ""
echo "  Current state:"
echo "    - 8+ alerts firing"
echo "    - All symptoms of one root cause"
echo "    - Disk is nearly full"
echo ""
echo "  Your tasks:"
echo "    1. Open Alertmanager to see the storm"
echo "    2. Identify the root cause alert"
echo "    3. SSH in: limactl shell lima-alertmanager"
echo "    4. Check disk: df -h"
echo "    5. Clear space: sudo rm /var/fillfile"
echo "    6. Configure alert grouping in Alertmanager"
echo ""
echo "============================================"
echo ""
echo "Run ./verify.sh when you've fixed the issue and improved alerts."
