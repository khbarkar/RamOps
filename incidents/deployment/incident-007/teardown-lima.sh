#!/usr/bin/env bash
set -euo pipefail

echo "=== Cleaning up Lima VM ==="
limactl stop app-server 2>/dev/null || true
limactl delete app-server 2>/dev/null || true
echo "Cleanup complete!"
