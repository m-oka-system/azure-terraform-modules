# =============================================================================
# Azure Network セキュリティポリシー
# =============================================================================
# このポリシーは、Azure ネットワークリソースのセキュリティベストプラクティスを検証します。
# 参考:
#   - https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview
#   - https://learn.microsoft.com/azure/security/fundamentals/network-best-practices
#
# 注: Terraform の必須項目（resource_group_name, direction, priority 等）は
#     terraform plan が通る時点で存在が保証されるため、テスト対象外としています。
# =============================================================================

@network @security
Feature: Azure Network Security
  Azure ネットワークリソースはセキュリティベストプラクティスに準拠する必要があります

  # ===========================================================================
  # Public IP
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # パブリック IP の管理
  # ---------------------------------------------------------------------------
  # なぜ: Standard SKU の Public IP は、より多くのセキュリティ機能を提供します
  # Basic SKU はセキュリティの観点から非推奨です
  @critical
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

  # なぜ: WAF_v2 SKU を使用することで、WAF 機能を利用できます
  Scenario: Application Gateway は WAF_v2 SKU を使用する
    Given I have azurerm_application_gateway defined
    Then it must contain sku
    And it must contain name
    And its value must match the "WAF_v2|Standard_v2" regex

  # ===========================================================================
  # Azure Front Door
  # ===========================================================================

  # なぜ: Premium SKU では WAF 機能が利用可能です
  Scenario: Front Door は適切な SKU を使用する
    Given I have azurerm_cdn_frontdoor_profile defined
    Then it must contain sku_name
    And its value must match the "Standard_AzureFrontDoor|Premium_AzureFrontDoor" regex
