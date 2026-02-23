# モジュール実装パターン

## variables.tf テンプレート

最小宣言のみで定義します。`type`、`description`、`default` は一切書きません。

```hcl
variable "common" {}

variable "resource_group_name" {}

variable "tags" {}

variable "<モジュール名>" {}
```

### 変数の並び順

| 順序 | カテゴリ                             | 例                                  |
| ---- | ------------------------------------ | ----------------------------------- |
| 1    | `common`（常に先頭）                 | `variable "common" {}`              |
| 2    | `resource_group_name`                | `variable "resource_group_name" {}` |
| 3    | `tags`                               | `variable "tags" {}`                |
| 4    | `random`（必要な場合）               | `variable "random" {}`              |
| 5    | 主リソース変数（モジュール名と同名） | `variable "storage" {}`             |
| 6    | 従属リソース変数                     | `variable "blob_container" {}`      |
| 7    | 他モジュールの output を渡す変数     | `variable "subnet" {}`              |

## `<モジュール名>.tf` テンプレート

### 基本構造

```hcl
################################
# {リソース表示名}
################################
resource "azurerm_{リソースタイプ}" "this" {
  for_each            = var.<モジュール名>
  name                = "<CAFプレフィックス>-${each.value.name}-${var.common.project}-${var.common.env}"
  location            = var.common.location
  resource_group_name = var.resource_group_name

  # セキュリティ設定
  minimum_tls_version = "1.2" # TLS 1.2 以上を強制

  tags = var.tags
}
```

### ルール

- **ファイル名**: モジュール名と一致させる（`main.tf` にしない）
- **data source**: ファイル先頭に配置する（`data.tf` を作らない）
- **locals**: このファイル内に配置する（`locals.tf` を作らない）
- **セクション区切り**: 主リソース（ファイル先頭）にのみ 3 行見出し（`################################`）を使用。サブリソースには見出しを付けない。補足が必要な場合のみ 1 行コメント
- **リソースラベル**: `this` を使用
- **ループ**: `for_each = var.<主リソース変数名>` を使用
- **命名規則**: `<CAFプレフィックス>-${each.value.name}-${var.common.project}-${var.common.env}`
  - ハイフン不可のリソース（Storage Account 等）は `replace()` で除去
- **コメント**: 属性名だけでは意図がわからない設定にのみ日本語コメントを付ける。属性名の言い換えに過ぎないコメントは書かない
- **tags**: `tags = var.tags` をリソースブロック末尾に配置

### dynamic ブロックパターン

#### 0 or 1（条件付き生成）

```hcl
dynamic "cors" {
  for_each = each.value.site_config.cors != null ? [true] : []

  content {
    allowed_origins = var.allowed_origins[each.key]
  }
}
```

#### 複数（ループ生成）

```hcl
dynamic "ip_security_restriction" {
  for_each = toset(var.allowed_cidr)

  content {
    ip_address_range = ip_security_restriction.value
    action           = "Allow"
  }
}
```

### リソースブロック内の引数の順序

| 順序 | カテゴリ       | 説明                                    |
| ---- | -------------- | --------------------------------------- |
| 1    | meta-argument  | `for_each`。ブロック先頭に配置          |
| 2    | 通常の引数     | `name`、`location` 等のパラメータ       |
| 3    | ネストブロック | `site_config`、`identity`、`dynamic` 等 |
| 4    | `lifecycle`    | `ignore_changes` 等。必要な場合のみ     |
| 5    | `depends_on`   | 暗黙的な依存関係で不十分な場合のみ      |

### 命名制約のあるリソース

ハイフンを使用できないリソースは `replace()` で除去します:

```hcl
# Storage Account: 英小文字と数字のみ
name = replace("st-${each.value.name}-${var.common.project}-${var.common.env}-${var.random}", "-", "")
```

## outputs.tf テンプレート

リソースオブジェクト全体を返します。個別属性の output は作成しません。

```hcl
output "<リソース論理名>" {
  value = azurerm_{リソースタイプ}.this
}
```

### ルール

- **output 名**: リソースの論理名（`azurerm_` プレフィックスを除いた名前）
- **value**: リソースオブジェクト全体（`azurerm_xxx.this`）
- 個別属性（`.id`、`.name` 等）の output は作成しない

---

# Root Module パターン（envs/dev/）

Child Module の作成後、Root Module から呼び出すためのコードを追加します。

## envs/dev/main.tf - module ブロック

### 常時作成するモジュール

```hcl
module "<モジュール名>" {
  source              = "../../modules/<モジュール名>"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  <モジュール名>      = var.<モジュール名>
  # 他モジュールの output を渡す変数
  subnet              = module.vnet.subnet
}
```

### resource_enabled で作成有無を制御するモジュール

```hcl
module "<モジュール名>" {
  count = var.resource_enabled.<モジュール名> ? 1 : 0

  source              = "../../modules/<モジュール名>"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  <モジュール名>      = var.<モジュール名>
}
```

### ルール

- 引数の並び順は Child Module の `variables.tf` の変数宣言順と一致させる
- `source` は `"../../modules/<モジュール名>"` の相対パスを使用する
- `common`、`resource_group_name`、`tags` は定型パターンで記述する
- 他モジュールの output を参照する場合は `module.<name>.<output>` を使用する
- `count` を使用する場合はブロック先頭に配置する（`count` と `for_each` は排他的なため同時に使用しない）

## envs/dev/variables.tf - 完全宣言

Child Module の変数に対応する完全な型宣言を追加します。

### 主リソース変数

```hcl
variable "<モジュール名>" {
  description = "{リソース名}の設定"
  type = map(object({
    name                = string
    # リソース固有の属性
    sku_name            = optional(string, "S0")
    public_network_access = optional(string, "Disabled")
    # ネストブロック用（null でオプション化）
    managed_network     = optional(object({
      isolation_mode = string
    }))
  }))
  default = {}
}
```

### ルール

- `description` は日本語で記述する
- `type` は Child Module で参照するすべての属性を含める
- `optional()` を使用してオプション属性にデフォルト値を設定する
- セキュリティ関連のデフォルト値は安全な値にする（例: `public_network_access = "Disabled"`）

### resource_enabled への追加

`count` で作成有無を制御するモジュールの場合のみ、`resource_enabled` 変数に追加します:

```hcl
variable "resource_enabled" {
  type = object({
    # ... 既存の項目 ...
    <モジュール名> = optional(bool, false)  # 追加
  })
}
```

## envs/dev/locals.tf - ローカル変数

プライベートエンドポイント定義や動的な値の生成が必要な場合に追加します。

```hcl
locals {
  # プライベートエンドポイント定義の追加例
  private_endpoint = merge(
    # ... 既存の定義 ...
    {
      for k, v in module.<モジュール名>.< output名> :
      "<prefix>_${k}" => {
        name                           = v.name
        subnet_id                      = module.vnet.subnet["pe"].id
        private_dns_zone_ids           = try([module.private_dns_zone[0].private_dns_zone["<zone>"].id], [])
        subresource_names              = ["<subresource>"]
        private_connection_resource_id = v.id
      }
    },
  )
}
```

## envs/dev/terraform.tfvars - 変数値

```hcl
<モジュール名> = {
  main = {
    name                  = "main"
    sku_name              = "S0"
    public_network_access = "Disabled"
  }
}
```

### ルール

- セキュリティのデフォルト値を適用する
- 開発環境用の適切な SKU を選択する
- 依存リソースのキー名（`target_*`）は既存リソースと整合させる
