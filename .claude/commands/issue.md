---
allowed-tools: mcp__Azure*,mcp__Terraoform*
description: コンテキストに基づいて GitHub Issue を作成する
---

Issue テンプレートの形式に従って Issue を作成または更新します。
コンテキストが提供されていない場合は、必ずユーザーに入力を求めてください。

## オプション

| Option | Action                                       |
| ------ | -------------------------------------------- |
| (なし) | Issue を作成し、ブラウザで開く               |
| `-u`   | 既存の Issue の説明を更新し、ブラウザで開く  |

## 作業手順

### 共通手順（全オプション共通）

1. テンプレートが指定されていない場合は、`.github/ISSUE_TEMPLATE/*.md` の Issue テンプレートから適切なものを選択する

2. 提供されたコンテキストに基づいて Issue のタイトルと説明を生成する

3. Azure MCP/Terraform MCP を使用して以下の情報を取得し、説明と備考に追加する：

- 開発のベストプラクティス
- コード実装例
- azurerm リソースブロックのリファレンス
- ドキュメント URL（jp ロケールを優先）

4. Markdown 形式のドラフトをユーザーに提示し、確認を求める（y/n）

- title: コンテキストに基づいて生成したタイトル
- body: コンテキストに基づいて生成した説明
- assignees: 現在の作業ユーザー

### オプション別の手順

| Option | Command                                                                          |
| ------ | -------------------------------------------------------------------------------- |
| (なし) | `gh issue create --title <title> --body <body> --assignee @me`                   |
| `-u`   | `gh issue edit <number> --title <title> --body <body>`                           |

5. Issue の作成/更新後、ブラウザで開く：

```bash
gh issue view <number> --web
```

## 注意事項

- Issue のタイトルと説明は日本語で記述する
- 可能な限り jp ロケールの URL を提供する
- Markdown のテーブルや Mermaid 記法を活用して視覚的にわかりやすくする
- `-u` オプション使用時、Issue 番号が指定されていない場合はユーザーに確認する
