# Terraform State Drift Detection (Vagrant)

**Difficulty:** Beginner-Intermediate
**Category:** Terraform / Infra as Code
**Time estimate:** 15-20 minutes

## Scenario

Infrastructure is managed with Terraform. Engineers made manual changes to config files without updating Terraform. Use `terraform plan` to detect drift and `terraform apply` to revert the unauthorized changes.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- [Vagrant](https://www.vagrantup.com/downloads) >= 2.0
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) >= 6.0
- `jq`

## Setup

```bash
./setup.sh
```

This creates a VM, applies Terraform config, then makes out-of-band manual changes to simulate drift.

## Your Task

1. `cd tf && terraform plan` to detect drift
2. Examine what changed
3. `terraform apply` to revert to managed state
4. `./verify.sh` to confirm

## Cleanup

```bash
./teardown.sh
```
