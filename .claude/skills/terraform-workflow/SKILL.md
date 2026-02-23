---
name: terraform-workflow
description: "Terraform コード実装の全ワークフロー（リサーチ → 実装 → 検証）をオーケストレーションします。Child Module と Root Module（envs/dev/）を網羅的に実装します。「モジュールを作って」「ワークフロー」「workflow」「〜のモジュールを作成して」などのキーワードでトリガーされます。"
model: opus
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, AskUserQuestion
---

## 前提条件

ワークフローを開始する前に、以下のファイルを Read ツールで読み込んでください:

- `.claude/rules/terraform.md` - 開発ガイドライン
- `docs/TF_STYLE_GUIDE.md` - スタイルガイド

## 引数

引数を以下のように解釈してください:

| 引数                   | 説明                                                          | デフォルト |
| ---------------------- | ------------------------------------------------------------- | ---------- |
| 第 1 引数              | Azure サービス名（例: `event_grid`）                          | 必須       |
| `--skip-research`      | リサーチフェーズをスキップ                                    | false      |
| `--from <phase>`       | 指定フェーズから開始（`research` / `implement` / `validate`） | `research` |
| `--research-only`      | リサーチフェーズのみ実行                                      | false      |
| `--module-name <name>` | モジュール名の上書き（サービス名と異なる場合）                | サービス名 |

使用例:

```
/terraform-workflow event_grid                         # 全フェーズ実行
/terraform-workflow event_grid --skip-research         # リサーチをスキップ
/terraform-workflow event_grid --from implement        # 実装から開始
/terraform-workflow event_grid --from validate         # 検証のみ
/terraform-workflow event_grid --research-only         # リサーチのみ
/terraform-workflow event_grid --module-name eventgrid # モジュール名を上書き
```

サービス名が指定されていない場合は、処理を中断し「サービス名を指定してください」と通知してください。

## コンテキスト収集

以下のコマンドを **1 回の Bash 呼び出し** で実行して現在の状態を把握してください。並列 Bash 呼び出しは 1 つの失敗で他が連鎖エラーになるため、必ず単一コマンドとして実行します:

```bash
echo "=== 既存リサーチファイル ===" && ls docs/research/ 2>/dev/null || echo "(なし)"; \
echo "=== 既存モジュール一覧 ===" && ls modules/ 2>/dev/null || echo "(なし)"; \
echo "=== 現在日付 ===" && date +%Y-%m-%d; \
echo "=== Git 状態 ===" && git status --short
```

## 制約

- ワークフローの実行以外の作業を行わないでください
- オーケストレーターとして全ツールを使用できます

## 実行手順

### 0. 事前チェック

1. 引数を解析し、実行するフェーズを決定する
2. モジュール名を決定する（`--module-name` 指定があればそれを使用、なければサービス名）
3. 現在の状態を確認し、以下を表示する:

```
=== Terraform ワークフロー ===
サービス名:     {サービス名}
モジュール名:   {モジュール名}
リサーチ済み:   ✅ / ❌
実装済み:       ✅ / ❌

実行フェーズ:
  1. リサーチ   {実行 / スキップ}
  2. 実装       {実行 / スキップ}
  3. 検証       {実行 / スキップ}
```

### フェーズ 1-3 の詳細

各フェーズの詳細なロジックは `references/phase-specifications.md` を Read ツールで読み込んでください。

#### フェーズ 1: リサーチ

**スキップ条件**: `--skip-research`、`--from implement`、`--from validate` のいずれか

以下の 3 つの Agent を **1 回のレスポンスで並列に** Task tool で起動し、結果を統合して `docs/research/YYYY-MM-DD_{サービス名}.md` に保存します。

- azure-researcher
- terraform-researcher
- context7-researcher

**完了確認**: `docs/research/*_{サービス名}.md` が存在することを確認してから次へ進む。

#### フェーズ 2: 実装

**スキップ条件**: `--research-only`、`--from validate`

**前提条件**: リサーチファイルが存在すること

リサーチファイルと類似モジュールを参考に、以下を実装します:

1. **Child Module**: `modules/<モジュール名>/` に 3 ファイルを作成
2. **Root Module**: `envs/dev/` の関連ファイルを更新
   - `main.tf` に module ブロックを追加
   - `variables.tf` に変数の完全宣言を追加
   - `terraform.tfvars` に変数値を追加
   - `locals.tf` に locals を追加（必要な場合）
   - `variables.tf` の `resource_enabled` に追加（必要な場合）

**完了確認**: `modules/<モジュール名>/` に 3 ファイルが存在し、`envs/dev/main.tf` に module ブロックが追加されていることを確認してから次へ進む。

**実装途中で失敗した場合**:

- Child Module が不完全な場合: 作成済みファイルを削除し、`modules/<モジュール名>/` ディレクトリごと削除してからエラーを報告する
- Root Module 更新が不完全な場合: `git checkout envs/dev/` で変更を元に戻してからエラーを報告する
- エラー内容とどのステップで失敗したかをユーザーに明示する

#### フェーズ 3: 検証

**スキップ条件**: `--research-only`

**前提条件**: モジュールディレクトリが存在すること

構造チェック、スタイルチェック、terraform fmt、バリデーションスクリプトを実行します。

### 4. 完了サマリー

```
=== ワークフロー完了 ===

生成・更新ファイル:
  [リサーチ]
  - docs/research/YYYY-MM-DD_{サービス名}.md

  [Child Module]
  - modules/<モジュール名>/variables.tf
  - modules/<モジュール名>/<モジュール名>.tf
  - modules/<モジュール名>/outputs.tf

  [Root Module]
  - envs/dev/main.tf              (module ブロック追加)
  - envs/dev/variables.tf         (変数の完全宣言追加)
  - envs/dev/terraform.tfvars     (変数値追加)
  - envs/dev/locals.tf            (locals 追加 ※必要な場合)

検証結果: ✅ 全チェック通過 / ❌ {N} 件の問題あり

次のステップ:
  1. terraform plan で差分を確認
  2. /commit でコミット
  3. /pr で PR を作成
```

ワークフローの実行以外の作業を行わないでください。
