#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="consensus-failure"

echo "Cleaning up Distributed Consensus Failure scenario..."

kind delete cluster --name "$CLUSTER_NAME" 2>/dev/null || true

echo "Cleanup complete!"
