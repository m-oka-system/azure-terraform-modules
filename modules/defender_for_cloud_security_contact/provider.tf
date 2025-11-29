terraform {
  required_providers {
    # リソースプロバイダーのバージョン
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.7.0"
    }
  }
}
