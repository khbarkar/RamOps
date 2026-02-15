#!/usr/bin/env bash
set -euo pipefail

echo "=== RamOps: Verifying secret management ==="
echo ""

# Check that app-credentials Secret exists
if ! kubectl get secret app-credentials &>/dev/null; then
  echo "FAIL: Secret 'app-credentials' not found."
  echo "Hint: Create a Secret with the database credentials:"
  echo "  kubectl create secret generic app-credentials \\"
  echo "    --from-literal=DB_HOST=postgres.internal \\"
  echo "    --from-literal=DB_USER=admin \\"
  echo "    --from-literal=DB_PASSWORD=super-secret-password-123"
  exit 1
fi

echo "Found Secret 'app-credentials'"

# Check that the deployment references the Secret
DEPLOYMENT_YAML=$(kubectl get deployment web-app -o yaml)

if echo "$DEPLOYMENT_YAML" | grep -q "configMapRef:" && echo "$DEPLOYMENT_YAML" | grep -q "name: app-config"; then
  echo ""
  echo "FAIL: Deployment still references ConfigMap 'app-config' for environment variables."
  echo "Hint: Edit the deployment to use secretRef instead:"
  echo "  kubectl edit deployment web-app"
  echo ""
  echo "Change from:"
  echo "  envFrom:"
  echo "    - configMapRef:"
  echo "        name: app-config"
  echo ""
  echo "To:"
  echo "  envFrom:"
  echo "    - secretRef:"
  echo "        name: app-credentials"
  exit 1
fi

if ! echo "$DEPLOYMENT_YAML" | grep -q "secretRef:"; then
  echo ""
  echo "FAIL: Deployment does not reference any Secret."
  echo "Hint: Update the deployment to use the app-credentials Secret."
  exit 1
fi

if ! echo "$DEPLOYMENT_YAML" | grep -q "name: app-credentials"; then
  echo ""
  echo "FAIL: Deployment references a Secret but not 'app-credentials'."
  exit 1
fi

echo "Deployment correctly references Secret 'app-credentials'"

# Check that ConfigMap no longer contains sensitive data (optional cleanup)
if kubectl get configmap app-config &>/dev/null; then
  echo ""
  echo "WARNING: ConfigMap 'app-config' still exists."
  echo "Best practice: Delete it since it contains sensitive data:"
  echo "  kubectl delete configmap app-config"
  echo ""
fi

# Verify pod is running with the secret
POD=$(kubectl get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD" ]; then
  echo "FAIL: No pod found for web-app"
  exit 1
fi

PHASE=$(kubectl get pod "$POD" -o jsonpath='{.status.phase}')

if [ "$PHASE" != "Running" ]; then
  echo "FAIL: Pod is not Running. Check if the Secret was created correctly."
  exit 1
fi

echo "Pod is running successfully with Secret"
echo ""
echo "============================================"
echo "  PASSED"
echo "  Credentials are now stored in a Secret."
echo "============================================"
echo ""
echo "Important security notes:"
echo "  1. Secrets in Kubernetes are base64-encoded, NOT encrypted"
echo "  2. Anyone with RBAC access to Secrets can read them"
echo "  3. For production, consider:"
echo "     - External secret stores (Vault, AWS Secrets Manager)"
echo "     - Sealed Secrets or SOPS for GitOps"
echo "     - Secret encryption at rest in etcd"
echo "     - Regular secret rotation"
echo "     - Audit logging for secret access"
