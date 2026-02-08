# Refactoring Patterns Reference

## 変数定義パターン

### 共通変数 (default なし)

```hcl
variable "common" {
  description = "プロジェクト共通設定"
  type = object({
    project  = string
    env      = string
    location = string
  })
  nullable = false
}
```

### ランタイム値 (default なし)

```hcl
variable "resource_group_name" {
  description = "リソースグループ名"
  type        = string
  nullable    = false
}
```

### タグ変数

```hcl
variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
  nullable    = false
}
```

### 静的設定値 - シンプルな型

```hcl
variable "example_map" {
  description = "日本語の説明"
  type = map(object({
    name  = string
    value = string
  }))
  default = {
    item1 = { name = "item1", value = "val1" }
    item2 = { name = "item2", value = "val2" }
  }
  nullable = false
}
```

### 静的設定値 - optional() 活用

多くのエントリで共通の値を持つフィールドには `optional()` を使用:

```hcl
variable "subnet" {
  description = "サブネットの設定"
  type = map(object({
    name             = string
    target_vnet      = string
    address_prefixes = list(string)
    # 多くのエントリで false → optional(bool, false)
    default_outbound_access_enabled = optional(bool, false)
    # 多くのエントリで "Disabled" → optional(string, "Disabled")
    private_endpoint_network_policies = optional(string, "Disabled")
    # 多くのエントリで空リスト → optional(list(string), [])
    service_endpoints = optional(list(string), [])
    # null を許容する場合 → optional() のみ (default なし)
    service_delegation = optional(object({
      name    = string
      actions = list(string)
    }))
  }))
  default  = { ... }
  nullable = false
}
```

## default 値の最適化パターン

### Before (冗長)

```hcl
default = {
  bastion = {
    name                            = "AzureBastionSubnet"
    target_vnet                     = "hub"
    address_prefixes                = ["192.168.1.0/24"]
    default_outbound_access_enabled = false      # optional default と同じ → 不要
    private_endpoint_network_policies = "Disabled"  # optional default と同じ → 不要
  }
}
```

### After (最適化済み)

```hcl
default = {
  bastion = {
    name             = "AzureBastionSubnet"
    target_vnet      = "hub"
    address_prefixes = ["192.168.1.0/24"]
    # optional default と異なる値のみ明示
  }
  pe = {
    name                              = "pe"
    target_vnet                       = "spoke1"
    address_prefixes                  = ["10.10.0.0/24"]
    private_endpoint_network_policies = "Enabled"  # default("Disabled") と異なる → 残す
  }
}
```

## lookup() 簡素化パターン

### Before

```hcl
resource "azurerm_subnet" "this" {
  default_outbound_access_enabled   = lookup(each.value, "default_outbound_access_enabled", false)
  private_endpoint_network_policies = lookup(each.value, "private_endpoint_network_policies", "Disabled")
  service_endpoints                 = lookup(each.value, "service_endpoints", [])
}
```

### After

```hcl
resource "azurerm_subnet" "this" {
  default_outbound_access_enabled   = each.value.default_outbound_access_enabled
  private_endpoint_network_policies = each.value.private_endpoint_network_policies
  service_endpoints                 = each.value.service_endpoints
}
```

`optional()` が型レベルで default を保証するため、`lookup()` の第3引数が不要になる。

## dynamic ブロックのパターン

null 許容の optional フィールドに対する dynamic ブロック:

```hcl
dynamic "delegation" {
  for_each = each.value.service_delegation != null ? [each.value.service_delegation] : []
  content {
    name = "delegation"
    service_delegation {
      name    = delegation.value.name
      actions = delegation.value.actions
    }
  }
}
```

## output 定義パターン

```hcl
output "resource_name" {
  description = "リソースの日本語説明"
  value       = azurerm_xxx.this
}
```

## root module 変更パターン

### module call - Before

```hcl
module "vnet" {
  source              = "../../modules/vnet"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  vnet                = var.vnet       # 静的設定値 → 削除対象
  subnet              = var.subnet     # 静的設定値 → 削除対象
}
```

### module call - After

```hcl
module "vnet" {
  source              = "../../modules/vnet"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
}
```

## 変数分類の判定フロー

```
変数名が common / resource_enabled ?
  → YES: root に残す (共通変数)
  → NO: ↓

root main.tf で resource 出力を渡している？
  (例: azurerm_resource_group.rg.name, module.xxx.yyy)
  → YES: root から渡し続ける (ランタイム値)
  → NO: ↓

root variables.tf に default 値がある？
  → YES: child module に default を移行 (静的設定値)
  → NO: child module に default なしで定義
```
