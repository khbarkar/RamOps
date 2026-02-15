#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="ramops-incident-008"
SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Cleanup ==="
echo ""

# Clean up local cert files
if [ -d "$SCENARIO_DIR/certs" ]; then
  echo "Removing generated certificates..."
  rm -rf "$SCENARIO_DIR/certs"
fi

# Delete cluster
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Deleting Kind cluster '${CLUSTER_NAME}'..."
  kind delete cluster --name "$CLUSTER_NAME"
  echo "Done."
else
  echo "Cluster '${CLUSTER_NAME}' not found. Nothing to clean up."
fi
