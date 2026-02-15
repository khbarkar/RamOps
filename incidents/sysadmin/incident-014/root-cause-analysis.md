# Root Cause Analysis: The Zombie Apocalypse

## Incident Summary

The system accumulated thousands of zombie (defunct) processes, approaching the PID limit and preventing new processes from spawning. Multiple buggy applications were creating child processes without properly reaping them.

## Root Cause

Zombie processes are created when:
1. A child process terminates (calls `exit()`)
2. The parent process fails to call `wait()` or `waitpid()` to read the exit status
3. The kernel keeps the process entry (PID and exit status) until the parent reaps it

Three different applications had bugs causing zombies:
- **worker_manager.py**: Forked children without calling `wait()`
- **bash_backgrounder.sh**: Used `&` to background jobs without `wait` command
- **broken_daemon.c**: Forked children and never called `wait()`

## Technical Details

**Process Lifecycle:**
1. `fork()` - Parent creates child process
2. `exec()` - Child runs new program (optional)
3. `exit()` - Child terminates
4. `wait()` - Parent reads exit status and reaps child
5. Kernel frees process table entry

**Zombie State:**
- Process has terminated but not been reaped
- Shows as `<defunct>` in `ps` output
- State: Z (zombie)
- Cannot be killed with `kill -9` (already dead)
- Consumes a PID slot but no other resources

**Why Zombies Matter:**
- Each zombie holds a PID
- Systems have a maximum PID limit (default: 32768)
- PID exhaustion prevents new process creation
- Can cause system-wide denial of service

## Resolution

**Immediate Fixes:**

1. **Kill the parent processes:**
```bash
systemctl stop worker-manager.service
systemctl stop bash-backgrounder.service  
systemctl stop broken-daemon.service
```
When a parent dies, init/systemd adopts orphaned children and reaps them.

2. **Fix the Python code:**
```python
import os
import time

def spawn_worker():
    pid = os.fork()
    if pid == 0:
        time.sleep(2)
        os._exit(0)
    return pid

workers = []
for i in range(100):
    pid = spawn_worker()
    workers.append(pid)

# Reap all children
for pid in workers:
    os.waitpid(pid, 0)
```

3. **Fix the bash script:**
```bash
#!/bin/bash
for i in {1..50}; do
  (sleep 3; exit 0) &
done
wait  # Wait for all background jobs
```

4. **Fix the C daemon:**
```c
#include <signal.h>

// Option 1: Set up SIGCHLD handler
void sigchld_handler(int sig) {
    while (waitpid(-1, NULL, WNOHANG) > 0);
}

signal(SIGCHLD, sigchld_handler);

// Option 2: Ignore SIGCHLD for auto-reaping
signal(SIGCHLD, SIG_IGN);

// Option 3: Double-fork to reparent to init
pid_t pid = fork();
if (pid == 0) {
    pid_t pid2 = fork();
    if (pid2 == 0) {
        // Child work here
        exit(0);
    }
    exit(0);  // First child exits immediately
}
waitpid(pid, NULL, 0);  // Reap first child
```

## Prevention

**Best Practices:**

1. **Always reap children:**
   - Call `wait()` or `waitpid()` after forking
   - Set up SIGCHLD handlers for asynchronous reaping

2. **Use signal(SIGCHLD, SIG_IGN):**
   - Tells kernel to auto-reap terminated children
   - No need for explicit `wait()` calls

3. **Double-fork technique:**
   - Fork twice, first child exits immediately
   - Grandchild gets reparented to init
   - Init automatically reaps it

4. **Use modern process managers:**
   - systemd handles process lifecycle
   - supervisord manages daemons
   - Docker/containers isolate processes

5. **Monitor zombie count:**
   - Alert on: `ps aux | grep defunct | wc -l`
   - Track process table usage

## Key Learnings

- Zombies are terminated processes waiting to be reaped
- Parents must call `wait()` to clean up children
- Killing zombies doesn't work - kill the parent instead
- SIGCHLD handling is critical for long-running daemons
- Modern init systems (systemd) handle reaping automatically
- Understanding process lifecycle prevents resource exhaustion
