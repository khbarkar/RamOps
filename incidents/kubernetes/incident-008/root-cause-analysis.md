# Root Cause Analysis: Incident-008

## Summary

**Incident:** HTTPS connections failing with certificate errors
**Duration:** Until certificate renewed
**Impact:** All HTTPS traffic to API gateway failing; HTTP still functional
**Root Cause:** TLS certificate expired

## Timeline

1. TLS certificate was generated with short validity period
2. Certificate reached expiration date
3. HTTPS clients began rejecting connections due to expired certificate
4. HTTP traffic unaffected (doesn't use TLS)
5. Users reported "certificate has expired" errors

## Diagnosis

### Symptoms Observed

HTTPS requests fail with certificate validation errors:
```
curl: (60) SSL certificate problem: certificate has expired
```

### Investigation Steps

**1. Check pod status:**
```bash
kubectl get pods -l app=api-gateway
# Pod is Running - so the application itself is fine
```

**2. Check the TLS secret:**
```bash
kubectl get secrets
# api-tls-secret exists

kubectl describe secret api-tls-secret
# Shows it has tls.crt and tls.key
```

**3. Inspect the certificate:**
```bash
kubectl get secret api-tls-secret \
  -o jsonpath='{.data.tls\.crt}' | \
  base64 -d | \
  openssl x509 -text -noout
```

Look for the Validity section:
```
Validity
    Not Before: Jan 14 10:00:00 2024 GMT
    Not After : Jan 14 10:00:01 2024 GMT  ← EXPIRED!
```

**4. Check current date:**
```bash
date
# Compare to certificate's "Not After" date
```

**5. Verify HTTP still works:**
```bash
kubectl run test --image=alpine --rm -it -- sh
apk add curl
curl http://api-gateway/health  # Works!
curl https://api-gateway/health # Fails with certificate error
```

## Root Cause

The TLS certificate used by the API gateway expired. The certificate was only valid for a very short time (likely for testing) and was never renewed.

When a client connects via HTTPS:
1. Server presents the TLS certificate
2. Client checks if certificate is within validity period
3. Certificate's "Not After" date has passed
4. Client rejects the connection

## Fix

### Option 1: Generate New Certificate (Proper Fix)

Create a new certificate with proper validity:

```bash
# Generate new key and certificate (valid for 365 days)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=api.example.com/O=RamOps" \
  -addext "subjectAltName=DNS:api.example.com"

# Update the secret
kubectl create secret tls api-tls-secret \
  --cert=tls.crt \
  --key=tls.key \
  --dry-run=client -o yaml | \
  kubectl apply -f -

# Restart pods to pick up new certificate
kubectl rollout restart deployment api-gateway
```

### Option 2: Use cert-manager (Production Approach)

Install cert-manager for automatic certificate management:

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create a self-signed issuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
EOF

# Create a certificate resource
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: api-gateway-cert
spec:
  secretName: api-tls-secret
  duration: 2160h # 90 days
  renewBefore: 360h # 15 days before expiry
  issuerRef:
    name: selfsigned-issuer
    kind: Issuer
  commonName: api.example.com
  dnsNames:
    - api.example.com
EOF
```

cert-manager will:
- Automatically generate the certificate
- Store it in the specified secret
- Auto-renew before expiration

### Option 3: Use Let's Encrypt (For Public Domains)

For production with real domain names:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

## Verification

After renewing the certificate:

```bash
# Check new certificate expiration
kubectl get secret api-tls-secret \
  -o jsonpath='{.data.tls\.crt}' | \
  base64 -d | \
  openssl x509 -noout -dates

# Should show:
# notBefore=Feb 15 10:00:00 2024 GMT
# notAfter=Feb 15 10:00:00 2025 GMT  ← Valid for 1 year

# Test HTTPS connection
kubectl run test --image=alpine --rm -it -- sh
apk add curl
curl -k https://api-gateway/health  # Should work now!
```

## Lessons Learned

### What Went Wrong

1. **No certificate expiration monitoring** - no alerts before expiration
2. **Manual certificate management** - prone to human error
3. **Short certificate validity** - didn't allow time to react
4. **No automated renewal** - required manual intervention

### Prevention Strategies

**1. Monitor certificate expiration:**

```yaml
# Prometheus rule example
- alert: CertificateExpiringSoon
  expr: (x509_cert_not_after - time()) < 86400 * 30  # 30 days
  annotations:
    summary: "Certificate expiring in 30 days"
```

**2. Use cert-manager for automation:**
- Automatic certificate generation
- Auto-renewal before expiration
- Support for Let's Encrypt, self-signed, or internal CA
- Removes manual processes

**3. Set reasonable validity periods:**
- Production: 90 days (with 30-day renewal window)
- Let's Encrypt default: 90 days
- Internal CA: 1-2 years

**4. Document certificate renewal procedures:**
- Where certificates are stored
- How to renew manually (backup plan)
- Who to contact when alerts fire

**5. Test certificate renewal:**
- Practice the renewal process
- Verify monitoring alerts work
- Test automated renewal systems

## Additional Notes

### Certificate Lifecycle Best Practices

**Validity Periods:**
- **Short-lived certs (1-7 days):** Service mesh, internal microservices
- **Medium-lived certs (90 days):** Public-facing services (Let's Encrypt)
- **Long-lived certs (1-2 years):** Internal infrastructure (if auto-renewal in place)

**Renewal Timing:**
- Renew at 2/3 of lifetime (90-day cert → renew at day 60)
- Never wait until < 7 days before expiry
- Build in buffer for renewal failures

**Monitoring:**
- Alert at 30 days, 15 days, 7 days before expiry
- Dashboard showing all certificate expirations
- Automated tests of certificate validity

### Common Certificate Issues in Kubernetes

1. **Expired certificates** - what we just fixed
2. **Wrong SAN (Subject Alternative Name)** - certificate for wrong domain
3. **Untrusted CA** - self-signed cert not in trust store
4. **Key mismatch** - certificate and private key don't match
5. **Secret not mounted** - pod can't access certificate secret
6. **No restart after renewal** - pod still using old expired cert

### cert-manager Benefits

- **Automatic issuance** - certificates created when needed
- **Automatic renewal** - renews before expiration
- **Multiple issuers** - Let's Encrypt, self-signed, Vault, etc.
- **CRD-based** - certificates defined as Kubernetes resources
- **Monitoring integration** - exports Prometheus metrics
- **Industry standard** - widely used, well-documented

## Production War Story

> "We had a customer-facing API go down at 3 AM on a Sunday. SSL certificate expired. No one knew where the cert was stored or how to renew it. Documentation was outdated. Took 6 hours to figure out the renewal process and get a new cert deployed. Lost $50k in SLA credits.
>
> After that incident: installed cert-manager, set up monitoring, documented everything, and added cert expiration checks to our CI/CD. Never had the problem again."

Certificate expiration is 100% preventable with proper tooling and monitoring.
