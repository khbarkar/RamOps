terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

variable "vm_ip" {
  default = "192.168.56.10"
}

# Simulate infrastructure with local files and null resources

# Application config
resource "null_resource" "app_config" {
  triggers = {
    content = jsonencode({
      version     = "1.0.0"
      log_level   = "warn"
      environment = "production"
      port        = 8080
    })
  }

  provisioner "local-exec" {
    command = <<-EOT
      cat > ${path.module}/../generated/app-config.json <<'EOF'
${self.triggers.content}
EOF
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/../generated/app-config.json"
  }
}

# Nginx config
resource "null_resource" "nginx_config" {
  triggers = {
    port = 8080
  }

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/../generated
      cat > ${path.module}/../generated/nginx.conf <<'EOF'
server {
    listen ${self.triggers.port};
    server_name app.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
    }

    location /health {
        return 200 'ok';
    }
}
EOF
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/../generated/nginx.conf"
  }
}

# Service control
resource "null_resource" "app_service" {
  triggers = {
    config_hash = null_resource.app_config.id
  }

  provisioner "local-exec" {
    command = "echo 'App would be running with config version 1.0.0'"
  }
}

output "resources" {
  value = {
    app_config    = "generated/app-config.json"
    nginx_config  = "generated/nginx.conf"
    app_version   = "1.0.0"
  }
}
