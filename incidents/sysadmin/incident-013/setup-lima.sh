#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: The Vanishing Log Files (Lima) ==="
echo ""

if ! command -v limactl &> /dev/null; then
  echo "ERROR: Lima is not installed. Run: brew install lima"
  exit 1
fi

echo "Cleaning up previous run..."
limactl stop lima-logserver 2>/dev/null || true
limactl delete lima-logserver 2>/dev/null || true

echo ""
echo "Starting VM with Lima..."
limactl start --tty=false "$SCENARIO_DIR/lima-logserver.yaml"

echo ""
echo "============================================"
echo "  SCENARIO: The Vanishing Log Files"
echo "  SETUP COMPLETE"
echo ""
echo "  Disk is nearly full but logs were deleted"
echo "  Why isn't space being freed?"
echo ""
echo "  SSH: limactl shell lima-logserver"
echo "============================================"
