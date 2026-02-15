# Solution: Memory Leak in Production

## Root Cause

The `data-processor` application has a **memory leak**. The Python code appends event data to a list (`leaked_data`) that is never cleared, causing unbounded memory growth. Once the container's memory usage exceeds the configured limit (128Mi), Kubernetes invokes the **OOMKiller** to terminate the container.

The pod then restarts, appears healthy for a few minutes, and the cycle repeats.

## How to Diagnose

### 1. Check Pod Status

```bash
kubectl get pods
# Shows STATUS: Running with high RESTARTS count (e.g., 5, 10, 15...)
```

### 2. Inspect Termination Reason

```bash
kubectl describe pod <pod-name>
# Look at Events and Container Status:
#   Last State: Terminated
#     Reason: OOMKilled
#     Exit Code: 137
```

Exit code 137 = 128 + 9 (SIGKILL from OOMKiller)

### 3. Monitor Memory Usage

```bash
kubectl top pod <pod-name>
# Watch memory grow over time:
#   NAME              CPU(cores)   MEMORY(bytes)
#   data-processor    50m          45Mi   (after 30s)
#   data-processor    51m          75Mi   (after 60s)
#   data-processor    52m          110Mi  (after 90s)
#   data-processor    53m          128Mi  (OOMKilled!)
```

### 4. Check Application Logs

```bash
kubectl logs <pod-name>
# Shows:
#   Processed 100 events, leaked_data size: 100
#   Processed 200 events, leaked_data size: 200
#   ...
#   Processed 1000 events, leaked_data size: 1000
```

The growing list indicates a memory leak.

## Fix Options

### Option A: Fix the Memory Leak (Proper Solution)

Edit the application code to clear old data:

```bash
kubectl edit deployment data-processor
```

Replace the problematic loop with:

```python
# Fixed version - implements a circular buffer
MAX_BUFFER_SIZE = 100
recent_data = []

while True:
    event_data = {
        'id': counter,
        'timestamp': time.time(),
        'payload': 'x' * 10000
    }

    # Only keep recent events
    recent_data.append(event_data)
    if len(recent_data) > MAX_BUFFER_SIZE:
        recent_data.pop(0)  # Remove oldest

    counter += 1
    time.sleep(0.1)
```

### Option B: Increase Memory Limit (Temporary Workaround)

If you can't fix the code immediately, increase the memory limit to buy time:

```bash
kubectl edit deployment data-processor
```

Change:

```yaml
resources:
  limits:
    memory: "128Mi"
```

To:

```yaml
resources:
  limits:
    memory: "512Mi"  # or higher
```

**Warning:** This doesn't fix the leak, only delays the inevitable OOMKill.

### Option C: Add Restart Policy with Longer Delay

Not recommended but possible - let it crash and restart periodically:

```yaml
spec:
  template:
    spec:
      restartPolicy: Always
```

This is already the default. The problem will continue.

## Kubernetes OOMKiller Behavior

When a container exceeds its memory limit:

1. **Kernel OOMKiller** is invoked
2. Container is killed with `SIGKILL` (exit code 137)
3. Kubernetes marks termination reason as `OOMKilled`
4. Pod is automatically restarted (due to `restartPolicy: Always`)
5. Process repeats until memory limit is increased or leak is fixed

## Key Takeaways

1. **Set appropriate memory limits** based on actual application needs
2. **Monitor memory usage** in production with tools like Prometheus/Grafana
3. **Use memory profiling** during development to catch leaks early
4. **Set up alerts** for high memory usage and frequent OOMKills
5. **Memory requests vs limits**:
   - **Requests**: Memory guaranteed to the pod (for scheduling)
   - **Limits**: Maximum memory before OOMKill
6. **Exit code 137** always indicates OOMKiller was invoked

## Production Best Practices

```yaml
resources:
  requests:
    memory: "256Mi"  # What you expect under normal load
  limits:
    memory: "512Mi"  # Headroom for spikes, not infinite leaks

# Add monitoring
annotations:
  prometheus.io/scrape: "true"

# Set up alerts
- alert: PodMemoryUsageHigh
  expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.8
  for: 5m

- alert: PodOOMKilled
  expr: kube_pod_container_status_last_terminated_reason{reason="OOMKilled"} == 1
```

## Related Incidents

- JVM applications with no max heap size set
- Cache implementations with no eviction policy
- Log buffers that grow unbounded
- Websocket connections holding references indefinitely
- Image processing services loading full images into memory
