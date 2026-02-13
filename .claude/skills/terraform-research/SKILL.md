---
name: terraform-research
description: "Azure サービスの調査を実行し docs/research/ に結果を保存します。「調査して」「リサーチ」「research」「〜を調べて」などのキーワードでトリガーされます。"
model: haiku
allowed-tools: Bash, Read, Write, Glob, Grep, Task, AskUserQuestion
---

## 引数

引数を以下のように解釈してください:

- **第 1 引数**（必須）: Azure サービス名（例: `event_grid`、`redis`、`cosmosdb`）

サービス名が指定されていない場合は、処理を中断し「サービス名を指定してください」と通知してください。

## コンテキスト収集

以下のコマンドを実行して現在の状態を把握してください:

```bash
ls docs/research/ 2>/dev/null || echo "(なし)"   # 既存リサーチファイル
ls modules/                                       # 既存モジュール一覧
date +%Y-%m-%d                                    # 現在日付
```

## 制約

- 調査とファイル保存以外の作業を行わないでください
- Bash の用途は `ls`、`date` に限定してください

## 実行手順

### 1. 既存リサーチの確認

`docs/research/` に対象サービスの過去の調査結果が存在するか確認します。`*_{サービス名}.md` にマッチするファイルがあれば、ユーザーに「既存の調査結果があります。上書きしますか？」と確認してください。

### 2. Task tool で 2 つの Agent を並列起動

以下の 2 つの Agent を **1 回のレスポンスで並列に** 起動してください。

**Agent 1: azure-researcher**

Task tool の `subagent_type` に `azure-researcher` を指定し、以下のプロンプトを送信します:

```
以下の Azure サービスについて調査してください。

サービス名: {サービス名}

調査完了後、結果をそのまま返してください。docs/research/ へのファイル保存は不要です。
```

**Agent 2: terraform-researcher**

Task tool の `subagent_type` に `terraform-researcher` を指定し、以下のプロンプトを送信します:

```
以下の Azure サービスに関する Terraform リソースを調査してください。

サービス名: {サービス名}
対象プロバイダー: azurerm（優先）、azapi（必要に応じて）

調査完了後、結果をそのまま返してください。docs/research/ へのファイル保存は不要です。
```

**重要**: Agent にはファイル保存を依頼しないでください。結果の統合とファイル保存はこのスキル側で行います。

### 3. 結果の統合と保存

両 Agent の結果を統合フォーマットにまとめ、`docs/research/YYYY-MM-DD_{サービス名}.md` に保存します。日付は現在日付を使用してください。

統合フォーマットは `references/research-output-template.md` を Read ツールで読み込んでください。

### 4. 完了通知

保存したファイルパスと、調査結果のサマリー（主要リソース数、必須セキュリティ設定数）を表示してください。
