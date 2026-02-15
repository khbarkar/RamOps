# Solution: Infrastructure Drift Detection

## Root Cause

**Infrastructure drift** occurred when someone made manual changes to infrastructure that was managed by Terraform, bypassing the Infrastructure as Code (IaC) workflow. This created a mismatch between:
- The **desired state** defined in Terraform configuration files
- The **recorded state** in Terraform's state file
- The **actual state** of the infrastructure

Manual changes are dangerous because:
1. They're not tracked in version control
2. They can be overwritten by the next `terraform apply`
3. They create confusion about what's deployed
4. They bypass code review and change management processes

## How to Diagnose

### 1. Run Terraform Plan

```bash
cd /vagrant/tf
terraform plan
```

Output showing drift:
```
Terraform will perform the following actions:

  # local_file.app_config will be updated in-place
  ~ resource "local_file" "app_config" {
      ~ content = "Manually modified content - DRIFT!" -> "production-config-v1.2.3"
        id      = "..."
    }

  # local_file.api_key will be updated in-place
  ~ resource "local_file" "api_key" {
      ~ content = "unauthorized-key" -> "prod-api-key-abc123"
        id      = "..."
    }

  # local_file.database_backup will be created
  + resource "local_file" "database_backup" {
      + content  = "daily-backup-enabled"
      + filename = "/tmp/managed-resources/database-backup.txt"
      + id       = (known after apply)
    }

Plan: 1 to add, 2 to change, 0 to destroy.
```

The `~` indicates resources that need to be updated, `+` means create, `-` means destroy.

### 2. Check Actual Resources

```bash
cat /tmp/managed-resources/app-config.txt
# Shows: "Manually modified content - DRIFT!"
# Expected: "production-config-v1.2.3"

ls /tmp/managed-resources/
# database-backup.txt is missing
```

### 3. Compare with Terraform State

```bash
terraform show
# Shows what Terraform thinks is deployed

terraform state list
# Lists all resources in state
```

## Fix: Restore Infrastructure to Desired State

### Option 1: Apply Terraform Configuration (Recommended)

Restore infrastructure to match the Terraform code:

```bash
terraform apply
```

Review the plan, then confirm. This will:
- Overwrite manually changed files with correct content
- Recreate deleted resources
- Restore everything to the desired state

### Option 2: Import Manual Changes (If You Want to Keep Them)

If the manual changes were intentional and should be preserved:

```bash
# Update Terraform config to match manual changes
# Edit main.tf to reflect new desired state

# Then apply
terraform apply
```

**Important**: Always update Terraform code first, then apply. Never leave drift unresolved.

### Option 3: Detect and Alert on Drift Continuously

Set up automated drift detection:

```bash
# In CI/CD pipeline
terraform plan -detailed-exitcode
# Exit code 0 = no changes
# Exit code 1 = error
# Exit code 2 = changes needed (drift detected)
```

## Understanding Terraform State

### State File Purpose

The `terraform.tfstate` file tracks:
- What resources Terraform created
- Resource IDs and attributes
- Dependency graph
- Mapping between config and real infrastructure

### State Drift vs Configuration Drift

- **State drift**: Actual infrastructure differs from state file
- **Configuration drift**: Code differs from what's deployed

Both are detected by `terraform plan`.

### State Locking

For team environments, use remote state with locking:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

## Production Best Practices

### 1. Enable Read-Only Access

Use least-privilege IAM policies:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "ec2:*",
        "s3:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
}
```

Only allow modifications via Terraform service accounts.

### 2. Automated Drift Detection

Run drift detection in CI/CD:

```yaml
# GitHub Actions example
name: Terraform Drift Detection
on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  drift:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: hashicorp/setup-terraform@v1

      - name: Terraform Init
        run: terraform init

      - name: Detect Drift
        run: |
          terraform plan -detailed-exitcode
          EXIT_CODE=$?
          if [ $EXIT_CODE -eq 2 ]; then
            echo "DRIFT DETECTED!"
            exit 1
          fi
```

### 3. Use Terraform Cloud/Enterprise

Benefits:
- Remote state storage with locking
- Automated drift detection
- Policy enforcement (Sentinel)
- Audit logs
- RBAC for Terraform operations

### 4. Prevent Manual Changes

- **Cloud audit logs**: AWS CloudTrail, Azure Activity Log, GCP Cloud Audit Logs
- **Alerts**: Notify on non-Terraform changes
- **Policy enforcement**: Service Control Policies, Azure Policy, GCP Organization Policy

Example AWS EventBridge rule:

```json
{
  "source": ["aws.ec2"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventName": ["RunInstances", "TerminateInstances"],
    "userIdentity": {
      "type": ["IAMUser", "AssumedRole"]
    }
  }
}
```

Alert if the user is not the Terraform service account.

### 5. Import Existing Resources

If resources were created manually, import them:

```bash
# Add resource to Terraform config
resource "aws_instance" "example" {
  # ... configuration
}

# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0

# Verify
terraform plan
```

### 6. Use Terraform Refresh Carefully

```bash
terraform refresh
```

Updates state file with actual infrastructure. Use cautiously:
- Can mask drift instead of fixing it
- Modern Terraform runs refresh automatically during `plan`
- Prefer explicit `terraform apply` to restore desired state

### 7. Implement Change Management

Process for emergency manual changes:

1. Make change (document reason)
2. Create drift ticket immediately
3. Update Terraform code within 24 hours
4. Run `terraform plan` to verify sync
5. Review in next planning meeting

## Common Drift Scenarios

### Manual Console Changes

```
Developer: "I just need to test this security group rule..."
Result: Production security group differs from Terraform
Fix: terraform apply (overwrites manual change)
```

### Incident Response Modifications

```
3am outage: Scale up instances manually
Next day: Terraform wants to scale back down
Fix: Update Terraform config, then apply
```

### Auto-Scaling Groups

```
ASG scales up automatically
Terraform plan shows drift (wants to scale down)
Fix: Use lifecycle.ignore_changes for dynamic attributes
```

```hcl
resource "aws_autoscaling_group" "example" {
  # ...

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
```

## Terraform Commands for Drift Management

```bash
# Detect drift
terraform plan -detailed-exitcode

# Show current state
terraform show

# List all resources
terraform state list

# Show specific resource
terraform state show aws_instance.example

# Refresh state (sync with actual)
terraform refresh

# Restore infrastructure to desired state
terraform apply

# Remove resource from state (doesn't delete resource)
terraform state rm aws_instance.example

# Move resource in state
terraform state mv aws_instance.old aws_instance.new

# Import existing resource
terraform import aws_instance.example i-1234567890
```

## Key Takeaways

1. **Never make manual changes** to Terraform-managed infrastructure
2. **Run `terraform plan` regularly** to detect drift
3. **Automate drift detection** in CI/CD pipelines
4. **Use cloud audit logs** to track who made changes
5. **Implement RBAC** to prevent unauthorized modifications
6. **Document emergency procedures** for when manual changes are necessary
7. **Always update Terraform code** to match desired state
8. **Use remote state with locking** for team collaboration
9. **Consider Terraform Cloud** for enterprise drift detection
10. **Treat infrastructure as immutable** - destroy and recreate, don't modify

## Related Issues

- Terraform state file conflicts in team environments
- Deleted resources that Terraform tries to recreate
- Attribute drift (changes to resource properties)
- Resource tagging drift
- Security group rule proliferation
- Manual scaling during incidents
- Cloud provider automatic changes (AWS managed prefix lists, etc.)
