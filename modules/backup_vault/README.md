# Azure Backup Vault Module

このモジュールは、Azure Backupのバックアップコンテナー（Data Protection Backup Vault）とBlob Storageのバックアップ設定を作成します。

## 機能

- Azure Data Protection Backup Vault の作成
- Blob Storage 用のバックアップポリシーの作成
- Blob Storage のバックアップインスタンスの設定
- バックアップに必要なロール割り当て（Storage Account Backup Contributor）の自動設定

## リソース

このモジュールは以下のリソースを作成します：

- `azurerm_data_protection_backup_vault` - バックアップコンテナー
- `azurerm_data_protection_backup_policy_blob_storage` - Blob Storage用のバックアップポリシー
- `azurerm_data_protection_backup_instance_blob_storage` - Blob Storageのバックアップインスタンス
- `azurerm_role_assignment` - Storage Account Backup Contributorロールの割り当て

## 使用例

### main.tf

```hcl
module "backup_vault" {
  source              = "../../modules/backup_vault"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  random              = local.common.random
  backup_vault        = var.backup_vault
  backup_policy_blob  = var.backup_policy_blob
  backup_instance_blob = {
    app = {
      name                 = "app"
      target_backup_vault  = "primary"
      target_backup_policy = "daily"
      storage_account_id   = module.storage.storage_account["app"].id
    }
  }
}
```

### variables.tf

```hcl
variable "backup_vault" {
  description = "バックアップコンテナーの設定"
  type = map(object({
    name           = string
    datastore_type = string
    redundancy     = string
  }))
  default = {
    primary = {
      name           = "primary"
      datastore_type = "VaultStore"
      redundancy     = "LocallyRedundant"  # LocallyRedundant, GeoRedundant, ZoneRedundant
    }
  }
}

variable "backup_policy_blob" {
  description = "Blob Storage用のバックアップポリシー設定"
  type = map(object({
    name                = string
    target_backup_vault = string
    retention_duration  = string
  }))
  default = {
    daily = {
      name                = "daily"
      target_backup_vault = "primary"
      retention_duration  = "P30D"  # 30日間の保持期間
    }
  }
}

variable "backup_instance_blob" {
  description = "Blob Storageのバックアップインスタンス設定"
  type = map(object({
    name                 = string
    target_backup_vault  = string
    target_backup_policy = string
    storage_account_id   = string
  }))
  default = {}
}
```

## パラメータ

### backup_vault

| パラメータ | 型 | 必須 | 説明 |
|----------|------|------|------|
| name | string | Yes | バックアップコンテナーの名前 |
| datastore_type | string | Yes | データストアタイプ（通常は "VaultStore"） |
| redundancy | string | Yes | 冗長性オプション（LocallyRedundant, GeoRedundant, ZoneRedundant） |

### backup_policy_blob

| パラメータ | 型 | 必須 | 説明 |
|----------|------|------|------|
| name | string | Yes | バックアップポリシーの名前 |
| target_backup_vault | string | Yes | 関連付けるバックアップコンテナーのキー |
| retention_duration | string | Yes | バックアップの保持期間（ISO 8601形式、例: P30D、P90D） |

### backup_instance_blob

| パラメータ | 型 | 必須 | 説明 |
|----------|------|------|------|
| name | string | Yes | バックアップインスタンスの名前 |
| target_backup_vault | string | Yes | 関連付けるバックアップコンテナーのキー |
| target_backup_policy | string | Yes | 関連付けるバックアップポリシーのキー |
| storage_account_id | string | Yes | バックアップ対象のストレージアカウントID |

## 保持期間の設定

保持期間はISO 8601形式で指定します：

- `P30D` - 30日間
- `P90D` - 90日間
- `P1Y` - 1年間

## 注意事項

1. **システム割り当てマネージドID**: バックアップコンテナーには自動的にシステム割り当てマネージドIDが設定されます
2. **ロール割り当て**: ストレージアカウントに対して "Storage Account Backup Contributor" ロールが自動的に割り当てられます
3. **依存関係**: バックアップインスタンスの作成前にロール割り当てが完了するように依存関係が設定されています
4. **対応するストレージ**: このモジュールはBlob Storageのバックアップのみをサポートしています

## Outputs

| Output | 説明 |
|--------|------|
| backup_vault | 作成されたバックアップコンテナーの詳細 |
| backup_policy_blob | 作成されたバックアップポリシーの詳細 |
| backup_instance_blob | 作成されたバックアップインスタンスの詳細 |

## 参考リンク

- [Azure Data Protection Backup Vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_vault)
- [Azure Backup Policy Blob Storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_policy_blob_storage)
- [Azure Backup Instance Blob Storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_instance_blob_storage)
