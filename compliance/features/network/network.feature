# =============================================================================
# Azure Network セキュリティポリシー
# =============================================================================
# このポリシーは、Azure ネットワークリソースのセキュリティベストプラクティスを検証します。
# 参考:
#   - https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview
#   - https://learn.microsoft.com/azure/security/fundamentals/network-best-practices
# =============================================================================

@network @security
Feature: Azure Network Security
  Azure ネットワークリソースはセキュリティベストプラクティスに準拠する必要があります

  # ===========================================================================
  # Network Security Group (NSG)
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # NSG 基本設定
  # ---------------------------------------------------------------------------
  # なぜ: NSG はリソースグループを設定する必要があります
  Scenario: NSG はリソースグループを設定する
    Given I have azurerm_network_security_group defined
    Then it must contain resource_group_name

  # なぜ: NSG ルールは direction（Inbound/Outbound）を設定する必要があります
  Scenario: NSG ルールは direction を設定する
    Given I have azurerm_network_security_rule defined
    Then it must contain direction

  # なぜ: NSG ルールは priority を設定してルールの優先順位を決める必要があります
  Scenario: NSG ルールは priority を設定する
    Given I have azurerm_network_security_rule defined
    Then it must contain priority

  # ===========================================================================
  # Virtual Network
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # VNet 設計
  # ---------------------------------------------------------------------------
  # なぜ: VNet は適切なアドレス空間を持つ必要があります
  Scenario: VNet はアドレス空間を設定する
    Given I have azurerm_virtual_network defined
    Then it must contain address_space

  # なぜ: サブネットを使用することで、ネットワークをセグメント化できます
  Scenario: VNet はサブネットを持つ
    Given I have azurerm_subnet defined
    Then it must contain address_prefixes

  # ===========================================================================
  # Public IP
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # パブリック IP の管理
  # ---------------------------------------------------------------------------
  # なぜ: Standard SKU の Public IP は、より多くのセキュリティ機能を提供します
  # Basic SKU はセキュリティの観点から非推奨です
  Scenario: Public IP は Standard SKU を使用する
    Given I have azurerm_public_ip defined
    Then it must contain sku
    And its value must be "Standard"

  # なぜ: Static 割り当ては予測可能で管理しやすいです
  Scenario: Public IP は Static 割り当てを使用する
    Given I have azurerm_public_ip defined
    Then it must contain allocation_method
    And its value must be "Static"

  # ===========================================================================
  # Application Gateway
  # ===========================================================================

  # なぜ: WAF を有効にすることで、Web アプリケーションを保護できます
  Scenario: Application Gateway は WAF を設定できる SKU を使用する
    Given I have azurerm_application_gateway defined
    Then it must contain sku

  # ===========================================================================
  # Azure Front Door
  # ===========================================================================

  # なぜ: Front Door を使用する場合、適切なプロファイルを設定する必要があります
  Scenario: Front Door はプロファイルを設定する
    Given I have azurerm_cdn_frontdoor_profile defined
    Then it must contain sku_name

  # ===========================================================================
  # Private Endpoint
  # ===========================================================================

  # なぜ: Private Endpoint を使用することで、Azure PaaS サービスへの
  # プライベートアクセスが可能になります
  Scenario: Private Endpoint はサブネットを指定する
    Given I have azurerm_private_endpoint defined
    Then it must contain subnet_id

  # なぜ: Private Service Connection を設定することで、
  # 対象リソースへの接続を確立します
  Scenario: Private Endpoint は Service Connection を設定する
    Given I have azurerm_private_endpoint defined
    Then it must contain private_service_connection
