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

provider "azurerm" {
  # サブスクリプション ID (環境変数 ARM_SUBSCRIPTION_ID を設定していない場合は必要)
  # subscription_id = "00000000-0000-0000-0000-000000000000"

  # リソースプロバイダーの登録モード (core, extended, all, none, legacy)
  resource_provider_registrations = "none"

  # Entra 認証を使用してストレージアカウントにアクセス
  storage_use_azuread = true

  # サブスクリプションに明示的に登録するリソースプロバイダー
  resource_providers_to_register = [
    "Microsoft.Advisor",
    "Microsoft.DBforMySQL",
    "Microsoft.KeyVault",
    "Microsoft.Network",
    "Microsoft.Web",
  ]
  features {
    key_vault {
      # Azure Key Vault の論理削除を無効にする
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      # リソースグループ内にリソースがあっても削除する
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "http" {}
