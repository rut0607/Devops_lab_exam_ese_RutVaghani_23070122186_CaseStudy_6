# Task 6 - Terraform creates sentiment.env
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

resource "local_file" "sentiment_env" {
  filename = "${path.module}/sentiment.env"
  content  = <<-EOT
    APP_NAME=sentiment-app
    VERSION=v4.0.0-final
    BATCH=500
    IMAGE=sentiment-worker:latest
    NODE_PORT=30096
  EOT
}

output "env_file_path" {
  value = local_file.sentiment_env.filename
}
