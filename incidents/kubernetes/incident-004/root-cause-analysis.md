# Root Cause Analysis: Incident-004

## Summary

**Incident:** Application pod crash-looping with write errors
**Duration:** Until fixed
**Impact:** Log processing service unavailable
**Root Cause:** Pod's ephemeral storage filled up due to unbounded log file growth

## Timeline

1. Pod starts and begins writing log files to `/data/logs/`
2. EmptyDir volume has a 50Mi size limit
3. Application writes 5MB log files every 2 seconds
4. After ~20 seconds, volume reaches capacity (50Mi)
5. Subsequent write operations fail with "No space left on device"
6. Application crashes when it can't write critical files
7. Pod restarts, cycle repeats

## Diagnosis

### Symptoms Observed

```bash
kubectl get pods
# NAME                            READY   STATUS             RESTARTS   AGE
# log-processor-xxxxx             0/1     CrashLoopBackOff   5          3m
```

### Investigation Steps

**1. Check pod logs:**
```bash
kubectl logs log-processor-xxxxx
```

Logs show:
```
ERROR: Failed to write log file - No space left on device
Disk usage:
Filesystem      Size  Used Avail Use% Mounted on
overlay          50M   50M     0 100% /data
```

**2. Examine pod events:**
```bash
kubectl describe pod log-processor-xxxxx
```

Events might show:
```
Warning  Evicted  Pod ephemeral local storage usage exceeds the total limit of containers 100Mi
```

**3. Check deployment configuration:**
```bash
kubectl get deployment log-processor -o yaml
```

Found the issues:
```yaml
resources:
  limits:
    ephemeral-storage: "100Mi"  # Very small limit
volumes:
  - name: data
    emptyDir:
      sizeLimit: "50Mi"  # Even smaller limit
```

**4. Exec into the pod (if it's running):**
```bash
kubectl exec -it log-processor-xxxxx -- sh
df -h /data
du -sh /data/logs/*
```

Shows `/data` is 100% full with log files.

## Root Cause

The application continuously writes log files without:
1. **Log rotation** - old logs are never deleted
2. **Size limits** - no cap on total log volume
3. **Monitoring** - no alerts before disk fills

The emptyDir volume has a tiny 50Mi limit, which fills in seconds. Once full, all write operations fail, causing the application to crash.

## Fix

### Option 1: Clean Up Log Files

Exec into the pod and manually remove old logs:

```bash
kubectl exec -it log-processor-xxxxx -- sh
cd /data/logs
ls -lh  # see the log files
rm app-*.log  # delete old logs
```

**Problem:** This is temporary - logs will fill up again.

### Option 2: Increase Volume Size

Edit the deployment to increase storage limits:

```bash
kubectl edit deployment log-processor
```

Change:
```yaml
resources:
  limits:
    ephemeral-storage: "2Gi"  # Increase from 100Mi
volumes:
  - name: data
    emptyDir:
      sizeLimit: "1Gi"  # Increase from 50Mi
```

**Problem:** Still temporary - eventually fills up without rotation.

### Option 3: Implement Log Rotation (PROPER FIX)

Update the application to rotate logs:

```yaml
command:
  - /bin/sh
  - -c
  - |
    mkdir -p /data/logs
    counter=0
    while true; do
      logfile="/data/logs/app-${counter}.log"
      dd if=/dev/zero of="$logfile" bs=1M count=5 2>/dev/null

      counter=$((counter + 1))

      # Delete logs older than 5 files (keep only recent 5)
      ls -t /data/logs/app-*.log | tail -n +6 | xargs rm -f

      sleep 2
    done
```

Or use a proper logging solution:
- Send logs to stdout (let Kubernetes handle them)
- Use a sidecar container with log rotation (e.g., logrotate)
- Ship logs to external system (Elasticsearch, Loki, CloudWatch)

### Option 4: Log to stdout Instead (BEST PRACTICE)

Remove file logging entirely:

```yaml
command:
  - /bin/sh
  - -c
  - |
    counter=0
    while true; do
      echo "$(date): Processing batch $counter"
      counter=$((counter + 1))
      sleep 2
    done
```

Kubernetes automatically handles stdout logs with rotation.

## Verification

After implementing the fix:

```bash
kubectl get pods
# NAME                            READY   STATUS    RESTARTS   AGE
# log-processor-xxxxx             1/1     Running   0          2m

kubectl exec log-processor-xxxxx -- df -h /data
# Filesystem      Size  Used Avail Use% Mounted on
# overlay         1.0G  25M   999M   3% /data
```

Watch for 5 minutes to ensure disk usage stabilizes and doesn't grow unbounded.

## Lessons Learned

### What Went Wrong

1. **No log rotation policy** - logs accumulated indefinitely
2. **Insufficient storage allocation** - 50Mi too small even with rotation
3. **No monitoring** - no alerts before disk filled
4. **Writing to disk unnecessarily** - should log to stdout instead

### Prevention Strategies

**1. Use stdout for container logs:**
```yaml
# Let Kubernetes handle log rotation
echo "log message" >> /dev/stdout
```

**2. Set appropriate storage limits:**
```yaml
resources:
  limits:
    ephemeral-storage: "2Gi"  # Reasonable size
```

**3. Implement log rotation:**
- Use `logrotate` in sidecar
- Rotate by size/time
- Keep limited history (e.g., last 5 files)

**4. Monitor disk usage:**
```yaml
# Add monitoring for ephemeral storage
# Alert when usage > 80%
```

**5. Use external log storage:**
- FluentBit/Fluentd to Elasticsearch
- Promtail to Loki
- CloudWatch/Stackdriver for cloud providers

## Additional Notes

### emptyDir Volume Characteristics

- **Lifecycle:** Exists only while pod is running
- **Storage:** Uses node's disk space
- **Size limit:** Can be enforced with `sizeLimit`
- **Performance:** Fast (local disk), but ephemeral

### Kubernetes Log Best Practices

1. **Write logs to stdout/stderr** - simplest approach
2. **Kubernetes auto-rotates** logs in `/var/log/containers/`
3. **Use log aggregation** for persistence (ELK, Loki, etc.)
4. **Set log retention policies** at cluster level
5. **Monitor pod ephemeral storage** metrics

### Common Disk Fill Scenarios

- Application logs without rotation
- Cache files growing unbounded
- Temp files not cleaned up
- Database WAL/binlogs not purged
- Core dumps accumulating
