#!/usr/bin/env bash
set -euo pipefail

INSTANCE_NAME="lima-cryptominer"

echo "Cleaning up Cryptominer Investigation scenario..."

limactl delete --force "$INSTANCE_NAME" 2>/dev/null || true

echo "Cleanup complete!"
