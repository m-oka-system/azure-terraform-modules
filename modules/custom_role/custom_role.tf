################################
# Custom Role Definition
################################

# JSONファイルから権限設定を読み込む（各キーごとに1回だけ読み込む）
locals {
  permissions = {
    for key in keys(var.custom_role) : key => jsondecode(file("${path.module}/${key}.json"))
  }
}

resource "azurerm_role_definition" "this" {
  for_each = var.custom_role

  name        = each.value.name
  scope       = var.scope
  description = each.value.description

  # 読み込んだJSONファイルから権限設定を取得
  permissions {
    actions          = try(local.permissions[each.key].actions, [])
    not_actions      = try(local.permissions[each.key].not_actions, [])
    data_actions     = try(local.permissions[each.key].dataActions, [])
    not_data_actions = try(local.permissions[each.key].notDataActions, [])
  }

  # ロールの割り当て可能なスコープ
  assignable_scopes = var.assignable_scopes
}
