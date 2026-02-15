#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Hard Link Deployment Trap (Lima) ==="
echo ""

if ! command -v limactl &> /dev/null; then
  echo "ERROR: Lima is not installed. Run: brew install lima"
  exit 1
fi

echo "Cleaning up previous run..."
limactl stop lima-app-server 2>/dev/null || true
limactl delete lima-app-server 2>/dev/null || true

echo ""
echo "Starting VM with Lima..."
limactl start --tty=false "$SCENARIO_DIR/lima-app-server.yaml"

echo ""
echo "============================================"
echo "  SCENARIO: Hard Link Deployment Trap"
echo "  SETUP COMPLETE"
echo ""
echo "  App: http://localhost:8000"
echo ""
echo "  SSH: limactl shell lima-app-server"
echo "============================================"
