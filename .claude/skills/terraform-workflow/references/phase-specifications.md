# フェーズ仕様

## フェーズ 1: リサーチ

### Agent プロンプトテンプレート

以下の 3 つの Agent を **1 回のレスポンスで並列に** Task tool で起動してください。

**Agent 1: azure-researcher**

Task tool の `subagent_type` に `azure-researcher` を指定:

```
以下の Azure サービスについて調査してください。

サービス名: {サービス名}

以下の 4 セクションを返してください:
- サービス概要
- 必須セキュリティ設定
- ネットワーク要件
- 注意事項（Azure 観点）

docs/research/ へのファイル保存は不要です。結果をそのまま返してください。
```

**Agent 2: terraform-researcher**

Task tool の `subagent_type` に `terraform-researcher` を指定:

```
以下の Azure サービスに関する Terraform リソースを調査してください。

サービス名: {サービス名}
対象プロバイダー: azurerm（優先）、azapi（必要に応じて）

以下の 3 セクションを返してください:
- プロバイダーバージョン
- Terraform リソース構成（リソース一覧、データソース、必須属性、推奨オプション属性、ネストブロック）
- プロジェクトパターンとの整合

docs/research/ へのファイル保存は不要です。結果をそのまま返してください。
```

**Agent 3: context7-researcher**

Task tool の `subagent_type` に `context7-researcher` を指定:

```
以下の Azure サービスについて、Context7 を使用して補足情報を調査してください。

サービス名: {サービス名}

以下の 3 セクションを返してください:
- azapi 対応状況（azapi 実装例を含む）
- AVM 参考情報
- 注意事項（Context7 観点）

docs/research/ へのファイル保存は不要です。結果をそのまま返してください。
```

**重要**: Agent にはファイル保存を依頼しないでください。結果の統合とファイル保存はワークフロー側で行います。

### 統合ルール

3 Agent の結果を統合して `docs/research/YYYY-MM-DD_{サービス名}.md` に保存します。

統合フォーマットは `.claude/skills/terraform-research/references/research-output-template.md` を Read ツールで読み込んでください。

セクション単位で各 Agent の結果をマッピングしてください:

| テンプレートのセクション | ソース |
|---|---|
| サービス概要 | azure-researcher |
| 必須セキュリティ設定 | azure-researcher |
| Terraform リソース構成 | terraform-researcher |
| ネットワーク要件 | azure-researcher |
| プロジェクトパターンとの整合 | terraform-researcher |
| azapi 対応状況 | context7-researcher |
| AVM 参考情報 | context7-researcher |
| 注意事項・既知の制約 | azure-researcher + context7-researcher を統合 |

- プロバイダーバージョン（terraform-researcher）はファイル先頭のメタ情報として調査日の下に記載します
- 「未取得」と報告されたセクションはそのまま「未取得」と記載してください
- 情報が競合する場合はより具体的な情報を優先してください

### 完了確認条件

- `docs/research/*_{サービス名}.md` が存在すること
- ファイルに「必須セキュリティ設定」セクションが含まれていること
- ファイルに「Terraform リソース構成」セクションが含まれていること

---

## フェーズ 2: 実装

実装は **Child Module**（`modules/`）と **Root Module**（`envs/dev/`）の両方を対象とします。

### ステップ 2a: Child Module の 3 ファイル作成

#### variables.tf

- 最小宣言のみ: `variable "xxx" {}`（型・説明・デフォルト値は一切書かない）
- 並び順: `common` → `resource_group_name` → `tags` → `random`（必要時） → 主リソース変数 → 従属リソース変数 → 外部依存変数

```hcl
variable "common" {}

variable "resource_group_name" {}

variable "tags" {}

variable "<モジュール名>" {}
```

#### `<モジュール名>.tf`

- ファイル名はモジュール名と一致（`main.tf` にしない）
- data source はファイル先頭に配置（`data.tf` を作らない）
- locals はこのファイル内に配置（`locals.tf` を作らない）
- セクション区切り: `################################`
- リソースラベル: `this`
- ループ: `for_each = var.<主リソース変数名>`
- 命名規則: `<CAFプレフィックス>-${each.value.name}-${var.common.project}-${var.common.env}`
  - ハイフン不可のリソースは `replace()` で除去
- セキュリティ設定には日本語コメント
- `tags = var.tags` をリソースブロック末尾に配置

