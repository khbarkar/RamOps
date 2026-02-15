# Root Cause Analysis: Secrets Leaked in Image Layers

## Incident Summary

An API key was leaked in a public Docker image. Despite the developer attempting to delete it with `RUN rm -rf /tmp/*`, the secret remained extractable from the image layers. An attacker discovered and exploited this secret for unauthorized API access.

## Root Cause

Docker images are built using a layered filesystem. Each `RUN` command in a Dockerfile creates a new layer that is immutable. When you delete a file in a later layer, Docker creates a "whiteout" file that hides the original, but the original file still exists in the earlier layer.

**The vulnerable pattern:**
```dockerfile
RUN curl -H "Authorization: Bearer ${API_KEY}" ...
RUN rm -rf /tmp/*  # This doesn't remove the secret from the previous layer!
```

The secret is baked into layer N when the curl command runs. Layer N+1 marks it as deleted, but anyone can extract layer N directly and retrieve the secret.

## Technical Details

**How Docker Layers Work:**
- Each instruction creates a new read-only layer
- Layers are stacked using a union filesystem
- Deleting a file creates a "whiteout" marker in the new layer
- Previous layers remain unchanged and accessible

**Extraction Methods:**
```bash
# View all layers and commands
docker history --no-trunc IMAGE_NAME

# Extract a specific layer
docker save IMAGE_NAME > image.tar
tar -xf image.tar
# Each layer is a separate tar.gz file

# Search for secrets in all layers
docker save IMAGE_NAME | tar -xO | grep -a "sk_live_"
```

## Attack Vector

1. Attacker pulls public image from Docker Hub
2. Runs `docker history --no-trunc vulnerable-app:leaked`
3. Sees the curl command with the API key in plain text
4. Extracts and uses the key for unauthorized access

## Resolution

**Immediate Fix:**
1. Revoke the leaked API key immediately
2. Remove the vulnerable image from Docker Hub
3. Audit all systems that may have used the compromised key

**Proper Implementation - Multi-Stage Build:**
```dockerfile
FROM alpine:3.18 AS builder
RUN --mount=type=secret,id=api_key \
    curl -H "Authorization: Bearer $(cat /run/secrets/api_key)" \
    https://api.example.com/data > /tmp/data.json

FROM alpine:3.18
COPY --from=builder /tmp/data.json /app/data.json
COPY app.sh /app/app.sh
CMD ["/app/app.sh"]
```

**Why This Works:**
- Secrets only exist in the builder stage
- Builder stage is discarded in the final image
- Only the result (data.json) is copied to the final stage
- No secret appears in any layer of the final image

**Alternative: BuildKit Secrets:**
```bash
# Build with secret from file
docker build --secret id=api_key,src=./api_key.txt -t app:secure .

# Build with secret from environment
echo $API_KEY | docker build --secret id=api_key -t app:secure .
```

## Prevention

**Best Practices:**

1. **Never put secrets in Dockerfiles:**
   - No hardcoded secrets in ARG or ENV
   - No secrets in RUN commands
   - Use BuildKit secrets or multi-stage builds

2. **Use .dockerignore:**
   ```
   .env
   *.key
   *.pem
   secrets/
   ```

3. **Scan images before pushing:**
   ```bash
   docker scan IMAGE_NAME
   trivy image IMAGE_NAME
   ```

4. **Use secret management:**
   - Kubernetes Secrets
   - HashiCorp Vault
   - AWS Secrets Manager
   - Environment variables at runtime (not build time)

5. **Audit image history:**
   ```bash
   docker history --no-trunc IMAGE_NAME | grep -i "secret\|password\|key\|token"
   ```

6. **Use minimal base images:**
   - Fewer layers = less surface area for leaks
   - Distroless images when possible

7. **Sign and verify images:**
   - Docker Content Trust
   - Cosign for signing
   - Verify signatures before deployment

## Key Learnings

- Docker layers are immutable - deletion doesn't remove data from previous layers
- Multi-stage builds isolate secrets to discarded stages
- BuildKit secrets never enter the layer filesystem
- Always assume image layers are public and inspectable
- Secrets should be injected at runtime, not build time
- Regular security scanning catches leaked secrets before production

## Detection

**Signs of leaked secrets:**
- `docker history` shows sensitive commands
- Security scanners flag secrets in layers
- Unusual API usage from unknown sources
- Secrets visible in public registries

**Tools:**
- `docker history --no-trunc`
- `trivy image` - scans for secrets
- `grype` - vulnerability scanner
- `git-secrets` - prevents committing secrets
- `truffleHog` - finds secrets in git history
