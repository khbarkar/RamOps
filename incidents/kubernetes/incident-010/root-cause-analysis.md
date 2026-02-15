# Solution: Exposed Database Credentials

## Root Cause

Sensitive credentials (database passwords, API keys) are stored in a **ConfigMap** instead of a **Secret**. ConfigMaps are designed for non-sensitive configuration data and should never contain credentials, tokens, or other secrets.

This is a critical security vulnerability because:
1. ConfigMaps are easily readable by anyone with basic cluster access
2. They may be logged or exposed in various ways
3. They don't follow security best practices for secret management
4. RBAC policies often allow broader access to ConfigMaps than Secrets

## How to Diagnose

### 1. List ConfigMaps

```bash
kubectl get configmaps
# Shows: app-config
```

### 2. Inspect the ConfigMap

```bash
kubectl describe configmap app-config

# or

kubectl get configmap app-config -o yaml
```

You'll see plaintext credentials:
```yaml
data:
  DB_PASSWORD: "super-secret-password-123"
  API_KEY: "sk-live-abc123def456ghi789jkl012mno345"
  REDIS_URL: "redis://:another-password@redis.internal:6379"
```

### 3. Check How It's Used

```bash
kubectl get deployment web-app -o yaml
```

Shows:
```yaml
envFrom:
  - configMapRef:
      name: app-config
```

## Fix: Migrate to Kubernetes Secrets

### Step 1: Create a Secret

```bash
kubectl create secret generic app-credentials \
  --from-literal=DB_HOST=postgres.internal \
  --from-literal=DB_USER=admin \
  --from-literal=DB_PASSWORD=super-secret-password-123 \
  --from-literal=DB_NAME=production_db \
  --from-literal=API_KEY=sk-live-abc123def456ghi789jkl012mno345 \
  --from-literal=REDIS_URL=redis://:another-password@redis.internal:6379
```

### Step 2: Update the Deployment

```bash
kubectl edit deployment web-app
```

Change from:
```yaml
envFrom:
  - configMapRef:
      name: app-config
```

To:
```yaml
envFrom:
  - secretRef:
      name: app-credentials
```

### Step 3: Delete the Old ConfigMap

```bash
kubectl delete configmap app-config
```

The pod will automatically restart with the new configuration.

## Alternative: Using Secret YAML

You can also create Secrets declaratively:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-credentials
  namespace: default
type: Opaque
stringData:  # Use stringData for plain text (automatically base64 encoded)
  DB_HOST: "postgres.internal"
  DB_USER: "admin"
  DB_PASSWORD: "super-secret-password-123"
  DB_NAME: "production_db"
  API_KEY: "sk-live-abc123def456ghi789jkl012mno345"
  REDIS_URL: "redis://:another-password@redis.internal:6379"
```

**Warning**: Never commit this to git! Use external secret management instead.

## Understanding Kubernetes Secrets

### What Secrets Are

- Base64-encoded (NOT encrypted by default)
- Separate RBAC permissions from ConfigMaps
- Can be encrypted at rest in etcd (requires configuration)
- Not shown in `kubectl describe` output (need `-o yaml` to see)

### What Secrets Are NOT

- **Not encrypted** in transit or at rest (by default)
- **Not a complete secret management solution**
- **Not safe** to commit to git (even base64-encoded)

### Viewing a Secret

```bash
# This WON'T show the actual values
kubectl describe secret app-credentials

# This WILL show base64-encoded values
kubectl get secret app-credentials -o yaml

# Decode a specific value
kubectl get secret app-credentials -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
```

## Production Best Practices

### 1. Use External Secret Management

Don't store production secrets in Kubernetes Secrets. Use:

- **HashiCorp Vault**
- **AWS Secrets Manager** (with External Secrets Operator)
- **Azure Key Vault**
- **Google Secret Manager**
- **Sealed Secrets** (for GitOps workflows)

### 2. Enable Secret Encryption at Rest

Configure etcd encryption:

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <base64-encoded-key>
      - identity: {}
```

### 3. Implement RBAC

Restrict who can read secrets:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list"]
    resourceNames: ["app-credentials"]  # Specific secrets only
```

### 4. Use Secret Rotation

Implement regular secret rotation:
- Automate with tools like cert-manager (for TLS certs)
- Use External Secrets Operator with auto-refresh
- Set up alerts for expiring credentials

### 5. Audit Secret Access

Enable audit logging to track who accesses secrets:

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["secrets"]
```

### 6. Never Commit Secrets to Git

Use:
- **Sealed Secrets**: Encrypted secrets safe for git
- **SOPS**: Mozilla's secret encryption tool
- **External Secrets Operator**: Sync from external stores
- **Helm secrets plugin**: Encrypt values.yaml

## Example: External Secrets Operator

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: app-credentials
  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: prod/db/password
    - secretKey: API_KEY
      remoteRef:
        key: prod/api/key
```

## Common Mistakes to Avoid

1. Storing secrets in ConfigMaps
2. Committing secrets to git (even base64-encoded)
3. Logging secrets in application logs
4. Exposing secrets in error messages
5. Not rotating secrets regularly
6. Granting overly broad RBAC permissions
7. Not enabling encryption at rest
8. Using same secrets across environments (dev/staging/prod)

## Key Takeaways

1. **ConfigMaps are for configuration, not secrets**
2. **Kubernetes Secrets are better but not perfect** - use external secret stores in production
3. **Base64 encoding is not encryption** - anyone with kubectl access can decode
4. **Implement defense in depth**:
   - RBAC controls
   - Encryption at rest
   - External secret management
   - Audit logging
   - Regular rotation
5. **Never commit secrets to version control**

## Related Security Issues

- API keys in container images
- Passwords in environment variables visible via `kubectl describe`
- Database connection strings in application code
- TLS certificates not rotated
- Service account tokens with excessive permissions
