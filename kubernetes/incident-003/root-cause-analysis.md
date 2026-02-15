# Solution: DNS Outage

## Diagnosis Steps

### 1. Check CoreDNS Pod Status

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

You might see CoreDNS pods in `CrashLoopBackOff` or running but ineffective.

### 2. Check CoreDNS Logs

```bash
kubectl logs -n kube-system -l k8s-app=kube-dns
```

Look for error messages like:
```
plugin/errors: 2 Corefile:13 - Error during parsing: Unknown directive 'forword'
```

### 3. Test DNS Resolution

```bash
kubectl exec -it deploy/backend -- nslookup database
kubectl exec -it deploy/backend -- nslookup kubernetes.default
kubectl exec -it deploy/backend -- nslookup google.com
```

All of these should fail or timeout.

### 4. Inspect CoreDNS ConfigMap

```bash
kubectl get configmap coredns -n kube-system -o yaml
```

Look for the typo in the Corefile: `forword` instead of `forward`.

## The Fix

### Option 1: Edit the ConfigMap Directly

```bash
kubectl edit configmap coredns -n kube-system
```

Find the line:
```
forword . /etc/resolv.conf {
```

Change it to:
```
forward . /etc/resolv.conf {
```

Save and exit.

### Option 2: Patch the ConfigMap

```bash
kubectl get configmap coredns -n kube-system -o yaml > coredns-fixed.yaml
```

Edit `coredns-fixed.yaml` to fix the typo, then apply:

```bash
kubectl apply -f coredns-fixed.yaml
```

### Option 3: One-Line Fix

```bash
kubectl get configmap coredns -n kube-system -o yaml | \
  sed 's/forword/forward/' | \
  kubectl apply -f -
```

## Restart CoreDNS

After fixing the ConfigMap, restart CoreDNS to pick up the changes:

```bash
kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system
```

## Verify the Fix

Wait a few seconds for DNS to stabilize, then test:

```bash
kubectl exec -it deploy/backend -- nslookup database
kubectl exec -it deploy/backend -- nslookup google.com
```

Both should now resolve successfully.

Run the verification script:

```bash
./verify.sh
```

## What Went Wrong?

The CoreDNS Corefile had a typo: `forword` instead of `forward`. This is a common mistake during manual configuration changes or copy-paste errors. CoreDNS couldn't parse the configuration, causing it to fail to forward external DNS queries.

## Production Parallels

This scenario mirrors real incidents where:
- Manual edits to CoreDNS config introduce typos
- ConfigMap updates during cluster upgrades go wrong
- Automated tools generate malformed DNS configurations
- Copy-paste errors from documentation cause outages
- Missing validation on DNS config changes

## Prevention

- Always validate CoreDNS config syntax before applying
- Use GitOps to version-control cluster configurations
- Test DNS changes in a non-production environment first
- Monitor CoreDNS logs for configuration errors
- Set up alerts for CoreDNS pod restarts or crashloops
