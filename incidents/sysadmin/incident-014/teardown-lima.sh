#!/usr/bin/env bash
set -euo pipefail

echo "=== Cleaning up Lima VM ==="
limactl stop lima-zombies 2>/dev/null || true
limactl delete lima-zombies 2>/dev/null || true
echo "Cleanup complete!"
