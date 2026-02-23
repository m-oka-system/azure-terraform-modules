---
name: terraform-validate
description: "Terraform モジュールのバリデーションを実行します。「検証して」「validate」「lint」「trivy」「チェック」などのキーワードでトリガーされます。"
model: haiku
allowed-tools: Bash, Read, Glob, Grep
---

## 引数

引数を以下のように解釈してください:

- **第 1 引数**: 対象モジュール名（例: `storage`、`key_vault`）。省略時はプロジェクト全体を検証
- **`--fix`**: `terraform fmt` を適用してフォーマットを自動修正する

## コンテキスト収集

以下のコマンドを **1 回の Bash 呼び出し** で実行して現在の状態を把握してください。並列 Bash 呼び出しは 1 つの失敗で他が連鎖エラーになるため、必ず単一コマンドとして実行します:

```bash
echo "=== 既存モジュール一覧 ===" && ls modules/ 2>/dev/null || echo "(なし)"; \
echo "=== 環境ディレクトリ ===" && ls envs/ 2>/dev/null || echo "(なし)"
```

## 制約

- バリデーション以外の変更を加えないでください（`--fix` 指定時の `terraform fmt` を除く）
- Bash の用途は `terraform fmt`、`bash .claude/scripts/*`、`ls` に限定してください

## 実行手順

### 1. モジュール構造チェック（モジュール名が指定された場合）

`modules/<モジュール名>/` ディレクトリの構造が 3 ファイルパターンに準拠しているか確認します。

詳細なチェック項目は `references/validation-checklist.md` を Read ツールで読み込んでください。

### 2. コードスタイルチェック（モジュール名が指定された場合）

`modules/<モジュール名>/` の各ファイルを読み込み、以下を確認します:

- `variables.tf`: 変数が最小宣言（`variable "xxx" {}`）のみであること
- `<モジュール名>.tf`: リソースラベルが `this` であること、`for_each` を使用していること、セクション区切りに `################################` を使用していること
- `outputs.tf`: output がリソースオブジェクト全体を返していること（`value = azurerm_xxx.this` の形式）

詳細なチェック項目は `references/validation-checklist.md` を Read ツールで読み込んでください。

### 3. terraform fmt

```bash
# --fix が指定された場合
terraform fmt -recursive modules/<モジュール名>/

# --fix が指定されていない場合（チェックのみ）
terraform fmt -check -recursive modules/<モジュール名>/
```

モジュール名が省略された場合はプロジェクトルートに対して実行します。

### 4. バリデーションスクリプトの実行

バリデーションスクリプトで terraform validate、tflint、trivy を一括実行します:

```bash
bash .claude/scripts/test-validation-hook.sh
```

このスクリプトは以下の検証を行います:

- `terraform validate`（各環境ディレクトリ）
- `tflint`（各環境ディレクトリ）
- `trivy config`（CRITICAL、HIGH のみ）

### 5. 結果サマリー

バリデーション結果を以下のテーブル形式で表示します:

```
| チェック項目 | 結果 | 詳細 |
|---|---|---|
| モジュール構造 | ✅ / ❌ | 3 ファイルパターン準拠 |
| コードスタイル | ✅ / ❌ | 変数宣言・ラベル・for_each |
| terraform fmt | ✅ / ❌ | フォーマットチェック |
| バリデーション | ✅ / ❌ | validate + tflint + trivy |
```

### 6. エラー時の修正提案

エラーが検出された場合は、各項目について具体的な修正方法を提示してください:

- **構造エラー**: 不足ファイルの作成手順、禁止ファイルの統合先
- **スタイルエラー**: 該当行と修正後の例
- **fmt エラー**: `--fix` オプションの再実行を提案
- **スクリプトエラー**: スクリプト出力のエラーメッセージを解析し、修正方法を提示
