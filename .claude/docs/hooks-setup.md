# Claude Code Hooks - Terraform Validation Setup

## 概要

このプロジェクトでは、Claude Code の hook 機能を使って、**git commit 前**に自動的に Terraform の検証を実行します。問題があればコミットをブロックし、クリーンな履歴を維持します。

## 構成ファイル

```
.claude/
├── settings.json                                # Hook 設定
├── scripts/
│   ├── terraform-pre-commit-validation.sh       # メイン検証スクリプト
│   └── test-validation-hook.sh                  # テストスクリプト
└── docs/
    └── hooks-setup.md                           # このドキュメント
```

## 検証パイプライン

commit **前**、以下が順次実行されます：

```
1. コードを変更
2. git commit を実行
   ↓
3. 🔍 Pre-commit hook が自動実行
   - terraform validate（各環境）
   - tflint（各環境）
   - trivy scan（CRITICAL,HIGH のみ）
   ↓
4a. ✅ 検証成功 → commit が作成される
4b. ❌ 検証失敗 → commit が中止される
   → 問題を修正して再度 commit
```

**重要**: 問題のあるコードは commit されません。履歴が常にクリーンに保たれます。

### 1. Terraform Validate ✅
- **目的**: Terraform 構文とリソース設定の検証
- **コマンド**: `terraform validate`
- **初期化**: 必要に応じて `terraform init -backend=false` を実行
- **環境**: `envs/` 配下の各環境ディレクトリで実行

### 2. TFLint ✅
- **目的**: ベストプラクティスと Azure 固有のルールチェック
- **コマンド**: `tflint --format compact`
- **設定**: 環境固有の `.tflint.hcl` またはプロジェクトルート
- **初期化**: 必要に応じて `tflint --init` を実行
- **環境**: `envs/` 配下の各環境ディレクトリで実行

### 3. Trivy Config Scan ✅
- **目的**: セキュリティ脆弱性とミスコンフィギュレーション検出
- **コマンド**: `trivy config . --severity CRITICAL,HIGH`
- **フィルタ**: CRITICAL と HIGH レベルの問題のみ
- **出力**: JSON → テーブル形式でレポート
- **環境**: `envs/` 配下の各環境ディレクトリで実行

## インストール

### 必要なツール

```bash
# macOS (Homebrew)
brew install terraform
brew install tflint
brew install trivy

# Linux (apt)
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

### TFLint プラグイン初期化

```bash
tflint --init
```

## 使用方法

### 自動実行
Claude Code が `git commit` を実行すると、自動的に検証が開始されます。検証が失敗すると、コミットはブロックされます。

### 手動テスト

```bash
# Hook をテスト
./.claude/scripts/test-validation-hook.sh

# 個別のツールをテスト（各環境ディレクトリで）
cd envs/dev/
terraform validate
tflint
trivy config . --severity CRITICAL,HIGH
```

### 検証スキップ

緊急時や意図的にスキップする場合：

```bash
git commit -m "message" --no-verify
```

⚠️ **警告**: これは緊急時のみ使用してください。通常は検証を通過させることが強く推奨されます。

## エラー処理

### Exit Code
- **0**: すべての検証が成功 → コミット許可
- **2**: ブロッキングエラー → コミット中止
- **その他**: 非ブロッキングエラー → コミット許可

### エラー発生時の動作
1. エラーメッセージを stderr に出力
2. 問題箇所の詳細を表示
3. コミットをブロック
4. 修正を促すメッセージを表示

### 例：検証失敗時の出力

```
🔍 Pre-commit validation triggered

═══════════════════════════════════════════════════════
  Terraform Validation Pipeline
  Environments: dev
═══════════════════════════════════════════════════════

━━━ Environment: dev ━━━

  [1/3] Running terraform validate in dev...
  ✗ Terraform validate failed in dev

