################################
# Network security group
################################

# var.network_security_rule から各 NSG のルール数を動的に計算
# これにより、ハードコードが不要になり、Terraform 定義と Azure 実際の状態を比較できる
locals {
  # 各 NSG に紐づくセキュリティルール数を var.network_security_rule から計算
  nsg_expected_rule_count = {
    for k in keys(var.network_security_group) :
    k => length([
      for v in var.network_security_rule :
      v if v.target_nsg == k
    ])
  }
}

# 各 NSG の実際の情報を Azure から取得
data "azurerm_network_security_group" "this" {
  for_each            = var.network_security_group
  name                = module.network_security_group.network_security_group[each.key].name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [module.network_security_group]
}

# NSG のセキュリティルール数を検証（Terraform 定義 vs Azure 実際の状態）
check "network_security_group_rule_count" {
  assert {
    condition = alltrue([
      for k, v in local.nsg_expected_rule_count :
      length(data.azurerm_network_security_group.this[k].security_rule) == v
    ])
    error_message = "NSG のルール数が Terraform 定義と Azure 実際の状態で一致しません（ドリフト検知）:\n${join("\n", [
      for k, v in local.nsg_expected_rule_count :
      "- ${k}: Terraform定義=${v}, Azure実際=${length(data.azurerm_network_security_group.this[k].security_rule)}"
      if length(data.azurerm_network_security_group.this[k].security_rule) != v
    ])}"
  }
}
