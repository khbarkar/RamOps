#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Alert Storm from Single Root Cause (Lima) ==="
echo ""

if ! command -v limactl &> /dev/null; then
  echo "ERROR: Lima is not installed. Run: brew install lima"
  exit 1
fi

echo "Cleaning up previous run..."
limactl stop alertmanager 2>/dev/null || true
limactl delete alertmanager 2>/dev/null || true

echo ""
echo "Starting VM with Lima..."
limactl start --tty=false "$SCENARIO_DIR/lima-alertmanager.yaml"

echo ""
echo "============================================"
echo "  SCENARIO: Alert Storm from Single Root Cause"
echo "  SETUP COMPLETE"
echo ""
echo "  Prometheus: http://localhost:9090"
echo "  Alertmanager: http://localhost:9093"
echo ""
echo "  SSH: limactl shell alertmanager"
echo "============================================"
