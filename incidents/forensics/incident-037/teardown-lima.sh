#!/usr/bin/env bash
set -euo pipefail

INSTANCE_NAME="lima-rootkit"

echo "Cleaning up Rootkit Detection scenario..."

limactl delete --force "$INSTANCE_NAME" 2>/dev/null || true

echo "Cleanup complete!"