Error: Missing required argument
  on main.tf line 15:
  resource "azurerm_storage_account" "example" {
    The argument "location" is required.

═══════════════════════════════════════════════════════
❌ Validation failed - review issues above

💡 Tip: Fix the issues and commit again, or use --no-verify to skip validation
```

## カスタマイズ

### 環境固有の TFLint 設定

各環境で異なるルールを適用できます：

```
envs/
├── dev/.tflint.hcl      # dev 環境（緩め）
├── stg/.tflint.hcl      # stg 環境
└── prod/.tflint.hcl     # prod 環境（厳格）
```

環境固有の設定がない場合は、プロジェクトルートの `.tflint.hcl` を使用します。

#### dev 環境の例（緩め）
```hcl
# envs/dev/.tflint.hcl
rule "azurerm_resource_missing_tags" {
  enabled = false  # dev では必須タグをチェックしない
}
```

#### prod 環境の例（厳格）
```hcl
# envs/prod/.tflint.hcl
rule "azurerm_resource_missing_tags" {
  enabled = true
  tags = [
    "Environment",
    "ManagedBy",
    "Project",
    "CostCenter",  # prod のみ必須
    "Owner"        # prod のみ必須
  ]
}
```

### Trivy の重要度フィルタ

デフォルトでは `CRITICAL,HIGH` のみをチェックします。変更する場合はスクリプトを編集：

```bash
# .claude/scripts/terraform-pre-commit-validation.sh
trivy config . --severity CRITICAL,HIGH,MEDIUM  # MEDIUM を追加
```

### Hook の無効化

`.claude/settings.json` から該当の hook を削除：

```json
{
  "hooks": {
    "PreToolUse": []
  }
}
```

### 追加の検証ツール例

#### terraform fmt（自動フォーマット）
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "command": "bash .claude/scripts/terraform-pre-commit-validation.sh",
        "description": "Run Terraform validation before git commits"
      },
      {
        "matcher": "Edit|Write",
        "command": "if [[ \"$CLAUDE_TOOL_INPUT\" == *.tf ]]; then terraform fmt \"$CLAUDE_PROJECT_DIR\"; fi",
        "description": "Auto-format Terraform files on edit"
      }
    ]
  }
}
```

## トラブルシューティング

### Hook が実行されない
1. `.claude/settings.json` が存在するか確認
2. スクリプトに実行権限があるか確認: `chmod +x .claude/scripts/*.sh`
3. hook のマッチャーが正しいか確認（`Bash` for git commit）

### ツールが見つからない
```bash
# PATH を確認
echo $PATH

# ツールのバージョン確認
terraform version
tflint --version
trivy --version

# 再インストール
brew install terraform tflint trivy
```

### 改行コードエラー
```bash
# Unix 形式に変換
sed -i '' 's/\r$//' .claude/scripts/*.sh
```

### TFLint 初期化エラー
```bash
# 各環境で初期化
cd envs/dev/
tflint --init

cd ../stg/
tflint --init

cd ../prod/
tflint --init
```

### 検証が遅い

**オプション 1**: 高速な検証のみ実行
- terraform validate と tflint のみ
- trivy は CI/CD で実行

**オプション 2**: Pre-push に移動
- Commit は高速に
- Push 前に詳細検証

## 環境検出の仕組み

スクリプトは `envs/` ディレクトリ配下のサブディレクトリを自動検出します：

```bash
# スクリプト内の実装
ENV_DIRS=($(find "$ENVS_DIR" -mindepth 1 -maxdepth 1 -type d | sort))

# 各環境で検証を実行
for ENV_DIR in "${ENV_DIRS[@]}"; do
  ENV_NAME=$(basename "$ENV_DIR")
  echo "━━━ Environment: $ENV_NAME ━━━"

  cd "$ENV_DIR"
  terraform validate
  tflint
  trivy config . --severity CRITICAL,HIGH
  cd "$PROJECT_DIR"
done
```

この仕組みにより、新しい環境（例: `envs/qa/`）を追加しても、自動的に検証対象になります。

## 参考リンク

- [Claude Code Hooks Documentation](https://code.claude.com/docs/en/hooks.md)
- [TFLint Documentation](https://github.com/terraform-linters/tflint)
- [Trivy Documentation](https://trivy.dev/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Git Hooks 詳細](../../.githooks/README.md)

## よくある質問

### Q: 検証が遅い場合は？
A: 以下を試してください：
- `.terraform` キャッシュの再利用
- Trivy のキャッシュ有効化: `export TRIVY_CACHE_DIR=~/.cache/trivy`
- 変更されたファイルのみを検証（スクリプトのカスタマイズが必要）

### Q: 特定のファイルだけ検証したい
A: スクリプトを修正して git diff でファイルリストを取得：
```bash
CHANGED_FILES=$(git diff --cached --name-only | grep '\.tf$')
```

### Q: CI/CD でも同じ検証を実行したい
A: 検証スクリプトは独立しているため、CI/CD でも利用可能：
```yaml
# .github/workflows/terraform-validation.yml
- name: Terraform Validation
  run: |
    echo '{"tool_name":"Bash","tool_input":{"command":"git commit"}}' | \
    bash .claude/scripts/terraform-pre-commit-validation.sh
```

### Q: 新しい環境を追加したら？
A: `envs/` 配下にディレクトリを追加するだけで、自動的に検証対象になります。環境固有の `.tflint.hcl` を配置することで、カスタマイズも可能です。

## ベストプラクティス

### Do ✅
- Pre-commit hook を有効にする
- 検証失敗時は問題を修正してから commit
- チーム全員が同じ hook を使用
- CI/CD でも同じスクリプトを使用
- 環境固有のルールは env-specific `.tflint.hcl` で管理

### Don't ❌
- `--no-verify` を常用しない
- 検証をスキップして後で修正しない
- Hook を無効化したまま開発しない
- 問題を放置して commit しない
- 環境ごとの検証要件を無視しない
