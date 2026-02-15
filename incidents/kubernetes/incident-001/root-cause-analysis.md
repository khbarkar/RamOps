---
title: "Production pod crash-looping"
difficulty: Beginner
skills: [Debugging, Troubleshooting]
technologies: [Kubernetes, Docker]
description: "Users reporting site is down - pods stuck in CrashLoopBackOff and constantly restarting"
---

# Solution: Single Pod Crashloop

## Root Cause

The `web-frontend` deployment has a misconfigured **liveness probe**. It checks `GET /healthz` on port `8080`, but nginx only listens on port `80` and has no `/healthz` endpoint.

Kubernetes repeatedly kills the container because the liveness probe fails, causing a CrashLoopBackOff.

## How to Diagnose

```bash
kubectl get pods
# Shows STATUS: CrashLoopBackOff or Running with high RESTARTS

kubectl describe pod <pod-name>
# Look at Events — you'll see:
#   Liveness probe failed: Get "http://10.x.x.x:8080/healthz": dial tcp ... connect: connection refused
#   Container web-frontend failed liveness probe, will be restarted

kubectl logs <pod-name>
# Logs look normal — nginx started fine. The issue isn't the app, it's the probe.
```

## Fix

Edit the deployment to point the liveness probe at the correct port and path:

```bash
kubectl edit deployment web-frontend
```

Change the liveness probe from:

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
```

To:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
```

Or remove the liveness probe entirely if a simple health check on `/` is sufficient.

## Key Takeaway

Always verify that liveness and readiness probes match what the application actually serves. A misconfigured probe is one of the most common causes of CrashLoopBackOff in production.
