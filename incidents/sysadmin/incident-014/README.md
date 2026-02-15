# The Zombie Apocalypse (Lima)

**Difficulty:** Intermediate-Advanced
**Category:** System Administration / Process Management
**Time estimate:** 30-40 minutes

## Scenario

Production alerts wake you at 2am: "10,000+ zombie processes detected". The application server is sluggish. New processes are failing to spawn with "fork: Resource temporarily unavailable". The monitoring dashboard shows the process table is filling up rapidly.

You SSH in and run ps - the output is flooded with processes marked as defunct. The system is approaching the PID limit and will soon be unable to create new processes.

## Prerequisites

- [Lima](https://lima-vm.io/) (installed via Homebrew)
- Basic understanding of Linux processes

## Setup

Run setup from the TUI or:
```bash
./setup-lima.sh
```

This creates a VM with multiple buggy applications creating zombie processes through different mechanisms.

## Your Task

1. SSH into the VM: `limactl shell lima-zombies`
2. Investigate the zombie processes
3. Find the parent processes responsible
4. Understand why zombies are being created
5. Learn about process lifecycle, wait(), SIGCHLD, and proper cleanup
6. Fix all the zombie-creating processes
7. Implement proper process management patterns
8. Run verify from the TUI to confirm no zombies remain

## Hints

Hint 1: Zombies are processes that have terminated but whose exit status hasn't been read by their parent. Use ps aux | grep defunct to see them.

Hint 2: Find zombie parents with: ps -eo pid,ppid,stat,cmd | grep Z. The parent PID is in the second column.

Hint 3: You can't kill a zombie with kill -9 because it's already dead. You need to either kill the parent (so init adopts and reaps the zombies) or fix the parent to call wait().

Hint 4: Check if a process is calling wait() with: strace -p PID -e trace=wait4,waitpid

Hint 5: There are multiple buggy programs creating zombies. Look in /opt for the source code of each one.

Hint 6: Common fixes include: adding wait() calls, setting up SIGCHLD handlers, using signal(SIGCHLD, SIG_IGN) for auto-reaping, or using the double-fork technique.

## Cleanup

Run teardown from the TUI or:
```bash
./teardown-lima.sh
```
