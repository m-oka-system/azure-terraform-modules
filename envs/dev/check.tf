################################
# Network security group
################################

# NSG ごとの期待するセキュリティルール数のマッピング
# 新しい NSG を追加する場合は、ここに期待するルール数を追加してください
locals {
  nsg_expected_rule_count = {
    bastion = 10 # Azure Bastion 用の必須ルール
    pe      = 4  # Private Endpoint 用
    app     = 4  # アプリケーション用
    func    = 3  # Azure Functions 用
    db      = 4  # データベース用
    vm      = 6  # 仮想マシン用
    appgw   = 5  # Application Gateway 用
    cae     = 0  # Container Apps Environment 用
    vm2     = 1  # 仮想マシン2 用 (未設定)
  }
}

# 各 NSG の実際の情報を取得
data "azurerm_network_security_group" "this" {
  for_each            = var.network_security_group
  name                = module.network_security_group.network_security_group[each.key].name
  resource_group_name = azurerm_resource_group.rg.name
}

# NSG のセキュリティルール数を検証
check "network_security_group_rule_count" {

  # すべての NSG のルール数が設定値と一致するかを一括チェック
  assert {
    condition = alltrue([
      for k, v in local.nsg_expected_rule_count :
      length(data.azurerm_network_security_group.this[k].security_rule) == v
    ])
    error_message = "NSG のルールの数が設定値と一致しません:\n${join("\n", [
      for k, v in local.nsg_expected_rule_count :
      "- ${k}: 設定値=${v}, 実際の値=${length(data.azurerm_network_security_group.this[k].security_rule)}"
      if length(data.azurerm_network_security_group.this[k].security_rule) != v
    ])}"
  }
}
