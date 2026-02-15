---
name: terraform-implement
description: "リサーチ結果に基づいて Terraform コードを実装します。Child Module と Root Module（envs/dev/）の両方を網羅的に実装します。「実装して」「implement」「モジュール作成」「モジュールを作って」などのキーワードでトリガーされます。"
model: opus
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

## 前提条件

実装を開始する前に、以下のファイルを Read ツールで読み込んでください:

- `.claude/rules/terraform.md` - 開発ガイドライン
- `docs/TF_STYLE_GUIDE.md` - スタイルガイド

## 引数

引数を以下のように解釈してください:

- **第 1 引数**（必須）: モジュール名（例: `event_grid`、`redis`）

モジュール名が指定されていない場合は、処理を中断し「モジュール名を指定してください」と通知してください。

## コンテキスト収集

以下のコマンドを **1 回の Bash 呼び出し** で実行して現在の状態を把握してください。並列 Bash 呼び出しは 1 つの失敗で他が連鎖エラーになるため、必ず単一コマンドとして実行します:

```bash
echo "=== 既存モジュール一覧 ===" && ls modules/ 2>/dev/null || echo "(なし)"; \
echo "=== 既存リサーチファイル ===" && ls docs/research/ 2>/dev/null || echo "(なし)"
```

## 制約

- Terraform コード実装以外の作業を行わないでください
- Bash の用途は `ls`、`terraform fmt` に限定してください

## 実行手順

### 1. リサーチファイルの読み込み

`docs/research/` から対象サービスのリサーチファイル（`*_{モジュール名}.md`）を検索して読み込みます。

リサーチファイルが存在しない場合は、処理を中断し「リサーチファイルが見つかりません。先に `/terraform-research {モジュール名}` を実行してください」と通知してください。

### 2. 類似モジュールの特定と読み込み

既存モジュールの中から、構造が類似する 1-2 個のモジュールを特定し、3 ファイルすべてを読み込んでパターンの参考にします。

加えて、`envs/dev/` の以下のファイルも読み込み、既存パターンを把握します:

- `envs/dev/main.tf` - 既存の module ブロック一覧
- `envs/dev/variables.tf` - 既存の変数宣言パターン
- `envs/dev/locals.tf` - 既存の locals パターン
- `envs/dev/terraform.tfvars` - 既存の変数値パターン

類似性の判断基準:

- 同じカテゴリの Azure サービス（例: Database 系なら `mssql_server`、Compute 系なら `app_service`）
- 類似のリソース構成（dynamic ブロック、ネットワーク統合パターン等）

### 3. Child Module 実装

`modules/<モジュール名>/` ディレクトリに 3 ファイルを作成します。

各ファイルの詳細なテンプレートとルールは `references/module-patterns.md` を Read ツールで読み込んでください。

概要:

- **`variables.tf`**: 最小宣言のみ（`variable "xxx" {}`）、規約に従った並び順
- **`<モジュール名>.tf`**: リソース定義（ラベル `this`、`for_each`、`################################` 区切り、日本語セキュリティコメント）
- **`outputs.tf`**: リソース全体出力（`value = azurerm_xxx.this`）

### 4. Root Module 実装（envs/dev/）

Child Module を環境から呼び出すために、以下のファイルを更新します。

各ファイルの詳細なテンプレートとルールは `references/module-patterns.md` の「Root Module パターン」セクションを参照してください。

#### 4a. `envs/dev/main.tf` に module ブロックを追加

- 既存の module ブロックの末尾に追加する
- `resource_enabled` で作成有無を制御する場合は `count` を使用する
- 引数の並び順は Child Module の `variables.tf` と一致させる

#### 4b. `envs/dev/variables.tf` に変数の完全宣言を追加

- `description`（日本語）、`type`（完全な型定義）、`default` を記述する
- 変数型は Child Module で使用する属性をすべて含める
- `optional()` を活用してオプション属性にデフォルト値を設定する

#### 4c. `envs/dev/locals.tf` に locals を追加（必要な場合）

- プライベートエンドポイント定義、動的な値の生成など
- 不要な場合はスキップする

#### 4d. `envs/dev/terraform.tfvars` に変数値を追加

- 実際の設定値を記述する
- セキュリティのデフォルト値を適用する

#### 4e. `envs/dev/variables.tf` の `resource_enabled` に追加（必要な場合）

- `count` で作成有無を制御するモジュールの場合のみ

### 5. terraform fmt の適用

```bash
terraform fmt modules/<モジュール名>/
terraform fmt envs/dev/
```

### 6. セルフレビューチェックリスト

実装完了後、`references/self-review-checklist.md` を Read ツールで読み込み、チェックリストで自己検証してください。結果をテーブル形式で表示してください。

不合格の項目がある場合は、修正してからチェックリストを再表示してください。
