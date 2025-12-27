# =============================================================================
# Azure データ保護ポリシー
# =============================================================================
# このポリシーは、Azure リソースのデータ保護設定を検証します。
# バックアップ、バージョニング、削除保護などを含みます。
# 参考:
#   - https://learn.microsoft.com/azure/storage/blobs/versioning-overview
#   - https://learn.microsoft.com/azure/backup/backup-overview
# =============================================================================

@data-protection @security
Feature: Azure Data Protection
  Azure リソースはデータ保護のベストプラクティスに準拠する必要があります

  # ===========================================================================
  # Storage Account データ保護
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 削除保持ポリシー
  # ---------------------------------------------------------------------------
  # なぜ: 削除保持ポリシーにより、誤削除したデータを一定期間復旧できます
  # Microsoft は最低 7 日間の保持を推奨しています
  @critical
  Scenario: Storage Account は Blob 削除保持ポリシーを設定する
    Given I have azurerm_storage_account defined
    Then it must contain blob_properties
    And it must contain delete_retention_policy

  # なぜ: コンテナレベルの削除保持も重要です
  @critical
  Scenario: Storage Account はコンテナ削除保持ポリシーを設定する
    Given I have azurerm_storage_account defined
    Then it must contain blob_properties
    And it must contain container_delete_retention_policy

  # ---------------------------------------------------------------------------
  # ライフサイクル管理
  # ---------------------------------------------------------------------------
  # なぜ: ライフサイクルポリシーにより、古いデータを自動的にアーカイブまたは削除し、
  # コストを最適化できます
  Scenario: Storage Management Policy はルールを設定する
    Given I have azurerm_storage_management_policy defined
    Then it must contain rule

  # ===========================================================================
  # Key Vault データ保護
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # ソフトデリート
  # ---------------------------------------------------------------------------
  # なぜ: ソフトデリートにより、誤削除したシークレット/キー/証明書を復旧できます
  # Azure では 7-90 日間の保持期間を設定できます
  @critical
  Scenario: Key Vault はソフトデリート保持期間を設定する
    Given I have azurerm_key_vault defined
    Then it must contain soft_delete_retention_days

  # なぜ: パージ保護を有効にすることで、保持期間中の完全削除を防止します
  # 注: dev 環境では無効にしていることがあるため、存在確認のみ行います
  Scenario: Key Vault はパージ保護設定を持つ
    Given I have azurerm_key_vault defined
    Then it must contain purge_protection_enabled

  # ===========================================================================
  # Database データ保護
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # Cosmos DB バックアップ
  # ---------------------------------------------------------------------------
  # なぜ: バックアップを設定することで、データ損失に備えることができます
  # Continuous または Periodic バックアップを選択できます
  @critical
  Scenario: Cosmos DB はバックアップを設定する
    Given I have azurerm_cosmosdb_account defined
    Then it must contain backup

  # ---------------------------------------------------------------------------
  # SQL Server 監査
  # ---------------------------------------------------------------------------
  # なぜ: 監査ログにより、データベースへのアクセスを追跡し、
  # セキュリティインシデントの調査に利用できます
  Scenario: SQL Server は監査ログを有効にする
    Given I have azurerm_mssql_server_extended_auditing_policy defined
    Then it must contain log_monitoring_enabled
    And its value must be true

  # なぜ: 監査ログの保持期間を設定することで、コンプライアンス要件を満たせます
  Scenario: SQL Server は監査ログ保持期間を設定する
    Given I have azurerm_mssql_server_extended_auditing_policy defined
    Then it must contain retention_in_days

  # ===========================================================================
  # Backup Vault
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # バックアップポリシー
  # ---------------------------------------------------------------------------
  # なぜ: バックアップポリシーを定義することで、自動バックアップが可能になります
  Scenario: Backup Policy は保持期間を設定する
    Given I have azurerm_data_protection_backup_policy_blob_storage defined
    Then it must contain retention_duration

  # ===========================================================================
  # 診断設定
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # ログの保存
  # ---------------------------------------------------------------------------
  # なぜ: 診断設定により、リソースのログを Log Analytics や Storage Account に
  # 送信し、監視やトラブルシューティングに利用できます
  Scenario: 診断設定は Log Analytics を設定する
    Given I have azurerm_monitor_diagnostic_setting defined
    Then it must contain log_analytics_workspace_id
