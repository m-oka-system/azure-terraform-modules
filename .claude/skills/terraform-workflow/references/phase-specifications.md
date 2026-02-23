# フェーズ仕様

## フェーズ 1: リサーチ

Agent プロンプトテンプレート、統合ルール、セクションマッピングは `.claude/skills/terraform-research/SKILL.md` の手順 2-3 と同一です。Read ツールで読み込んで実行してください。

以下はワークフロー固有の補足事項です:

### 既存リサーチの扱い

`docs/research/` に `*_{サービス名}.md` にマッチするファイルが存在する場合は、ユーザーに「既存の調査結果があります。上書きしますか？」と確認してください。

### 完了確認条件

- `docs/research/*_{サービス名}.md` が存在すること
- ファイルに「必須セキュリティ設定」セクションが含まれていること
- ファイルに「Terraform リソース構成」セクションが含まれていること

---

## フェーズ 2: 実装

実装パターンの詳細（Child Module の 3 ファイル構成、Root Module の更新手順、HCL テンプレート）は `.claude/skills/terraform-implement/references/module-patterns.md` を Read ツールで読み込んでください。

実装は **Child Module**（`modules/`）と **Root Module**（`envs/dev/`）の両方を対象とします。

### ステップ概要

1. **Child Module の 3 ファイル作成**: `variables.tf`、`<モジュール名>.tf`、`outputs.tf`
2. **Root Module の更新**: `envs/dev/` の `main.tf`、`variables.tf`、`terraform.tfvars`、必要に応じて `locals.tf`
3. **terraform fmt 適用**: Child Module と Root Module の両方に実行
4. **自己検証**: `.claude/skills/terraform-implement/references/self-review-checklist.md` の 18 項目チェックリストで確認

### terraform fmt 失敗時の対応

`terraform fmt` が非ゼロの終了コードを返した場合、生成したコードに構文エラーがあります。エラー出力を確認し、該当ファイルを修正してから再度 `terraform fmt` を実行してください。

---

## フェーズ 3: 検証

検証チェックリストの詳細は `.claude/skills/terraform-validate/references/validation-checklist.md` を Read ツールで読み込んでください。

### ステップ概要

1. **構造チェック**: 3 ファイルパターン（`variables.tf`、`<モジュール名>.tf`、`outputs.tf`）の準拠確認
2. **スタイルチェック**: 変数宣言・ラベル・for_each・セクション区切り・コメント
3. **terraform fmt**: `terraform fmt -check modules/<モジュール名>/`
4. **バリデーションスクリプト**: `bash .claude/scripts/test-validation-hook.sh`（validate + tflint + trivy 一括実行）

### 結果テーブル

```
| チェック項目 | 結果 | 詳細 |
|---|---|---|
| モジュール構造 | ✅ / ❌ | 3 ファイルパターン準拠 |
| コードスタイル | ✅ / ❌ | 変数宣言・ラベル・for_each |
| terraform fmt | ✅ / ❌ | フォーマットチェック |
| バリデーション | ✅ / ❌ | validate + tflint + trivy |
```
