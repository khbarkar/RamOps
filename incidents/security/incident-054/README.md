# Side-Channel Attack via CPU Cache Timing

**Difficulty:** Expert
**Category:** Advanced
**Time estimate:** 90-120 minutes

## Scenario

Your security team detected unusual CPU cache behavior on a multi-tenant Kubernetes node. A container is making millions of memory accesses with suspicious timing patterns. Analysis suggests a Spectre-style side-channel attack attempting to leak secrets from adjacent containers through CPU cache timing.

The attacker is exploiting speculative execution and cache timing to read memory from other processes on the same physical CPU core.

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/) for Kubernetes cluster
- Understanding of CPU architecture and caching
- Familiarity with Spectre/Meltdown attacks
- Knowledge of side-channel attacks
- 4GB+ RAM free

## What You'll Learn

- CPU cache architecture (L1, L2, L3)
- Speculative execution vulnerabilities
- Cache timing side-channel attacks
- Flush+Reload and Prime+Probe techniques
- Container isolation limitations
- Hardware-level security mitigations

## Setup

```bash
./setup.sh
```

This creates a Kubernetes cluster with a container performing cache timing attacks.

## Your Task

1. Detect the side-channel attack
2. Understand the attack technique being used
3. Identify what data is being targeted
4. Implement mitigations to prevent the attack
5. Assess what data may have been leaked

## Hints

Hint 1: Monitor CPU cache misses: `perf stat -e cache-misses,cache-references kubectl exec -it attacker-pod -- ./attack`. High cache miss rates with specific patterns indicate timing attacks.

Hint 2: Side-channel attacks rely on timing differences. Use `perf record` to capture timing data: `perf record -e cpu-cycles kubectl exec attacker-pod -- ./program`.

Hint 3: Flush+Reload attack: Attacker flushes cache line (clflush), victim accesses memory, attacker times reload. Fast reload = victim accessed it. Check for clflush instructions.

Hint 4: Prime+Probe attack: Attacker fills cache set, victim runs, attacker measures eviction. Slower access = victim used that cache set. Look for patterns of memory access.

Hint 5: Check CPU vulnerabilities: `grep . /sys/devices/system/cpu/vulnerabilities/*`. Look for Spectre, Meltdown, L1TF, MDS vulnerabilities and their mitigation status.

Hint 6: Spectre exploits speculative execution. CPU speculatively executes code based on branch prediction, leaving traces in cache. Check if CPU has speculative execution mitigations enabled.

Hint 7: Container isolation doesn't protect against side-channels. Containers on same node share CPU caches. Use `lscpu` to see cache topology and which containers share cores.

Hint 8: Mitigations: Disable hyperthreading (`echo off > /sys/devices/system/cpu/smt/control`), use CPU pinning to isolate sensitive workloads, enable kernel mitigations (retpoline, IBRS, IBPB).

Hint 9: For Kubernetes: Use Pod Security Standards to restrict privileged containers, implement node affinity to separate sensitive workloads, consider dedicated nodes for high-security workloads.

Hint 10: Check what the attacker is targeting: Look at memory access patterns. Are they probing kernel memory? Adjacent container memory? Crypto keys? Use `strace` to see system calls.

Hint 11: Advanced: Understand cache sets and ways. Modern CPUs have set-associative caches. Attacker can determine which cache set victim uses by timing evictions. Read Intel/AMD architecture manuals.

Hint 12: Real-world impact: Spectre/Meltdown allowed reading arbitrary memory. In cloud environments, this means reading secrets from other tenants. Assess blast radius - what secrets were in memory?

## Cleanup

```bash
./teardown.sh
```

## Production Parallels

This scenario mirrors:
- Real Spectre/Meltdown vulnerabilities (CVE-2017-5753, CVE-2017-5754)
- Cloud provider multi-tenancy security concerns
- Hardware-level security vulnerabilities
- Limitations of software isolation
- Need for hardware security features (Intel SGX, AMD SEV)
- Why some cloud providers disabled hyperthreading

## Further Reading

- [Spectre Attack Paper](https://spectreattack.com/spectre.pdf)
- [Meltdown Attack Paper](https://meltdownattack.com/meltdown.pdf)
- [Google Project Zero: Reading Privileged Memory](https://googleprojectzero.blogspot.com/2018/01/reading-privileged-memory-with-side.html)
- [Intel's Speculative Execution Side Channel Mitigations](https://www.intel.com/content/www/us/en/developer/articles/technical/software-security-guidance/technical-documentation/speculative-execution-side-channel-mitigations.html)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
