#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="ramops-incident-008"
SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Incident-008 ==="
echo ""

# Check prerequisites
for cmd in kind kubectl openssl; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: '$cmd' is required but not installed."
    exit 1
  fi
done

# Create cluster (delete existing if present)
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster '${CLUSTER_NAME}' already exists. Deleting..."
  kind delete cluster --name "$CLUSTER_NAME"
fi

echo "Creating Kind cluster '${CLUSTER_NAME}'..."
kind create cluster --name "$CLUSTER_NAME" --wait 60s

echo ""
echo "Generating expired TLS certificate..."
mkdir -p "$SCENARIO_DIR/certs"

# Generate a certificate that expired yesterday
openssl req -x509 -nodes -days 0 -newkey rsa:2048 \
  -keyout "$SCENARIO_DIR/certs/tls.key" \
  -out "$SCENARIO_DIR/certs/tls.crt" \
  -subj "/CN=api.example.com/O=RamOps" \
  -addext "subjectAltName=DNS:api.example.com" \
  2>/dev/null

# Backdate the certificate to make it expired
# Create a certificate valid from 7 days ago to 1 day ago (so it's expired now)
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout "$SCENARIO_DIR/certs/tls.key" \
  -out "$SCENARIO_DIR/certs/tls.crt" \
  -subj "/CN=api.example.com/O=RamOps" \
  -addext "subjectAltName=DNS:api.example.com" \
  -days 6 \
  2>/dev/null

# Backdate it by modifying the system date (doesn't work in Kind, so we'll use a pre-expired cert approach)
# Instead, create a cert with validity starting in the past
cat > "$SCENARIO_DIR/certs/openssl.conf" <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = api.example.com
O = RamOps

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = api.example.com
EOF

# Generate key
openssl genrsa -out "$SCENARIO_DIR/certs/tls.key" 2048 2>/dev/null

# Generate CSR
openssl req -new -key "$SCENARIO_DIR/certs/tls.key" \
  -out "$SCENARIO_DIR/certs/tls.csr" \
  -config "$SCENARIO_DIR/certs/openssl.conf" \
  2>/dev/null

# Sign with very short validity (1 second) to make it immediately expired
openssl x509 -req -in "$SCENARIO_DIR/certs/tls.csr" \
  -signkey "$SCENARIO_DIR/certs/tls.key" \
  -out "$SCENARIO_DIR/certs/tls.crt" \
  -days 0 \
  -extensions v3_req \
  -extfile "$SCENARIO_DIR/certs/openssl.conf" \
  2>/dev/null

echo "Waiting a moment for certificate to expire..."
sleep 2

echo ""
echo "Deploying API gateway with expired certificate..."
kubectl create secret tls api-tls-secret \
  --cert="$SCENARIO_DIR/certs/tls.crt" \
  --key="$SCENARIO_DIR/certs/tls.key"

kubectl apply -f "$SCENARIO_DIR/manifests/app.yaml"

echo ""
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/api-gateway

echo ""
echo "============================================"
echo "  SCENARIO ACTIVE"
echo "  The API gateway is experiencing issues."
echo ""
echo "  User report:"
echo "    'HTTPS connections are failing!'"
echo "    'Getting certificate errors when accessing the API'"
echo "    'This worked fine yesterday!'"
echo ""
echo "  Your task: diagnose and fix the HTTPS issue"
echo ""
echo "  Debug commands:"
echo "    kubectl get pods"
echo "    kubectl get secrets"
echo "    kubectl describe secret api-tls-secret"
echo ""
echo "  Test HTTPS (will fail):"
echo "    kubectl run -it --rm debug --image=alpine --restart=Never -- sh"
echo "    apk add curl"
echo "    curl -v -k https://api-gateway/health"
echo "============================================"
echo ""
echo "Run verify.sh when you think you've fixed it."
