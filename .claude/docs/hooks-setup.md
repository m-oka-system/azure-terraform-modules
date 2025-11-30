# Claude Code Hooks - Terraform Validation Setup

## 概要

このプロジェクトでは、Claude Code の hook 機能を使って、git commit 後に自動的に Terraform の検証を実行します。

## 構成ファイル

```
.claude/
├── settings.json                                # Hook 設定
├── scripts/
│   ├── terraform-post-commit-validation.sh     # メイン検証スクリプト
│   └── test-validation-hook.sh                 # テストスクリプト
└── docs/
    └── hooks-setup.md                          # このドキュメント
```

## 検証パイプライン

commit 後、以下が順次実行されます：

### 1. Terraform Validate ✅
- **目的**: Terraform 構文とリソース設定の検証
- **コマンド**: `terraform validate`
- **初期化**: 必要に応じて `terraform init -backend=false` を実行

### 2. TFLint ✅
- **目的**: ベストプラクティスと Azure 固有のルールチェック
- **コマンド**: `tflint --format compact`
- **設定**: `.tflint.hcl` で定義
- **初期化**: 必要に応じて `tflint --init` を実行

### 3. Trivy Config Scan ✅
- **目的**: セキュリティ脆弱性とミスコンフィギュレーション検出
- **コマンド**: `trivy config .`
- **出力**: JSON → テーブル形式でレポート

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
Claude Code が `git commit` を実行すると、自動的に検証が開始されます。

### 手動テスト

```bash
# Hook をテスト
./.claude/scripts/test-validation-hook.sh

# 個別のツールをテスト
terraform validate
tflint
trivy config .
```

### 検証スキップ

緊急時や意図的にスキップする場合：

```bash
git commit -m "message" --no-verify
```

## エラー処理

### Exit Code
- **0**: すべての検証が成功
- **2**: ブロッキングエラー（Claude にフィードバック）
- **その他**: 非ブロッキングエラー

### エラー発生時の動作
1. エラーメッセージを stderr に出力
2. Claude に詳細をフィードバック
3. 修正を促すメッセージを表示

## カスタマイズ

### 検証ルールの調整

#### TFLint (.tflint.hcl)
```hcl
rule "azurerm_resource_missing_tags" {
  enabled = true
  tags = [
    "Environment",
    "ManagedBy",
    "Project"  # 追加
  ]
}
```

#### Trivy (環境変数)
```bash
# 重要度フィルタ
export TRIVY_SEVERITY=HIGH,CRITICAL

# 特定のチェックをスキップ
export TRIVY_SKIP_CHECK=AVD-AZU-0015,AVD-AZU-0017
```

### Hook の無効化

`.claude/settings.json` から該当の hook を削除：

```json
{
  "hooks": {
    "PostToolUse": []
  }
}
```

### 追加の Hook 例

#### Pre-commit (より厳格)
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "command": "if [[ \"$CLAUDE_TOOL_INPUT\" == *\"git commit\"* ]]; then bash .claude/scripts/terraform-post-commit-validation.sh; fi"
      }
    ]
  }
}
```

#### Auto-format on Edit
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "if [[ \"$CLAUDE_TOOL_INPUT\" == *.tf ]]; then terraform fmt \"$CLAUDE_PROJECT_DIR\"; fi"
      }
    ]
  }
}
```

## トラブルシューティング

### Hook が実行されない
1. `.claude/settings.json` が存在するか確認
2. スクリプトに実行権限があるか確認: `chmod +x .claude/scripts/*.sh`
3. hook のマッチャーが正しいか確認

### ツールが見つからない
```bash
# PATH を確認
echo $PATH

# ツールのバージョン確認
terraform version
tflint --version
trivy --version
```

### 改行コードエラー
```bash
# Unix 形式に変換
sed -i '' 's/\r$//' .claude/scripts/*.sh
```

### タイムアウト
デフォルトは 60 秒。変更する場合：

```bash
timeout 300 bash .claude/scripts/terraform-post-commit-validation.sh
```

## 参考リンク

- [Claude Code Hooks Documentation](https://code.claude.com/docs/en/hooks.md)
- [TFLint Documentation](https://github.com/terraform-linters/tflint)
- [Trivy Documentation](https://trivy.dev/)
- [Terraform Documentation](https://www.terraform.io/docs)

## よくある質問

### Q: 検証が遅い場合は？
A: 以下を試してください：
- `.terraform` キャッシュの再利用
- Trivy のキャッシュ有効化: `export TRIVY_CACHE_DIR=~/.cache/trivy`
- 並列実行の検討（ただし hook は順次実行推奨）

### Q: 特定のファイルだけ検証したい
A: スクリプトを修正して git diff でファイルリストを取得：
```bash
CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD | grep '\.tf$')
```

### Q: CI/CD でも同じ検証を実行したい
A: 検証スクリプトは独立しているため、CI/CD でも利用可能：
```yaml
# GitHub Actions example
- name: Terraform Validation
  run: bash .claude/scripts/terraform-post-commit-validation.sh
```
