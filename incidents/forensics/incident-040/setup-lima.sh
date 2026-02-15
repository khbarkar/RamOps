#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTANCE_NAME="lima-logtamper"

echo "=== RamOps: Log Tampering (Lima) ==="
echo ""

if ! command -v limactl &> /dev/null; then
  echo "ERROR: Lima is not installed."
  echo "Install with: brew install lima"
  exit 1
fi

echo "Cleaning up previous run..."
limactl delete --force "$INSTANCE_NAME" 2>/dev/null || true
sleep 2

echo "Starting VM with Lima..."
limactl start --name="$INSTANCE_NAME" "$SCENARIO_DIR/lima-logtamper.yaml"

echo ""
echo "Waiting for system to be ready..."
sleep 5

echo ""
echo "============================================"
echo "  SCENARIO: Log Tampering"
echo "  SETUP COMPLETE"
echo ""
echo "  Logs have been tampered with"
echo "  Evidence of breach has been hidden"
echo ""
echo "  SSH into the system:"
echo "    limactl shell $INSTANCE_NAME"
echo ""
echo "============================================"
