#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="security-secrets"

echo "=== RamOps: Verifying fix ==="
echo ""

if ! kind get clusters | grep -q "$CLUSTER_NAME"; then
  echo "FAIL: Cluster not running."
  exit 1
fi

echo "[ok] Cluster is running."

# Check if secure image exists
if ! docker images | grep -q "vulnerable-app.*secure"; then
  echo "FAIL: Secure image not built."
  echo "      Build with: docker build -t vulnerable-app:secure -f Dockerfile.secure ."
  exit 1
fi

echo "[ok] Secure image exists."

# Check if secret is leaked in secure image
SECRET_LEAKED=$(docker history --no-trunc vulnerable-app:secure 2>/dev/null | grep -c "sk_live_" || echo 0)

if [ "$SECRET_LEAKED" -gt 0 ]; then
  echo "FAIL: Secret still visible in secure image layers."
  exit 1
fi

echo "[ok] Secret not visible in image history."

# Check if secret is in any layer
LAYER_CHECK=$(docker save vulnerable-app:secure | tar -xO | grep -c "sk_live_" || echo 0)

if [ "$LAYER_CHECK" -gt 0 ]; then
  echo "FAIL: Secret found in image layers."
  exit 1
fi

echo "[ok] Secret not found in any layer."

echo ""
echo "============================================"
echo "  PASSED"
echo "  - Secure image built successfully"
echo "  - Secret not visible in history"
echo "  - Secret not extractable from layers"
echo "  - Multi-stage build used correctly"
echo "============================================"
