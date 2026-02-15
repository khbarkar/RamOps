#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: The Zombie Apocalypse (Lima) ==="
echo ""

if ! command -v limactl &> /dev/null; then
  echo "ERROR: Lima is not installed. Run: brew install lima"
  exit 1
fi

echo "Cleaning up previous run..."
limactl stop lima-zombies 2>/dev/null || true
limactl delete lima-zombies 2>/dev/null || true

echo ""
echo "Starting VM with Lima..."
limactl start --tty=false "$SCENARIO_DIR/lima-zombies.yaml"

echo ""
echo "============================================"
echo "  SCENARIO: The Zombie Apocalypse"
echo "  SETUP COMPLETE"
echo ""
echo "  Hundreds of zombie processes are spawning"
echo "  The process table is filling up"
echo "  Find and fix all the zombie creators"
echo ""
echo "  SSH: limactl shell lima-zombies"
echo "============================================"
