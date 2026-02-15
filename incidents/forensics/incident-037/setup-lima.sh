#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTANCE_NAME="lima-rootkit"

echo "=== RamOps: Rootkit Detection (Lima) ==="
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
limactl start --name="$INSTANCE_NAME" "$SCENARIO_DIR/lima-rootkit.yaml"

echo ""
echo "Waiting for system to be ready..."
sleep 5

echo ""
echo "============================================"
echo "  SCENARIO: Rootkit Detection"
echo "  SETUP COMPLETE"
echo ""
echo "  System has been compromised with a rootkit"
echo "  Standard tools are hiding malicious activity"
echo ""
echo "  SSH into the system:"
echo "    limactl shell $INSTANCE_NAME"
echo ""
echo "============================================"
