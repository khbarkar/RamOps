#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLUSTER_NAME="security-secrets"

echo "=== RamOps: Secrets Leaked in Image Layers ==="
echo ""

if ! command -v kind &> /dev/null; then
  echo "ERROR: kind is not installed."
  echo "Install with: brew install kind"
  exit 1
fi

if ! command -v docker &> /dev/null; then
  echo "ERROR: docker is not installed."
  exit 1
fi

echo "Creating Kind cluster..."
kind create cluster --name "$CLUSTER_NAME" --wait 60s --quiet

echo "Building vulnerable container image..."
cd "$SCENARIO_DIR"
docker build -t vulnerable-app:leaked -f Dockerfile.vulnerable . --quiet

echo "Loading image into Kind..."
kind load docker-image vulnerable-app:leaked --name "$CLUSTER_NAME"

echo "Deploying vulnerable application..."
kubectl apply -f "$SCENARIO_DIR/manifests/deployment.yaml"
kubectl wait --for=condition=ready pod -l app=vulnerable-app -n security-demo --timeout=60s

echo ""
echo "============================================"
echo "  SCENARIO: Secrets Leaked in Image Layers"
echo "  SETUP COMPLETE"
echo ""
echo "  A secret API key is leaked in the image layers"
echo "  Even though it was 'deleted', it's still there"
echo ""
echo "  Your tasks:"
echo "    1. Find the leaked secret in the image"
echo "    2. Understand why deletion didn't work"
echo "    3. Rebuild securely"
echo ""
echo "  Investigate with:"
echo "    docker history vulnerable-app:leaked"
echo "    docker history --no-trunc vulnerable-app:leaked"
echo ""
echo "============================================"
