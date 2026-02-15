#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="ramops-dns-outage"

echo "=== RamOps: Cleanup ==="
echo ""

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Deleting Kind cluster '${CLUSTER_NAME}'..."
  kind delete cluster --name "$CLUSTER_NAME"
  echo "Done."
else
  echo "Cluster '${CLUSTER_NAME}' not found. Nothing to clean up."
fi
