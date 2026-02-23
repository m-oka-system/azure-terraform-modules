################################
# Backup Vault
################################
# 現在の日時を取得
resource "time_static" "current" {}

locals {
  # バックアップ開始日を取得
  backup_start_date = formatdate("YYYY-MM-DD", time_static.current.rfc3339)
  # バックアップ開始日を起点として、バックアップを繰り返す時間間隔を設定
  backup_repeating_time_intervals = ["R/${local.backup_start_date}T${var.backup_policy_blob_storage.backup_repeating_time_intervals.time}${var.backup_policy_blob_storage.backup_repeating_time_intervals.timezone}/${var.backup_policy_blob_storage.backup_repeating_time_intervals.interval}"]
}

# バックアップコンテナーを作成
resource "azurerm_data_protection_backup_vault" "this" {
  name                       = "bv-${var.common.project}-${var.common.env}"
  resource_group_name        = var.resource_group_name
  location                   = var.common.location
  datastore_type             = "VaultStore"
  redundancy                 = "LocallyRedundant"
  soft_delete                = "On"       # 論理削除
  retention_duration_in_days = 14         # 14日までは無料
  immutability               = "Disabled" # 不変コンテナー

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Blob Storage 用のバックアップポリシーを作成
resource "azurerm_data_protection_backup_policy_blob_storage" "this" {
  name                                   = "blob-policy-${var.common.project}-${var.common.env}"
  vault_id                               = azurerm_data_protection_backup_vault.this.id
  operational_default_retention_duration = var.backup_policy_blob_storage.operational_default_retention_duration
  vault_default_retention_duration       = var.backup_policy_blob_storage.vault_default_retention_duration
  time_zone                              = var.backup_policy_blob_storage.time_zone
  backup_repeating_time_intervals        = local.backup_repeating_time_intervals
}

# ストレージアカウントをバックアップするためのロールをバックアップコンテナーに対して割り当て
resource "azurerm_role_assignment" "backup_contributor" {
  scope                = var.storage_account.id
  role_definition_name = "Storage Account Backup Contributor"
  principal_id         = azurerm_data_protection_backup_vault.this.identity[0].principal_id
}

# ストレージアカウントのコンテナー一覧を取得
data "azurerm_storage_containers" "this" {
  storage_account_id = var.storage_account.id
}

# バックアップインスタンスとしてストレージアカウントを登録
resource "azurerm_data_protection_backup_instance_blob_storage" "this" {
  name                            = var.storage_account.name
  vault_id                        = azurerm_data_protection_backup_vault.this.id
  location                        = var.common.location
  storage_account_id              = var.storage_account.id
  backup_policy_id                = azurerm_data_protection_backup_policy_blob_storage.this.id
  storage_account_container_names = data.azurerm_storage_containers.this.containers[*].name

  depends_on = [
    azurerm_role_assignment.backup_contributor
  ]
}
