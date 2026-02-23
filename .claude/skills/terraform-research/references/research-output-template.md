# リサーチ統合フォーマット

以下のテンプレートに従って、3 Agent（azure-researcher、terraform-researcher、context7-researcher）の調査結果を統合してください。

```markdown
# {サービス正式名称} 調査結果

> 調査日: YYYY-MM-DD
> プロバイダーバージョン: azurerm ~> {version} / azapi ~> {version}

## サービス概要

- サービス名: {正式名称}
- カテゴリ: {Compute / Networking / Storage / Database 等}
- ドキュメント URL: {https://learn.microsoft.com/ja-jp/ で始まる URL}

## 必須セキュリティ設定

| 属性名 | 推奨値 | 理由 |
|---|---|---|
| minimum_tls_version | "1.2" | TLS 1.0/1.1 は非推奨 |
| public_network_access_enabled | false | プライベートアクセスを推奨 |
| ... | ... | ... |

## Terraform リソース構成

### リソース一覧

| # | リソースタイプ | 用途 | プロバイダー |
|---|---|---|---|
| 1 | azurerm_{リソース} | {用途} | azurerm |
| ... | ... | ... | ... |

### データソース

| データソースタイプ | 用途 |
|---|---|
| azurerm_client_config | テナント・サブスクリプション情報 |
| ... | ... |

### 必須属性

{主要リソースごとに必須属性のテーブルを記載}

| 属性名 | 型 | 説明 |
|---|---|---|
| name | string | リソース名 |
| location | string | リージョン |
| resource_group_name | string | リソースグループ名 |
| ... | ... | ... |

### 推奨オプション属性

{主要リソースごとに推奨オプション属性のテーブルを記載}

| 属性名 | 型 | デフォルト値 | 推奨値 | 説明 |
|---|---|---|---|---|
| ... | ... | ... | ... | ... |

### ネストブロック

{主要リソースごとにネストブロックの一覧を記載}

| ブロック名 | 必須 | 主要属性 |
|---|---|---|
| ... | ... | ... |

## ネットワーク要件

- VNet 統合: {必要 / 不要 / 推奨}
- プライベートエンドポイント: {対応 / 非対応}
- サービスエンドポイント: {対応 / 非対応}

## プロジェクトパターンとの整合

- 命名規則: `{prefix}-${each.value.name}-${var.common.project}-${var.common.env}`
- 共通変数: `var.common`（project, env, location）
- ループ: `for_each` を使用（count は使わない）
- ID 管理: User Assigned Managed Identity を優先
- 命名制約: {ハイフン不可等の制約があれば記載}

## azapi 対応状況

| 項目 | 状態 |
|---|---|
| azurerm で対応済み | {Yes / No / 一部} |
| azapi が必要な機能 | {具体名、なければ「なし」} |
| 推奨 API バージョン | {例: 2024-01-01} |

### azapi 実装例

{azapi が必要な場合のみ記載。不要な場合はこのサブセクションを省略}

```hcl
resource "azapi_resource" "example" {
  type      = "{Azure リソースタイプ}@{API バージョン}"
  name      = "{リソース名}"
  parent_id = "{親リソース ID}"

  body = {
    properties = {
      # 具体的なプロパティ
    }
  }
}
```

## AVM 参考情報

- モジュール名: {AVM モジュール名、該当なしの場合は記載}
- リポジトリ: {GitHub URL}
- 主な特徴: {箇条書き}

### 参考構成

{AVM モジュールが存在する場合のみ記載。該当なしの場合はこのサブセクションを省略}

```hcl
module "example" {
  source  = "{モジュールソース}"
  version = "{バージョン}"
  # ...
}
```

## 注意事項・既知の制約

- {命名規則の制約}
- {リージョン制限}
- {SKU による機能差}
```
