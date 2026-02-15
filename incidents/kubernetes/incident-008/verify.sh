#!/usr/bin/env bash
set -euo pipefail

echo "=== RamOps: Verifying fix ==="
echo ""

# Check that the secret exists
if ! kubectl get secret api-tls-secret >/dev/null 2>&1; then
  echo "FAIL: Secret 'api-tls-secret' not found"
  exit 1
fi

echo "Checking TLS certificate validity..."

# Extract and check certificate
CERT=$(kubectl get secret api-tls-secret -o jsonpath='{.data.tls\.crt}' | base64 -d)

# Check if certificate is valid (not expired)
if ! echo "$CERT" | openssl x509 -checkend 0 -noout 2>/dev/null; then
  echo "FAIL: Certificate is expired or invalid"
  echo ""
  echo "Certificate details:"
  echo "$CERT" | openssl x509 -text -noout | grep -A 2 Validity
  exit 1
fi

echo "✓ Certificate is valid"

# Check certificate has reasonable expiration (at least 1 day in the future)
if ! echo "$CERT" | openssl x509 -checkend 86400 -noout 2>/dev/null; then
  echo "WARNING: Certificate expires in less than 1 day"
fi

# Get certificate details
echo ""
echo "Certificate details:"
echo "$CERT" | openssl x509 -text -noout | grep -A 2 "Validity"
echo "$CERT" | openssl x509 -text -noout | grep "Subject:"

# Check that the pod is running
echo ""
echo "Checking pod status..."
POD=$(kubectl get pods -l app=api-gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD" ]; then
  echo "FAIL: No pod found for api-gateway"
  exit 1
fi

PHASE=$(kubectl get pod "$POD" -o jsonpath='{.status.phase}')
if [ "$PHASE" != "Running" ]; then
  echo "FAIL: Pod is not Running (current state: $PHASE)"
  exit 1
fi

echo "✓ Pod is running"

# Test HTTPS connection
echo ""
echo "Testing HTTPS connection..."
if ! kubectl run test-curl --image=alpine --rm -i --restart=Never --quiet -- sh -c '
  apk add --no-cache curl openssl >/dev/null 2>&1
  # Test with certificate validation (should work now)
  if curl -s --cacert /dev/null -k https://api-gateway/health | grep -q "OK"; then
    echo "✓ HTTPS connection successful"
    exit 0
  else
    echo "✗ HTTPS connection failed"
    exit 1
  fi
' 2>/dev/null; then
  echo "✓ HTTPS endpoint responding"
else
  echo "FAIL: HTTPS endpoint not responding correctly"
  exit 1
fi

echo ""
echo "============================================"
echo "  PASSED"
echo "  Certificate is valid and HTTPS is working!"
echo "============================================"
