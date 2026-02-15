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

以下のコマンドを **1 回の Bash 呼び出し** で実行して現在の状態を把握してください。並列 Bash 呼び出しは 1 つの失敗で他が連鎖エラーになるため、必ず単一コマンドとして実行します:

```bash
echo "=== 既存リサーチファイル ===" && ls docs/research/ 2>/dev/null || echo "(なし)"; \
echo "=== 既存モジュール一覧 ===" && ls modules/ 2>/dev/null || echo "(なし)"; \
echo "=== 現在日付 ===" && date +%Y-%m-%d
```

## 制約

- 調査とファイル保存以外の作業を行わないでください
- Bash の用途は `ls`、`date` に限定してください

## 実行手順

### 1. 既存リサーチの確認

`docs/research/` に対象サービスの過去の調査結果が存在するか確認します。`*_{サービス名}.md` にマッチするファイルがあれば、ユーザーに「既存の調査結果があります。上書きしますか？」と確認してください。

### 2. Task tool で 3 つの Agent を並列起動

以下の 3 つの Agent を **1 回のレスポンスで並列に** 起動してください。

**Agent 1: azure-researcher**

Task tool の `subagent_type` に `azure-researcher` を指定し、以下のプロンプトを送信します:

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

Task tool の `subagent_type` に `terraform-researcher` を指定し、以下のプロンプトを送信します:

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

Task tool の `subagent_type` に `context7-researcher` を指定し、以下のプロンプトを送信します:

```
以下の Azure サービスについて、Context7 を使用して補足情報を調査してください。

サービス名: {サービス名}

以下の 3 セクションを返してください:
- azapi 対応状況（azapi 実装例を含む）
- AVM 参考情報
- 注意事項（Context7 観点）

docs/research/ へのファイル保存は不要です。結果をそのまま返してください。
```

**重要**: Agent にはファイル保存を依頼しないでください。結果の統合とファイル保存はこのスキル側で行います。

### 3. 結果の統合と保存

3 Agent の結果を統合フォーマットにまとめ、`docs/research/YYYY-MM-DD_{サービス名}.md` に保存します。日付は現在日付を使用してください。

統合フォーマットは `references/research-output-template.md` を Read ツールで読み込んでください。

#### 統合ルール

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

### 4. 完了通知

保存したファイルパスと、調査結果のサマリー（主要リソース数、必須セキュリティ設定数）を表示してください。
