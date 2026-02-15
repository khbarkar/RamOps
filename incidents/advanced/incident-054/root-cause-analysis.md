---
title: "Side-Channel Attack via CPU Cache Timing"
difficulty: Expert
skills: [CPU Architecture, Security, Side-Channel Attacks]
technologies: [Kubernetes, Hardware Security, Spectre]
description: "Container exploiting CPU cache timing to leak secrets from adjacent containers through Spectre-style side-channel attack"
---

# Root Cause Analysis: Side-Channel Attack via CPU Cache Timing

## Incident Summary
Container exploiting CPU cache timing side-channel to leak secrets from adjacent containers through Spectre-style attack.

## Root Cause
Speculative execution vulnerability in CPU allows attacker to:
1. Train branch predictor to mispredict
2. Speculatively execute code that accesses victim memory
3. Measure cache timing to determine if access occurred
4. Reconstruct secret data bit by bit

## Technical Details
- Modern CPUs use speculative execution for performance
- Mispredicted branches leave traces in CPU cache
- Cache timing differences (hit vs miss) leak information
- Container isolation doesn't prevent cache-based side-channels
- Shared CPU cores between containers enable attack

## Attack Technique
Flush+Reload method:
1. Attacker flushes cache line (clflush instruction)
2. Victim process accesses memory
3. Attacker reloads and times access
4. Fast reload = victim accessed that address
5. Repeat to leak entire secret

## Resolution
1. Detect via perf monitoring (cache-misses, cpu-cycles)
2. Identify attacker container
3. Terminate malicious workload
4. Enable CPU mitigations (retpoline, IBRS, IBPB)
5. Disable hyperthreading if necessary
6. Rotate potentially leaked secrets
7. Implement workload isolation

## Prevention
- Use dedicated nodes for sensitive workloads
- Enable all CPU vulnerability mitigations
- Disable hyperthreading on sensitive nodes
- Implement CPU pinning for isolation
- Use hardware security features (SGX, SEV)
- Regular security audits of workloads
- Monitor for unusual cache behavior

## Lessons Learned
- Software isolation insufficient for hardware vulnerabilities
- Multi-tenancy has fundamental security limits
- Performance vs security tradeoffs (mitigations slow CPU)
- Need for defense in depth
