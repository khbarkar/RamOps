#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="sidechannel-attack"

echo "Cleaning up Side-Channel Attack scenario..."

kind delete cluster --name "$CLUSTER_NAME" 2>/dev/null || true

echo "Cleanup complete!"