```hcl
################################
# {リソース名}
################################
resource "azurerm_{リソースタイプ}" "this" {
  for_each            = var.<モジュール名>
  name                = "<prefix>-${each.value.name}-${var.common.project}-${var.common.env}"
  location            = var.common.location
  resource_group_name = var.resource_group_name

  # セキュリティ設定
  minimum_tls_version = "1.2" # TLS 1.2 以上を強制

  tags = var.tags
}
```

#### dynamic ブロックパターン

- 0 or 1: `for_each = 条件 != null ? [true] : []`
- 複数: `for_each = toset(list)` または `for_each = map`

#### outputs.tf

- リソースオブジェクト全体を返す（個別属性の output は作成しない）
- output 名はリソースの論理名

```hcl
output "<リソース論理名>" {
  value = azurerm_{リソースタイプ}.this
}
```

### ステップ 2b: Root Module の更新（envs/dev/）

Child Module を環境から呼び出すために、以下のファイルを更新します。既存のファイルを読み込み、末尾に追加する形で編集してください。

#### envs/dev/main.tf - module ブロックの追加

既存の module ブロック一覧の末尾に追加します。引数の並び順は Child Module の `variables.tf` と一致させます。

```hcl
# 常時作成するモジュール
module "<モジュール名>" {
  source              = "../../modules/<モジュール名>"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  <モジュール名>      = var.<モジュール名>
}

# resource_enabled で制御するモジュール
module "<モジュール名>" {
  count = var.resource_enabled.<モジュール名> ? 1 : 0

  source              = "../../modules/<モジュール名>"
  common              = var.common
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
  <モジュール名>      = var.<モジュール名>
}
```

#### envs/dev/variables.tf - 変数の完全宣言の追加

Child Module の変数に対応する完全な型宣言を追加します。

```hcl
variable "<モジュール名>" {
  description = "{リソース名}の設定"
  type = map(object({
    name                  = string
    sku_name              = optional(string, "S0")
    public_network_access = optional(string, "Disabled")
    # ネストブロック（null でオプション化）
    managed_network = optional(object({
      isolation_mode = string
    }))
  }))
  default = {}
}
```

- `description` は日本語で記述する
- `optional()` でオプション属性にデフォルト値を設定する
- セキュリティ関連のデフォルト値は安全側にする
- `resource_enabled` への追加が必要な場合は、`resource_enabled` 変数の `type` ブロックにも追加する

#### envs/dev/terraform.tfvars - 変数値の追加

```hcl
<モジュール名> = {
  main = {
    name                  = "main"
    sku_name              = "S0"
    public_network_access = "Disabled"
  }
}
```

#### envs/dev/locals.tf - locals の追加（必要な場合のみ）

プライベートエンドポイント定義や動的な値の生成が必要な場合に追加します。不要な場合はスキップしてください。

### ステップ 2c: terraform fmt 適用

```bash
terraform fmt modules/<モジュール名>/
terraform fmt envs/dev/
```

### 18 項目チェックリスト

`.claude/skills/terraform-implement/references/self-review-checklist.md` を Read ツールで読み込み、チェックリストで自己検証してください。

---

## フェーズ 3: 検証

### 構造チェック（6 項目）

| #   | チェック項目                 | 期待値       |
| --- | ---------------------------- | ------------ |
| 1   | `variables.tf` の存在        | 必須         |
| 2   | `<モジュール名>.tf` の存在   | 必須         |
| 3   | `outputs.tf` の存在          | 必須         |
| 4   | `main.tf` が存在しないこと   | 禁止ファイル |
| 5   | `data.tf` が存在しないこと   | 禁止ファイル |
| 6   | `locals.tf` が存在しないこと | 禁止ファイル |

### スタイルチェック

- `variables.tf`: 最小宣言のみ、並び順が規約に従っていること
- `<モジュール名>.tf`: ラベル `this`、`for_each`、セクション区切り、日本語コメント
- `outputs.tf`: リソース全体出力

### スクリプト実行手順

```bash
# フォーマットチェック
terraform fmt -check modules/<モジュール名>/

# バリデーションスクリプト（validate + tflint + trivy 一括実行）
bash .claude/scripts/test-validation-hook.sh
```

### 結果テーブル

```
| チェック項目 | 結果 | 詳細 |
|---|---|---|
| モジュール構造 | ✅ / ❌ | 3 ファイルパターン準拠 |
| コードスタイル | ✅ / ❌ | 変数宣言・ラベル・for_each |
| terraform fmt | ✅ / ❌ | フォーマットチェック |
| バリデーション | ✅ / ❌ | validate + tflint + trivy |
```
