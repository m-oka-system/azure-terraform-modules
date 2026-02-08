---
paths:
  - "**/*.tf"
---

# Terraform 開発ガイドライン

## コーディング規約

- @docs/TF_STYLE_GUIDE.md に従うこと

## 重要な注意事項

- Child Module で `main.tf`・`data.tf`・`locals.tf` を作成しない。リソース・data source・locals はすべて `<module_name>.tf` に含める
- Child Module の変数は最小宣言にする（`variable "xxx" {}`）。型・説明・デフォルト値を定義しない
- Child Module の output はリソースオブジェクト全体を返す。個別属性（`xxx_id` 等）の output は作成しない
- 原則、ループ処理目的では `count` を使用しない。map / set 型の変数を `for_each` で使用する

## 実装前のリサーチ

- 実装する前に Terraform MCP でプロバイダーのドキュメントを確認すること
- Azure 固有の設計判断には Azure MCP のベストプラクティスを参照すること
- 新規モジュール作成時は、既存の類似モジュール（`modules/` 配下）をパターンの参考にすること
- 曖昧な点があれば `AskUserQuestion` ツールを使ってユーザーにヒアリングすること

## 変更後の検証

- `.tf` ファイルの変更後は `bash .claude/scripts/terraform-pre-commit-validation.sh` を実行すること
