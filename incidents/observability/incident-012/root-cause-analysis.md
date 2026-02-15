# Solution: Alert Storm from Single Root Cause

## Root Cause

A **single infrastructure failure** (database disk full) triggered **cascading failures** across the entire application stack, causing an **alert storm** of 10+ alerts firing simultaneously:

1. **Root cause**: Database disk reached 100% capacity
2. **Direct impact**: Database stopped accepting writes, connection pool exhausted
3. **Cascading failures**:
   - API requests failing (can't reach database)
   - Cache miss rate increased (can't populate from DB)
   - Queue backlog growing (can't process messages without DB)
   - Authentication failures (session store in DB)
   - Health checks failing
   - Error log volume spiking

The alert system was poorly designed:
- No **alert grouping** - each symptom fired separately
- No **alert hierarchy** - symptoms treated equally to root cause
- No **alert dependencies** - symptom alerts didn't silence when root cause fired
- High **alert frequency** - repeated notifications every minute

Result: On-call engineer overwhelmed with 15+ pages at 3am, making it hard to identify the actual problem.

## How to Diagnose

### 1. Access Alertmanager

```bash
# Open in browser
http://localhost:9093
```

You'll see many alerts:
- DatabaseDiskFull (CRITICAL)
- DatabaseConnectionFailed (CRITICAL)
- APIErrorRateHigh (CRITICAL)
- UserAuthenticationFailing (CRITICAL)
- HighDatabaseLatency (WARNING)
- CacheMissRateHigh (WARNING)
- QueueBacklogGrowing (WARNING)
- ... and more

### 2. Identify the Root Cause Alert

Look for:
- **Infrastructure-level alerts** (disk, memory, network) over application alerts
- **Oldest alert** - what fired first?
- **Critical severity** alerts
- **Dependency patterns** - if DB is down, everything dependent on it fails

In this case: `DatabaseDiskFull` is the root cause.

### 3. SSH and Investigate

```bash
vagrant ssh

# Check disk space
df -h
# Shows: /var/lib/postgresql/data at 100% capacity

# Check what's using space
du -sh /var/lib/postgresql/data/*
# Shows: fillup.bin is consuming 950MB
```

### 4. Check Alert Timeline in Prometheus

```bash
# Open Prometheus
http://localhost:9090

# Query alert history
ALERTS{alertstate="firing"}
```

Sort by time - `DatabaseDiskFull` fired first, then cascading failures.

## Fix: Two-Part Solution

### Part 1: Fix the Immediate Issue

```bash
vagrant ssh

# Free up disk space
sudo rm /var/lib/postgresql/data/fillup.bin

# Verify disk usage is back to normal
df -h /var/lib/postgresql/data
# Should show < 50% usage

# Database should recover automatically
# Alerts will resolve within 1-2 minutes
```

### Part 2: Improve Alert Design

Edit `/etc/alertmanager/alertmanager.yml`:

```bash
vagrant ssh
sudo nano /etc/alertmanager/alertmanager.yml
```

Replace with better configuration:

```yaml
global:
  resolve_timeout: 5m

# Alert routing with intelligent grouping
route:
  receiver: 'default'

  # GROUP related alerts together
  group_by: ['alertname', 'severity', 'component']

  # Wait 30s to batch related alerts (not 1s)
  group_wait: 30s

  # Send updates every 5 minutes (not every second)
  group_interval: 5m

  # Repeat notifications every hour (not every 5 minutes)
  repeat_interval: 1h

  # Child routes for different severities
  routes:
    # Critical alerts - page immediately
    - match:
        severity: critical
      receiver: 'pagerduty'
      group_wait: 10s
      repeat_interval: 30m

    # Warning alerts - send to Slack, grouped
    - match:
        severity: warning
      receiver: 'slack'
      group_wait: 5m
      repeat_interval: 4h

receivers:
  - name: 'default'
    # Fallback receiver

  - name: 'pagerduty'
    # In production: PagerDuty integration
    # For now: same as default

  - name: 'slack'
    # In production: Slack webhook
    # For now: same as default

# Inhibition rules - silence symptoms when root cause fires
inhibit_rules:
  # If DatabaseDiskFull is firing, silence database connection alerts
  - source_match:
      alertname: DatabaseDiskFull
    target_match:
      component: database
    equal: ['cluster']

  # If database alerts are firing, silence application alerts
  - source_match:
      component: database
      severity: critical
    target_match:
      component: api
    equal: ['cluster']

  - source_match:
      component: database
      severity: critical
    target_match:
      component: cache
    equal: ['cluster']

  - source_match:
      component: database
      severity: critical
    target_match:
      component: auth
    equal: ['cluster']
```

Reload Alertmanager:

```bash
sudo systemctl reload alertmanager
```

## Better Alert Design Principles

### 1. Alert Hierarchy

**Infrastructure (bottom layer)**
- Disk full
- Memory exhausted
- Network partition
- Host unreachable

**Platform (middle layer)**
- Database down
- Cache unavailable
- Message queue unreachable

**Application (top layer)**
- API errors
- High latency
- Authentication failures

**Rule**: Fix bottom-layer issues first. Top-layer symptoms will resolve automatically.

### 2. Symptom vs Cause Alerts

| Alert Type | When to Fire | Example |
|------------|--------------|---------|
| **Cause** (actionable) | Root issue detected | Disk >90% full |
| **Symptom** (informational) | Side effect of root cause | API error rate high |

**Best practice**: Page on causes, log symptoms.

### 3. Alert Grouping Strategies

```yaml
# Group by alert name - batches identical alerts
group_by: ['alertname']

# Group by severity - separate critical from warnings
group_by: ['severity']

# Group by component - all database alerts together
group_by: ['component', 'severity']

# Group by cluster - separate prod from staging
group_by: ['cluster', 'severity', 'alertname']
```

### 4. Alert Inhibition (Dependencies)

Silence dependent alerts when parent alert fires:

```yaml
inhibit_rules:
  # Disk full silences database alerts
  - source_match:
      alertname: DatabaseDiskFull
    target_match_re:
      alertname: Database.*
```

### 5. Alert Timing

```yaml
# How long to wait before sending first notification
# (allows time to batch related alerts)
group_wait: 30s

# How often to send updates about grouped alerts
group_interval: 5m

# How often to repeat the same alert if still firing
repeat_interval: 1h  # Not 5m!
```

## Advanced: Alert Design Best Practices

### Define Alert Severity Levels

```yaml
# CRITICAL - wake someone up at 3am
severity: critical
# - Service completely down
# - Data loss imminent
# - Security breach

# WARNING - investigate during business hours
severity: warning
# - Degraded performance
# - Approaching limits
# - Minor errors

# INFO - good to know, no action needed
severity: info
# - Deployment completed
# - Autoscaling triggered
```

### Include Runbooks in Alerts

```yaml
- alert: DatabaseDiskFull
  annotations:
    summary: "Database disk is full"
    description: "Disk usage is {{ $value }}%"
    runbook: "https://wiki.company.com/runbooks/database-disk-full"
    remediation: |
      1. Check disk usage: df -h
      2. Find large files: du -sh /var/lib/postgresql/*
      3. Archive or delete old data
      4. Consider increasing disk size
```

### Use Alert Labels for Routing

```yaml
labels:
  severity: critical
  component: database
  team: platform
  environment: production
  oncall: database-team
```

Route based on labels:

```yaml
routes:
  - match:
      team: database-team
    receiver: database-pagerduty

  - match:
      team: frontend-team
    receiver: frontend-slack
```

### Implement Alert Silencing

For planned maintenance:

```bash
# Silence all alerts for db-server-01 during maintenance
amtool silence add \
  --author="ops-team" \
  --comment="Planned database maintenance" \
  --duration=2h \
  instance=db-server-01
```

### Configure Alert Deduplication

Alertmanager automatically deduplicates:
- Same alert from multiple Prometheus instances
- Repeated firings of the same condition

Ensure alerts have stable labels:

```yaml
# BAD: timestamp in labels creates duplicate alerts
labels:
  timestamp: "{{ $value }}"

# GOOD: stable labels
labels:
  instance: "db-01"
  job: "database"
```

## Production Examples

### AWS CloudWatch to Prometheus Bridge

```yaml
- alert: EBSDiskFull
  expr: aws_ebs_volume_used_bytes / aws_ebs_volume_size_bytes > 0.9
  labels:
    severity: critical
    component: infrastructure
    aws_service: ebs
```

### Kubernetes Pod Alerts

```yaml
- alert: PodCrashLooping
  expr: rate(kube_pod_container_status_restarts_total[5m]) > 0
  labels:
    severity: critical
    component: kubernetes
  annotations:
    summary: "Pod {{ $labels.pod }} is crash looping"

# Silence application errors when pod is crash looping
inhibit_rules:
  - source_match:
      alertname: PodCrashLooping
    target_match:
      component: application
    equal: ['pod']
```

### Multi-Datacenter Alerting

```yaml
# Only alert if issue affects multiple DCs
- alert: ServiceDownGlobal
  expr: |
    count by (service) (
      up{service="api"} == 0
    ) > 2  # Down in more than 2 datacenters
  labels:
    severity: critical
```

## Common Mistakes to Avoid

1. **Too many alerts** - alert fatigue, important alerts missed
2. **No grouping** - alert storm, overwhelming on-call
3. **Paging on symptoms** - wakes people for non-actionable issues
4. **No runbooks** - on-call doesn't know how to fix
5. **Flat hierarchy** - can't distinguish root cause from symptoms
6. **Too frequent repeats** - same alert every minute
7. **No silencing mechanism** - can't mute during maintenance
8. **Alert on everything** - 99% of alerts are false positives

## Key Takeaways

1. **Design alert hierarchy**: Infrastructure → Platform → Application
2. **Page on causes, log symptoms**: Only wake people for actionable issues
3. **Use alert grouping**: Batch related alerts together
4. **Implement inhibition**: Silence symptoms when root cause is known
5. **Include runbooks**: Tell on-call how to fix the problem
6. **Set appropriate thresholds**: Avoid false positives
7. **Review alerts regularly**: Delete noisy, non-actionable alerts
8. **Test alert routing**: Ensure critical alerts reach the right person

## Related Observability Topics

- SLO-based alerting (alert on SLO burn rate, not arbitrary thresholds)
- Multi-window multi-burn-rate alerting
- Alert routing and escalation policies
- On-call rotation and handoff procedures
- Post-incident review of alert effectiveness
- Alert quality metrics (time to detect, false positive rate)
