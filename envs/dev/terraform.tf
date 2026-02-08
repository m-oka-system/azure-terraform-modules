terraform {
  # Terraform のバージョン
  required_version = "~> 1.13.0"

  # リソースプロバイダーのバージョン
  required_providers {
    azurerm = {
      version = "~>4.50.0"
      source  = "hashicorp/azurerm"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13.0"
    }
  }
}
