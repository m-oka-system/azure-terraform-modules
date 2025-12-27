# =============================================================================
# Azure Database セキュリティポリシー
# =============================================================================
# このポリシーは、Azure SQL および Cosmos DB のセキュリティベストプラクティスを検証します。
# 参考:
#   - https://learn.microsoft.com/azure/azure-sql/database/security-best-practice
#   - https://learn.microsoft.com/azure/cosmos-db/security
# =============================================================================

@database @security
Feature: Azure Database Security
  Azure データベースサービスはセキュリティベストプラクティスに準拠する必要があります

  # ===========================================================================
  # Azure SQL Server
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # TLS/暗号化
  # ---------------------------------------------------------------------------
  # なぜ: TLS 1.2 以上を使用することで、最新の暗号化プロトコルを利用できます
  @critical
  Scenario: SQL Server は最小 TLS バージョン 1.2 を使用する
    Given I have azurerm_mssql_server defined
    Then it must contain minimum_tls_version
    And its value must be "1.2"

  # ---------------------------------------------------------------------------
  # 認証
  # ---------------------------------------------------------------------------
  # なぜ: Azure AD 認証を使用することで、より安全な認証が可能になります
  @critical
  Scenario: SQL Server は Azure AD 管理者を設定する
    Given I have azurerm_mssql_server defined
    Then it must contain azuread_administrator

  # なぜ: Azure AD 認証のみを使用することで、SQL 認証の脆弱性を排除できます
  # 本番環境では推奨
  Scenario: SQL Server は Azure AD 認証のみを使用する（推奨）
    Given I have azurerm_mssql_server defined
    Then it must contain azuread_administrator
    And it must contain azuread_authentication_only

  # ---------------------------------------------------------------------------
  # 監査とセキュリティ
  # ---------------------------------------------------------------------------
  # なぜ: 監査ログを有効にすることで、不正アクセスの検出が可能になります
  Scenario: SQL Server は拡張監査ポリシーを設定する
    Given I have azurerm_mssql_server_extended_auditing_policy defined
    Then it must contain log_monitoring_enabled
    And its value must be true

  # なぜ: セキュリティアラートにより、脅威を早期に検出できます
  Scenario: SQL Server はセキュリティアラートポリシーを設定する
    Given I have azurerm_mssql_server_security_alert_policy defined
    Then it must contain state

  # ===========================================================================
  # Azure Cosmos DB
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # ネットワークセキュリティ
  # ---------------------------------------------------------------------------
  # なぜ: パブリックアクセスを制限することで、不正アクセスのリスクを低減します
  # 注: 開発環境では一時的に許可することがあります
  Scenario: Cosmos DB はパブリックネットワークアクセスを制限する
    Given I have azurerm_cosmosdb_account defined
    Then it must contain public_network_access_enabled

  # なぜ: IP フィルターにより、許可された IP からのみアクセスを許可します
  Scenario: Cosmos DB は IP フィルターを設定する
    Given I have azurerm_cosmosdb_account defined
    When it has public_network_access_enabled
    When its value is true
    Then it must contain ip_range_filter

  # ---------------------------------------------------------------------------
  # バックアップ
  # ---------------------------------------------------------------------------
  # なぜ: バックアップを設定することで、データ損失に備えることができます
  Scenario: Cosmos DB はバックアップを設定する
    Given I have azurerm_cosmosdb_account defined
    Then it must contain backup

  # ===========================================================================
  # Azure MySQL Flexible Server
  # ===========================================================================

  # なぜ: MySQL でもネットワークセキュリティは重要です
  # VNet 統合（delegated_subnet_id）を使用する場合はプライベート接続となる
  Scenario: MySQL は VNet 統合を使用する
    Given I have azurerm_mysql_flexible_server defined
    Then it must contain delegated_subnet_id
