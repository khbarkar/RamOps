#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="security-secrets"

echo "=== Cleaning up Kind cluster ==="
kind delete cluster --name "$CLUSTER_NAME" 2>/dev/null || true

echo "Removing Docker images..."
docker rmi vulnerable-app:leaked 2>/dev/null || true
docker rmi vulnerable-app:secure 2>/dev/null || true

echo "Cleanup complete!"
