# Terraform スタイルガイド

本ドキュメントは、[HashiCorp 公式スタイルガイド](https://developer.hashicorp.com/terraform/language/style)をベースに、本リポジトリ固有のコーディング規約を統合した一元的なコーディング規約です。公式との相違点は各セクション内で `> **公式との相違点:**` として明示しています。

---

## 目次

- [用語集](#用語集)
- [1. コードフォーマット](#1-コードフォーマット)
- [2. ファイル構成](#2-ファイル構成)
- [3. 命名規約](#3-命名規約)
- [4. 変数定義](#4-変数定義)
- [5. リソース定義](#5-リソース定義)
- [6. 出力定義](#6-出力定義)
- [7. コメント規約](#7-コメント規約)
- [8. バージョン管理](#8-バージョン管理)
- [参考リンク](#参考リンク)

---

## 用語集

Terraform で使用される主要な用語を定義します。[Terraform 公式ドキュメント](https://developer.hashicorp.com/terraform/language)に基づいています。

| 用語                   | 説明                                                                                                                          |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Root Module            | `envs/dev/` 等の最上位ディレクトリ。`terraform plan/apply` の実行単位                                                         |
| Child Module           | `modules/` 配下の再利用可能なモジュール。`module` ブロックで呼び出す対象                                                      |
| Input Variables        | `variable` ブロックで宣言する値。外部からモジュールに渡すインターフェース                                                     |
| Local Values           | `locals` ブロックで定義する値。式に名前を割り当て、モジュール内で参照可能にする手段                                           |
| Root Module の output  | Root Module で定義する `output` ブロック。CLI への表示や `terraform_remote_state` 経由での参照に使用                          |
| Child Module の output | Child Module で定義する `output` ブロック。呼び出し元から `module.<NAME>.<OUTPUT>` で参照するモジュールの外部インターフェース |

---

## 1. コードフォーマット

HashiCorp 公式スタイルガイドに準拠したフォーマット規則です。

### 1.1 インデント

- インデントは **2 スペース** を使用します
- タブは使用しません

### 1.2 等号の位置揃え

同一ブロック内の `=` は位置を揃えます。

```hcl
# Good
resource_group_name = var.resource_group_name
location            = var.common.location
tags                = var.tags

# Bad
resource_group_name = var.resource_group_name
location = var.common.location
tags = var.tags
```

### 1.3 空行

- 最上位ブロック間（`resource`, `variable`, `output` 等）は空行で区切ります
- ネストされたブロック内では、論理グループ間に空行を入れます

### 1.4 フォーマッタ

VS Code（Cursor）に HashiCorp Terraform 拡張機能をインストールし、保存時に自動フォーマットを適用します。

```bash
code --install-extension "hashicorp.terraform"
```

`settings.json` に以下を追加します。

```jsonc
{
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true,
    "editor.formatOnSaveMode": "file",
  },
  "[terraform-vars]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true,
    "editor.formatOnSaveMode": "file",
  },
}
```

---

## 2. ファイル構成

### 2.1 モジュール構造（3 ファイルパターン）

すべての Child Module は以下の 3 ファイル構成に従います。

```
modules/<module_name>/
├── variables.tf          # 入力変数（型・説明なしの最小宣言）
├── <module_name>.tf      # リソース定義（data source、locals 含む）
└── outputs.tf            # 出力定義
```

> **公式との相違点:** 公式は `main.tf` を推奨していますが、本リポジトリではリソースファイルをモジュール名と一致させています（例: `vnet.tf`、`key_vault.tf`）。`locals.tf` や `data.tf` は分離しません。

### 2.2 環境構成（Root Module）

```
envs/<env_name>/
├── main.tf               # module ブロック（リソース定義）
├── terraform.tf          # required_providers、required_version
├── backend.tf            # backend 設定（リモートステート）
├── provider.tf           # provider 設定
├── variables.tf          # 入力変数（完全宣言: 型・説明・デフォルト値あり）
├── terraform.tfvars      # 変数値（機密情報、git 管理外）
├── locals.tf             # ローカル変数
└── outputs.tf            # 出力定義
```

### 2.3 変数宣言の二層構造

| レベル                    | 宣言方式                               | 例                                           |
| ------------------------- | -------------------------------------- | -------------------------------------------- |
| Child Module (`modules/`) | 最小宣言（型・説明・デフォルト値なし） | `variable "common" {}`                       |
| Root Module (`envs/`)     | 完全宣言（型・説明・デフォルト値あり） | `variable "common" { type = object({...}) }` |

**Child Module の変数宣言例:**

```hcl
# modules/storage/variables.tf
variable "common" {}
variable "resource_group_name" {}
variable "tags" {}
variable "random" {}
variable "storage" {}
variable "blob_container" {}
variable "allowed_cidr" {}
variable "storage_management_policy" {}
```

**Root Module の変数宣言例:**

```hcl
# envs/dev/variables.tf
variable "common" {
  description = "プロジェクト共通設定"
  type = object({
    project  = string
    env      = string
    location = string
  })
}
```

---

## 3. 命名規約

### 3.1 HCL コード内の命名

- **snake_case** を使用します: `resource_group_name`（`resourceGroupName` は不可）
- リソース型をラベルに含めません: `azurerm_virtual_network.this`（`azurerm_virtual_network.vnet_main` は不可）
- ラベルにはダブルクォートを使用します

### 3.2 Azure リソース命名規約（CAF 準拠）

パターン: `<プレフィックス>-<名前>-<プロジェクト>-<環境>[-<ランダムサフィックス>]`

Azure リソースのプレフィックスは以下の優先順位で決定します。

1. [Azure CAF リソース略称](https://learn.microsoft.com/ja-jp/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)に定義されているものはそれに従います
2. [azurecaf provider](https://registry.terraform.io/providers/aztfmod/azurecaf/latest/docs/resources/azurecaf_name) の slug に定義されているものはそれに従います
3. 上記に定義がない場合は、リソース種別が直感的にわかる短縮形を付けてください

**例:**

| リソース種別          | プレフィックス      | 例                         |
| --------------------- | ------------------- | -------------------------- |
| Virtual Network       | `vnet-`             | `vnet-hub-terraform-dev`   |
| Key Vault             | `kv-`               | `kv-app-terraform-dev`     |
| Storage Account       | `st` (ハイフン不可) | `stappterraformdev12345`   |
| App Service (Web App) | `webapp-`           | `webapp-api-terraform-dev` |
| Function App          | `func-`             | `func-app-terraform-dev`   |

### 3.3 命名制約のあるリソース

ストレージアカウントやコンテナーレジストリなど、ハイフンを使用できないリソースは `replace()` でハイフンを除去します。

```hcl
# Storage Account: 英小文字と数字のみ、3-24 文字
name = replace("st-${each.value.name}-${var.common.project}-${var.common.env}-${var.random}", "-", "")

# Container Registry: 英数字のみ、5-50 文字
name = replace("cr-${var.common.project}-${var.common.env}-${var.random}", "-", "")
```

### 3.4 `var.common` パターン

全モジュール共通で `var.common` を使用し、プロジェクト・環境・リージョン情報を伝播します。

```hcl
variable "common" {
  type = object({
    project  = string
    env      = string
    location = string
  })
}

# 使用例
name     = "webapp-${each.value.name}-${var.common.project}-${var.common.env}"
location = var.common.location
```

---

## 4. 変数定義

### 4.1 Root Module の変数定義

Root Module（`envs/`）の変数には以下を必須とします:

- `description`: 日本語で変数の説明を記述
- `type`: 型を明示
- `default`: 必要に応じてデフォルト値を設定

```hcl
variable "common" {
  description = "プロジェクト共通設定"
  type = object({
    project  = string
    env      = string
    location = string
  })
}

variable "resource_enabled" {
  description = "各リソースの作成有無を制御するフラグ"
  type = object({
    app_service    = bool
    function       = bool
    # ...
  })
}
```

### 4.2 バリデーション

変数に値の制約を追加したい場合は `validation` ブロックを追加します (任意)

```hcl
variable "env" {
  description = "環境名"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod"], var.env)
    error_message = "環境名は dev, stg, prod のいずれかを指定してください。"
  }
}
```

### 4.3 変数の並び順ルール

`main.tf` の `module` ブロック内の引数の並び順と、Child Module の `variables.tf` の変数宣言順は**一致させます**。

**共通の並び順テンプレート:**

| 順序 | カテゴリ                             | 例                                                     |
| ---- | ------------------------------------ | ------------------------------------------------------ |
| 1    | `common`（常に先頭）                 | `common = var.common`                                  |
| 2    | `resource_group_name`                | `resource_group_name = azurerm_resource_group.rg.name` |
| 3    | `tags`                               | `tags = azurerm_resource_group.rg.tags`                |
| 4    | `random`（必要な場合）               | `random = local.common.random`                         |
| 5    | 主リソース変数（モジュール名と同名） | `storage = var.storage`                                |
| 6    | 従属リソース変数                     | `blob_container = var.blob_container`                  |
| 7    | 他モジュールの output を渡す変数     | `subnet = module.vnet.subnet`                          |

**実例 - module ブロック（`main.tf`）と変数宣言（`variables.tf`）の対応:**

```hcl
# envs/dev/main.tf
module "application_insights" {
  source               = "../../modules/application_insights"
  common               = var.common                           # 1. common
  resource_group_name  = azurerm_resource_group.rg.name       # 2. resource_group_name
  tags                 = azurerm_resource_group.rg.tags       # 3. tags
  application_insights = var.application_insights             # 5. 主リソース変数
  log_analytics        = module.log_analytics.log_analytics   # 7. 他モジュール output
}
```

```hcl
# modules/application_insights/variables.tf（同一順序で宣言）
variable "common" {}
variable "resource_group_name" {}
variable "tags" {}
variable "application_insights" {}
variable "log_analytics" {}
```

---

## 5. リソース定義

### 5.1 リソースブロックの記述順序

リソースブロック内の引数は以下の順序で記述します。

| 順序 | カテゴリ                 | 説明                                                          |
| ---- | ------------------------ | ------------------------------------------------------------- |
| 1    | meta-argument            | `for_each` または `count`。ブロック先頭に配置します           |
| 2    | 通常の引数（非ブロック） | `name`、`location` 等のリソース固有パラメータ                 |
| 3    | ネストブロック           | `site_config`、`identity`、`dynamic` 等のリソース固有ブロック |
| 4    | `lifecycle` ブロック     | `ignore_changes` 等。必要な場合のみ記述します                 |
| 5    | `depends_on`             | 暗黙的な依存関係で不十分な場合のみ記述します                  |

各カテゴリの間には**空行を 1 行**入れて区切ります。同一カテゴリ内の引数は空行なしで連続させます。

```hcl
resource "azurerm_linux_web_app" "this" {
  # 1. meta-argument（先頭）
  for_each = var.app_service

  # 2. 通常の引数
  name                = "webapp-${each.value.name}-${var.common.project}-${var.common.env}"
  location            = var.common.location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan[each.value.target_service_plan].id

  # 3. ネストブロック（dynamic 含む）
  site_config {}

  dynamic "cors" {
    for_each = each.value.site_config.cors != null ? [true] : []

    content {
      allowed_origins = var.allowed_origins[each.key]
    }
  }

  # 4. lifecycle ブロック
  lifecycle {
    ignore_changes = [...]
  }

  # 5. depends_on（末尾）
  depends_on = [...]
}
```

### 5.2 `data` ソースの規約

`data` ソースはリソースファイル（`<module_name>.tf`）内に配置します。`data.tf` として分離しません。参照するリソースの直前に定義し、コードが上から下へ積み上がるように構成します。

```hcl
# modules/key_vault/key_vault.tf

# data ソースを先に定義
data "azurerm_client_config" "current" {}

# 参照するリソースを後に定義
resource "azurerm_key_vault" "this" {
  for_each  = var.key_vault
  tenant_id = data.azurerm_client_config.current.tenant_id
  # ...
}
```

### 5.3 `for_each` 専用ルール

本リポジトリでは、すべてのリソースで `for_each` を map で使用します。`count` は基本的に使用しません。

```hcl
# Good: for_each で map を使用
resource "azurerm_storage_account" "this" {
  for_each = var.storage
  name     = replace("st-${each.value.name}-${var.common.project}-${var.common.env}-${var.random}", "-", "")
  # ...
}

# Bad: count を使用
resource "azurerm_storage_account" "this" {
  count = length(var.storage)
  name  = var.storage[count.index].name
  # ...
}
```

> **公式との相違点:** 公式は `count` と `for_each` の使い分けを推奨していますが、本リポジトリでは `for_each` に統一しています。ただし、以下の場合に限り `count` を使用できます。
>
> - Root Module の `module` ブロックでリソース全体の作成有無を制御する場合
> - Child Module 内で条件により単一リソースの作成有無（0 or 1）を制御する場合

```hcl
# 例外1: module ブロックでの条件付き作成
module "bastion" {
  count = var.resource_enabled.bastion ? 1 : 0
  # ...
}

# 例外2: Child Module 内での条件付きリソース作成
resource "random_password" "admin_password" {
  count            = var.azuread_authentication_only ? 0 : 1
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
}
```

### 5.4 条件付きリソース作成

`for_each` を使用した条件付きリソース作成の例です:

```hcl
resource "azurerm_security_center_storage_defender" "this" {
  for_each           = { for k, v in var.storage : k => v if v.defender_for_storage_enabled }
  storage_account_id = azurerm_storage_account.this[each.key].id
}
```

### 5.5 `dynamic` ブロック

ネストブロックを動的に生成する場合に使用します。生成するブロック数に応じて `for_each` の渡し方が異なります。

| 生成パターン | ブロック数 | `for_each` の形式          | 用途                               |
| ------------ | ---------- | -------------------------- | ---------------------------------- |
| 条件付き生成 | 0 or 1     | `条件 ? [true] : []`       | オプショナルなブロックの有無を制御 |
| ループ生成   | 複数       | `toset(list)` または `map` | 同一ブロックを複数生成             |

#### 条件付き生成（0 or 1）

```hcl
dynamic "cors" {
  for_each = each.value.site_config.cors != null ? [true] : []

  content {
    allowed_origins     = var.allowed_origins[each.key]
    support_credentials = each.value.site_config.cors.support_credentials
  }
}
```

#### ループ生成（複数）

同一のネストブロックを複数生成する場合に使用します。`for_each` にリストや map を渡します。

```hcl
dynamic "ip_security_restriction" {
  for_each = toset(var.allowed_cidr)

  content {
    name             = each.value.ingress.ip_security_restriction.name
    ip_address_range = ip_security_restriction.value
    action           = "Allow"
  }
}
```

### 5.6 `target_*` プレフィックスパターン

リソースが別モジュールのリソースを参照する場合、参照先のキーを `target_*` プレフィックス付きの変数で指定します。

```hcl
# variables.tf での定義例
# subnet は vnet モジュールで作成されるが、どの vnet に属するかを target_vnet で指定する
variable "subnet" {
  type = map(object({
    name        = string
    target_vnet = string  # vnet モジュールの map キーを指定
    # ...
  }))
}
```

```hcl
# インプット変数での指定例
subnet = {
  app = {
    name        = "app"
    target_vnet = "spoke1"  # vnet["spoke1"] を参照
    # ...
  }
}
```

```hcl
# リソース定義での使用例
resource "azurerm_subnet" "this" {
  for_each             = var.subnet
  virtual_network_name = var.vnet[each.value.target_vnet].name
}
```

### 5.7 `"MyIP"` マジックストリングパターン

IP ホワイトリストの変数値に `"MyIP"` を指定すると、実行時に `var.allowed_cidr` へ置換されます。開発環境で動的な IP アドレスを許可リストに追加する用途で使用します。

```hcl
ip_rules = join(",", lookup(each.value.network_rules, "ip_rules", null)) == "MyIP"
  ? var.allowed_cidr
  : lookup(each.value.network_rules, "ip_rules", null)
```

### 5.8 ランダムサフィックスパターン

グローバルに一意な名前が必要なリソース（Storage Account、Redis Cache 等）には `var.random` を付与します。

```hcl
# Root Module で乱数を生成
resource "random_integer" "num" {
  min = 10000
  max = 99999
}

# locals 経由で Child Module に渡す
locals {
  common = {
    random = tostring(random_integer.num.result)
  }
}
```

### 5.9 `lifecycle` ブロック

Terraform 外で変更される属性は `lifecycle.ignore_changes` で無視します。

| 対象                       | 例                                       | 変更元                 |
| -------------------------- | ---------------------------------------- | ---------------------- |
| CI/CD デプロイ属性         | `docker_image_name`、`application_stack` | CI/CD パイプライン     |
| Azure 自動付与タグ         | `tags["hidden-link: /app-insights-*"]`   | Azure プラットフォーム |
| マネージドサービス管理属性 | `frontend_ip_configuration` 等           | AKS 等のコントローラー |

```hcl
lifecycle {
  ignore_changes = [
    # CI/CD デプロイ属性
    site_config[0].application_stack[0].docker_image_name,
    site_config[0].application_stack[0].docker_registry_url,
    # Azure 自動付与タグ
    tags["hidden-link: /app-insights-conn-string"],
    tags["hidden-link: /app-insights-instrumentation-key"],
    tags["hidden-link: /app-insights-resource-id"],
  ]
}
```

### 5.10 `moved` / `import` ブロック

リソースアドレスの変更や既存リソースの取り込みには `moved` / `import` ブロックを使用します。`terraform state mv` / `terraform import` コマンドは使用しません。

#### `moved` ブロック

リソースのリネームやモジュール間の移動に使用します。既存のリソースを破棄せずにアドレスを変更できます。

```hcl
# リソースのリネーム
moved {
  from = azurerm_virtual_network.main
  to   = azurerm_virtual_network.this
}

# モジュールのリネーム
moved {
  from = module.vnet
  to   = module.virtual_network
}

# モジュール内への移動
moved {
  from = azurerm_subnet.this
  to   = module.vnet.azurerm_subnet.this
}
```

- Root Module（`envs/<env_name>/moved.tf`）に記述します
- 適用完了後の削除は任意です（変更履歴として残すこともできます）
- `moved` ブロックの削除は破壊的変更となるため、削除する場合はすべての環境で適用済みであることを確認します

#### `import` ブロック

既存の Azure リソースを Terraform 管理下に取り込む場合に使用します。

```hcl
import {
  to = azurerm_resource_group.this["main"]
  id = "/subscriptions/xxx/resourceGroups/rg-main-terraform-dev"
}
```

- Root Module（`envs/<env_name>/import.tf`）に記述します
- `terraform plan` で差分がないことを確認してから `terraform apply` を実行します
- 適用完了後の削除は任意です（変更履歴として残すこともできます）

---

## 6. 出力定義

### 6.1 リソース全体出力

Child Module の出力は、個別属性ではなくリソースオブジェクト全体を出力します。呼び出し元で必要な属性を取得します。

```hcl
# Good: リソース全体を出力
output "storage_account" {
  value = azurerm_storage_account.this
}

# Bad: 個別属性を出力
output "storage_account_id" {
  value = azurerm_storage_account.this.id
}
output "storage_account_name" {
  value = azurerm_storage_account.this.name
}
```

### 6.2 出力の参照

呼び出し元では以下のようにアクセスします:

```hcl
module.storage.storage_account["app"].id
module.storage.storage_account["app"].name
module.storage.storage_account["app"].primary_connection_string
```

### 6.3 Root Module の出力

Root Module の `output` には `description` を記述します。

```hcl
output "resource_group_name" {
  description = "リソースグループ名"
  value       = azurerm_resource_group.rg.name
}
```

---

## 7. コメント規約

### 7.1 コメント構文

`#` を使用します。`//` や `/* */` は使用しません。

```hcl
# Good
# VNet 統合を経由してコンテナーイメージをプル

# Bad
// VNet 統合を経由してコンテナーイメージをプル
/* VNet 統合を経由してコンテナーイメージをプル */
```

### 7.2 セクション見出し

リソースファイル内のセクション見出しには `#` 記号の装飾行で囲んだコメントを使用します。

```hcl
################################
# Storage Account
################################
resource "azurerm_storage_account" "this" {
  # ...
}
```

### 7.3 コメント言語

- Azure 固有の設定には**日本語コメント**を付けます
- 設定の意味や意図を記録として残すためにコメントを付ける場合もあります (任意)

```hcl
ftp_publish_basic_authentication_enabled       = false # FTP 基本認証を無効化
webdeploy_publish_basic_authentication_enabled = false # SCM 基本認証を無効化
https_only                                     = true  # HTTPS のみ
vnet_image_pull_enabled                        = true  # VNet 統合を経由してコンテナーイメージをプル
```

---

## 8. バージョン管理

### 8.1 バージョン固定

`terraform.tf` で `required_providers` と `required_version` を明記します。

```hcl
terraform {
  required_version = "~> 1.13.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.50.0"
    }
  }
}
```

### 8.2 `.gitignore`

以下のファイルをバージョン管理から除外します。

```gitignore
# Terraform
.terraform/
*.tfstate
*.tfstate.*
crash.log
crash.*.log
tfplan.binary
tfplan.json
plan.out
plan.json
plan.log

# 変数ファイル（機密情報を含む）
*.tfvars
*.tfvars.json

# Override ファイル
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# CLI 設定ファイル
.terraformrc
terraform.rc
```

> **注意:** `.terraform.lock.hcl` はバージョン管理に**含めてください**。依存関係の再現性を保証するために必要です。

---

## 参考リンク

- [HashiCorp Terraform Style Guide（公式）](https://developer.hashicorp.com/terraform/language/style)
- [Terraform Module Structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
- [Azure CAF リソース略称の推奨事項](https://learn.microsoft.com/ja-jp/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)
- [azurecaf provider](https://registry.terraform.io/providers/aztfmod/azurecaf/latest/docs/resources/azurecaf_name)
