---
name: refactor-module
description: >
  Terraform child module の変数定義を AVM (Azure Verified Modules) 標準に準拠させるリファクタリング。
  child module の variables.tf に type/description/nullable を追加し、
  default 値を root module から child module に移行する。
  Triggers: "refactor module", "AVM standard", "変数定義リファクタリング", "モジュールリファクタリング",
  "When explicitly invoked with /refactor-module (module_name).
  Arguments: 対象モジュール名 (e.g., "vnet", "storage", "key_vault")
---

# Refactor Module to AVM Standard

child module の変数定義を AVM 標準に準拠させるリファクタリングワークフロー。

## Arguments

対象モジュール名が引数として渡される。例: `/refactor-module vnet`

引数からモジュールパスを解決:

- child module: `modules/(module_name)/`
- root module: `envs/dev/`

## Workflow

### STEP 1: worktree 作成

`wtp` コマンドで独立した作業環境を作成:

```bash
wtp add -b feature/refactor-(module_name)-module
```

作成された worktree パスを記録し、以降のすべての作業は worktree 上で行う。

### STEP 2: 現状把握 - child module ファイル読み取り

worktree 上の対象 child module の全ファイルを読む:

1. `modules/(module_name)/variables.tf` - 現在の変数定義
2. `modules/(module_name)/outputs.tf` - 現在の出力定義
3. `modules/(module_name)/(module_name).tf` - リソース定義 (変数の使われ方を確認)

### STEP 3: 現状把握 - root module の関連箇所読み取り

worktree 上の root module から対象モジュールの情報を収集:

1. `envs/dev/main.tf` - module call ブロックから渡している引数を特定
2. `envs/dev/variables.tf` - 対応する variable 定義と default 値を特定

### STEP 4: 変数の分類

各変数を以下に分類:

| 分類             | 条件                                                       | 対応                                  |
| ---------------- | ---------------------------------------------------------- | ------------------------------------- |
| **共通変数**     | `common`, `resource_enabled`                               | root に残す (default なし)            |
| **ランタイム値** | resource 出力を参照 (例: `azurerm_resource_group.rg.name`) | root から渡し続ける (default なし)    |
| **静的設定値**   | root の variable に default がある                         | child module に default を移行        |
| **タグ**         | `tags`                                                     | child module に `default = {}` で定義 |

### STEP 5: child module variables.tf の更新

**重要: 変数の並び順は現状を維持する。アルファベット順にソートしない。**

各変数に以下を追加・更新:

- `description`: 日本語で説明を記述
- `type`: 適切な型定義
- `nullable = false`: 原則すべての変数に付与
- `default`: 静的設定値の場合、root module から移行

`optional()` の活用:

- `map(object({...}))` 型で、多くのエントリで同じ値を持つフィールドには `optional(type, default_value)` を使う
- 例: `default_outbound_access_enabled = optional(bool, false)`

詳細パターンは [references/patterns.md](references/patterns.md) を参照。

### STEP 6: default 値の最適化

`optional()` で default を設定したフィールドは、default 値内の各エントリから冗長な記述を削除:

- `optional(bool, false)` としたフィールド → default 内で `= false` の記述を削除
- `optional(string, "Disabled")` としたフィールド → default 内で `= "Disabled"` の記述を削除
- default と異なる値を持つエントリのみ明示的に記述を残す

### STEP 7: リソース定義の簡素化

`modules/(module_name)/(module_name).tf` で `lookup()` を直接アクセスに置換:

- Before: `lookup(each.value, "field_name", null)`
- After: `each.value.field_name`

`optional()` により型が保証されるため `lookup()` は不要になる。

### STEP 8: outputs.tf の更新

全 output に `description` を追加 (日本語):

```hcl
output "example" {
  description = "リソースの説明"
  value       = azurerm_xxx.this
}
```

### STEP 9: root module variables.tf から変数定義を削除

STEP 4 で「静的設定値」に分類した変数の定義を `envs/dev/variables.tf` から削除。

### STEP 10: root module main.tf から引数を削除

STEP 9 で削除した変数に対応する module call 引数を `envs/dev/main.tf` から削除。

残す引数: `common`, `resource_group_name`, `tags`, その他ランタイム値。

### STEP 11: バリデーション

worktree 上で以下を順に実行し、すべて成功することを確認:

```bash
cd envs/dev
terraform fmt -recursive ../..
terraform validate
tflint
trivy config . --severity HIGH,CRITICAL
```

### STEP 12: terraform plan で差分確認

worktree の `envs/dev/` に `terraform.tfvars` が存在しない場合、本体リポジトリからコピー:

```bash
cp /Volumes/Prograde/repo/azure-terraform-modules/envs/dev/terraform.tfvars (worktree_path)/envs/dev/terraform.tfvars
```

terraform init と plan を実行:

```bash
cd (worktree_path)/envs/dev
terraform init -reconfigure
terraform plan
```

対象モジュールに関連する差分が **ゼロ** であることを確認。
無関係なモジュールの差分は無視してよい。

### STEP 13: コミット

`/commit` スラッシュコマンドを使用してコミット。

コミットメッセージ形式:

```
refactor: (module_name) モジュールの変数定義を AVM 標準に準拠させる
```

### STEP 14: セルフレビュー

`/pr-review-toolkit:review-pr` スラッシュコマンドでセルフレビューを実行。

レビュー結果は worktree の `review/` ディレクトリ (git 管理外) に md ファイルとして保存:

```bash
mkdir -p (worktree_path)/review
# レビュー結果を review/review-(module_name).md に保存
```

`review/` は `.gitignore` に含まれているか確認し、含まれていなければ追加不要 (git 管理外のまま運用)。

### STEP 15: レビュー指摘の修正

STEP 14 のレビュー結果から **Critical** および **Important** の指摘を修正。

修正後、STEP 11 のバリデーションを再実行して問題がないことを確認。
修正があれば `/commit` で追加コミット。

### STEP 16: PR 作成

`/pr` スラッシュコマンドで PR を作成。
