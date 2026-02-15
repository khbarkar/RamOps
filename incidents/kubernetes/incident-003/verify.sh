#!/usr/bin/env bash
set -euo pipefail

echo "=== RamOps: Verifying DNS fix ==="
echo ""

# Check CoreDNS is healthy
echo "Checking CoreDNS status..."
COREDNS_PODS=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}')

if echo "$COREDNS_PODS" | grep -v "Running"; then
  echo "FAIL: CoreDNS pods are not all Running"
  echo "$COREDNS_PODS"
  exit 1
fi

echo "CoreDNS pods are Running"
echo ""

# Test DNS resolution from within a pod
echo "Testing DNS resolution from application pod..."

# Test internal service resolution
if ! kubectl exec deploy/backend -- nslookup database.default.svc.cluster.local > /dev/null 2>&1; then
  echo "FAIL: Cannot resolve internal service 'database.default.svc.cluster.local'"
  exit 1
fi
echo "[ok] Can resolve internal service (database)"

# Test kubernetes service resolution
if ! kubectl exec deploy/backend -- nslookup kubernetes.default.svc.cluster.local > /dev/null 2>&1; then
  echo "FAIL: Cannot resolve 'kubernetes.default.svc.cluster.local'"
  exit 1
fi
echo "[ok] Can resolve kubernetes service"

# Test external DNS resolution
if ! kubectl exec deploy/backend -- nslookup google.com > /dev/null 2>&1; then
  echo "FAIL: Cannot resolve external domain 'google.com'"
  exit 1
fi
echo "[ok] Can resolve external domains"

echo ""

# Check application is healthy
echo "Checking application health..."
BACKEND_STATUS=$(kubectl get deployment backend -o jsonpath='{.status.conditions[?(@.type=="Available")].status}')

if [ "$BACKEND_STATUS" != "True" ]; then
  echo "FAIL: Backend deployment is not Available"
  exit 1
fi
echo "[ok] Backend deployment is healthy"

echo ""
echo "============================================"
echo "  PASSED"
echo "  DNS is working correctly!"
echo "  - CoreDNS pods are running"
echo "  - Internal service resolution works"
echo "  - External domain resolution works"
echo "  - Application is healthy"
echo "============================================"
