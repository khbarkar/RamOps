# Infrastructure Drift Detection

**Difficulty:** Intermediate
**Category:** Terraform / Infrastructure as Code
**Time estimate:** 25-30 minutes

## Scenario

Your team manages infrastructure using Terraform. Everything was deployed correctly last week, but now the production environment is behaving differently than expected. Someone may have made manual changes directly in the infrastructure, bypassing Terraform.

Your task is to detect the drift, understand what changed, and restore infrastructure to match the Terraform state.

## Prerequisites

- [Lima](https://lima-vm.io/) (installed via Homebrew)
- Terraform will be installed automatically in the VM

## What You'll Learn

- How infrastructure drift occurs
- Using `terraform plan` to detect drift
- Understanding Terraform state vs actual infrastructure
- Strategies for drift remediation
- Preventing unauthorized manual changes

## Setup

Run setup from the TUI or:
```bash
./setup-lima.sh
```

This creates a VM with Terraform installed, deploys infrastructure, and then simulates manual changes to create drift.

## Your Task

1. SSH into the VM: `limactl shell lima-terraform-drift`
2. Navigate to the Terraform directory: `cd /opt/terraform`
3. Detect drift using Terraform commands
4. Identify what changed manually
5. Restore infrastructure to match Terraform configuration
6. Run verify from the TUI to confirm drift is resolved

## Hints

Hint 1: Use terraform plan to detect differences between the current state and actual infrastructure.

Hint 2: Check the files in /tmp/managed-resources/ to see what the infrastructure currently looks like.

Hint 3: Someone manually modified files that Terraform manages. You need to reapply the Terraform configuration.

Hint 4: Use terraform apply to restore infrastructure to the desired state defined in your .tf files.

## Cleanup

Run teardown from the TUI or:
```bash
./teardown-lima.sh
```

## Production Parallels

This scenario mirrors:
- Manual changes in AWS console bypassing Terraform
- Direct database schema changes not reflected in IaC
- Infrastructure modifications during incident response
- Lack of drift detection in CI/CD pipelines
- Missing change management processes
