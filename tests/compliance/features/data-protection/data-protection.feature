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

  # なぜ: ルールが無効化されていると、ライフサイクルポリシーが機能しません
  Scenario: ライフサイクルルールは有効化されている
    Given I have azurerm_storage_management_policy defined
    Then it must contain rule
    And it must contain enabled
    And its value must be true

  # なぜ: base_blob アクションがないと、通常の Blob にポリシーが適用されません
  Scenario: ライフサイクルポリシーは base_blob アクションを設定する
    Given I have azurerm_storage_management_policy defined
    Then it must contain rule
    And it must contain actions
    And it must contain base_blob

  # なぜ: スナップショットの削除ポリシーがないと、古いスナップショットが蓄積し
  # ストレージコストが増大します
  Scenario: ライフサイクルポリシーはスナップショット削除を設定する
    Given I have azurerm_storage_management_policy defined
    Then it must contain rule
    And it must contain actions
    And it must contain snapshot
    And it must contain delete_after_days_since_creation_greater_than

  # なぜ: バージョンの削除ポリシーがないと、変更履歴が無制限に蓄積し
  # ストレージコストが増大します（versioning_enabled = true の場合）
  Scenario: ライフサイクルポリシーはバージョン削除を設定する
    Given I have azurerm_storage_management_policy defined
    Then it must contain rule
    And it must contain actions
    And it must contain version
    And it must contain delete_after_days_since_creation

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
  # なぜ: Continuous バックアップにより、任意の時点への復元が可能になります
  # Periodic は定期バックアップのみで、復元ポイントが限定されます
  @critical
  Scenario: Cosmos DB は Continuous バックアップを設定する
    Given I have azurerm_cosmosdb_account defined
    Then it must contain backup
    And it must contain type
    And its value must match the "Continuous" regex

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
  # 運用層とコンテナー層の両方で保持期間を設定することが推奨されます
  Scenario: Backup Policy は運用層の保持期間を設定する
    Given I have azurerm_data_protection_backup_policy_blob_storage defined
    Then it must contain operational_default_retention_duration

  Scenario: Backup Policy はコンテナー層の保持期間を設定する
    Given I have azurerm_data_protection_backup_policy_blob_storage defined
    Then it must contain vault_default_retention_duration

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
