# Infrastructure Drift Detection

**Difficulty:** Intermediate
**Category:** Terraform / Infrastructure as Code
**Time estimate:** 25-30 minutes

## Scenario

Your team manages infrastructure using Terraform. Everything was deployed correctly last week, but now the production environment is behaving differently than expected. Someone may have made manual changes directly in the infrastructure, bypassing Terraform.

Your task is to detect the drift, understand what changed, and restore infrastructure to match the Terraform state.

## Prerequisites

- [Vagrant](https://www.vagrantup.com/downloads) >= 2.0
- **Apple Silicon (ARM) Macs - Choose ONE:**
  - **QEMU (FREE, recommended):**
    ```bash
    brew install qemu
    vagrant plugin install vagrant-qemu
    ```
  - **VMware Fusion** (free for personal use)
  - **Parallels Desktop** (14-day trial)
- **Intel Macs / Linux / Windows:**
  - [VirtualBox](https://www.virtualbox.org/) >= 6.0
- Terraform will be installed automatically in the VM

## What You'll Learn

- How infrastructure drift occurs
- Using `terraform plan` to detect drift
- Understanding Terraform state vs actual infrastructure
- Strategies for drift remediation
- Preventing unauthorized manual changes

## Setup

```bash
./setup.sh
```

This creates a VM with Terraform installed, deploys infrastructure, and then simulates manual changes to create drift.

## Your Task

1. SSH into the VM: `vagrant ssh`
2. Navigate to the Terraform directory: `cd /vagrant/tf`
3. Detect drift using Terraform commands
4. Identify what changed manually
5. Restore infrastructure to match Terraform configuration
6. Run `./verify.sh` to confirm drift is resolved

## Hints

<details>
<summary>Hint 1</summary>
Use <code>terraform plan</code> to detect differences between the current state and actual infrastructure.
</details>

<details>
<summary>Hint 2</summary>
Check the files in <code>/tmp/managed-resources/</code> to see what the infrastructure currently looks like.
</details>

<details>
<summary>Hint 3</summary>
Someone manually modified files that Terraform manages. You need to reapply the Terraform configuration.
</details>

<details>
<summary>Hint 4</summary>
Use <code>terraform apply</code> to restore infrastructure to the desired state defined in your .tf files.
</details>

## Cleanup

```bash
./teardown.sh
```

## Production Parallels

This scenario mirrors:
- Manual changes in AWS console bypassing Terraform
- Direct database schema changes not reflected in IaC
- Infrastructure modifications during incident response
- Lack of drift detection in CI/CD pipelines
- Missing change management processes
