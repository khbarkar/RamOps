terraform {
  required_version = ">= 1.0"
}

# Simple local file resources to simulate infrastructure
# In production, these would be AWS, Azure, or GCP resources

resource "local_file" "app_config" {
  filename = "/tmp/managed-resources/app-config.txt"
  content  = "production-config-v1.2.3"

  lifecycle {
    # Prevent accidental deletion
    prevent_destroy = false
  }
}

resource "local_file" "api_key" {
  filename = "/tmp/managed-resources/api-key.txt"
  content  = "prod-api-key-abc123"
}

resource "local_file" "database_backup" {
  filename = "/tmp/managed-resources/database-backup.txt"
  content  = "daily-backup-enabled"
}

# Output the resource paths
output "managed_resources" {
  value = {
    app_config      = local_file.app_config.filename
    api_key         = local_file.api_key.filename
    database_backup = local_file.database_backup.filename
  }
  description = "Paths to resources managed by Terraform"
}

output "instructions" {
  value = <<-EOT

  Resources have been created at:
    - ${local_file.app_config.filename}
    - ${local_file.api_key.filename}
    - ${local_file.database_backup.filename}

  To detect drift:
    terraform plan

  To restore infrastructure:
    terraform apply

  EOT
}
