#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="kafka-disk-bound"

echo "=== Cleaning up Kind cluster ==="
kind delete cluster --name "$CLUSTER_NAME" 2>/dev/null || true
echo "Cleanup complete!"
