# Terraform Validation Setup - 完了ガイド

## ✅ セットアップ完了

以下の2つの検証システムが有効になっています：

### 1. Claude Code Hook 🤖
- **設定ファイル**: `.claude/settings.json`
- **動作**: Claude Code が `git commit` を実行した時
- **状態**: ✅ 有効

### 2. Git Native Hook 👤
- **設定ファイル**: `.githooks/post-commit`
- **動作**: ユーザーが手動で `git commit` を実行した時
- **状態**: ✅ 有効（`git config core.hooksPath .githooks`）

## 📊 検証パイプライン

誰が commit しても、以下が自動実行されます：

```
git commit
    ↓
┌─────────────────────────────────────┐
│  Post-Commit Validation Pipeline    │
├─────────────────────────────────────┤
│  1. terraform validate              │
│     └─ 構文チェック                 │
│                                     │
│  2. tflint                          │
│     └─ ベストプラクティス検証       │
│                                     │
│  3. trivy config                    │
│     └─ セキュリティスキャン         │
└─────────────────────────────────────┘
    ↓
  結果表示
```

## 🧪 動作確認

### テスト 1: Claude Code による commit
Claude Code に以下を依頼:
```
git commit でテストファイルをコミットして
```

### テスト 2: 手動 commit
ターミナルで実行:
```bash
# テストファイルを作成
echo "# test" > test.md

# commit（検証が自動実行される）
git add test.md
git commit -m "test: verify manual commit hook"
```

期待される出力:
```
🔍 Post-commit validation triggered

═══════════════════════════════════════════════════════
  Terraform Validation Pipeline
═══════════════════════════════════════════════════════

[1/3] Running terraform validate...
✓ Terraform validate passed

[2/3] Running tflint...
✓ tflint passed (no issues)

[3/3] Running trivy config scan...
✓ trivy scan passed (no misconfigurations)

═══════════════════════════════════════════════════════
✅ All validations passed successfully
```

## 📁 ファイル構成

```
azure-terraform-modules/
├── .claude/
│   ├── settings.json                    # Claude Code hook 設定
│   ├── settings.example.json            # カスタマイズ例
│   ├── scripts/
│   │   ├── terraform-post-commit-validation.sh  # メイン検証スクリプト
│   │   └── test-validation-hook.sh              # テストスクリプト
│   └── docs/
│       ├── hooks-setup.md               # Claude Code hooks 詳細
│       └── validation-setup-complete.md # このファイル
│
├── .githooks/
│   ├── post-commit                      # Git native hook
│   ├── setup-hooks.sh                   # セットアップスクリプト
│   └── README.md                        # Git hooks 詳細
│
├── .git/
│   └── config                           # core.hooksPath = .githooks
│
├── .tflint.hcl                          # TFLint 設定
└── .gitignore                           # 更新済み（キャッシュ除外）
```

## 🎯 検証スキップ方法

必要に応じて検証をスキップできます：

```bash
# 検証をスキップして commit
git commit -m "message" --no-verify

# または環境変数でスキップ
SKIP_VALIDATION=1 git commit -m "message"
```

## 🔧 管理コマンド

### Hook の確認
```bash
# 現在の hooks ディレクトリを確認
git config --get core.hooksPath

# Hook ファイルの確認
ls -lh .githooks/
```

### Hook の再インストール
```bash
# 設定を再適用
git config core.hooksPath .githooks

# または setup スクリプトを実行
./.githooks/setup-hooks.sh
```

### Hook の無効化
```bash
# 一時的に無効化
git config --unset core.hooksPath

# 再度有効化
git config core.hooksPath .githooks
```

### Hook の削除
```bash
# Git 設定をクリア
git config --unset core.hooksPath

# Hook ファイルを削除（バックアップ）
mv .githooks .githooks.backup
```

## 🤝 チーム共有

### 新しいチームメンバーのセットアップ

プロジェクトの README に以下を追加:

````markdown
## 開発環境セットアップ

### 1. 依存関係のインストール

```bash
# macOS
brew install terraform tflint trivy

# Linux
# Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/

# TFLint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

### 2. TFLint 初期化

```bash
tflint --init
```

### 3. Git Hooks セットアップ

```bash
git config core.hooksPath .githooks
```

これで commit 時に自動検証が実行されます。
````

## 📊 現在の検証ルール

### Terraform Validate
- 構文エラー
- リソース設定の妥当性
- Provider バージョンの互換性

### TFLint (`.tflint.hcl`)
- Azure ベストプラクティス
- 命名規則（snake_case）
- 必須タグ: `Environment`, `ManagedBy`
- 未使用の変数/出力
- ドキュメント完全性

### Trivy Security Scan
- セキュリティ脆弱性
- ミスコンフィギュレーション
- Azure 固有のセキュリティルール
- 現在検出されている問題:
  - Key Vault: purge protection 無効（MEDIUM）
  - Secrets: content-type 未指定（LOW）
  - Secrets: expiry date 未設定（LOW）

## 🚀 次のステップ

### オプション: 検出された問題の修正

検証で見つかった推奨事項に対応する場合:

**1. Key Vault の purge protection を有効化**
```hcl
# modules/key_vault/key_vault.tf
resource "azurerm_key_vault" "this" {
  # ...
  purge_protection_enabled = true  # デフォルトを true に変更
}
```

**2. Secret に metadata を追加**
```hcl
# modules/key_vault_secret/key_vault_secret.tf
resource "azurerm_key_vault_secret" "this" {
  # ...
  content_type    = "text/plain"  # または "application/json" 等
  expiration_date = "2025-12-31T23:59:59Z"  # 適切な期限を設定
}
```

### CI/CD 統合

GitHub Actions や Azure Pipelines でも同じスクリプトを使用:

```yaml
# .github/workflows/terraform-validation.yml
- name: Terraform Validation
  run: |
    echo '{"tool_name":"Bash","tool_input":{"command":"git commit"}}' | \
    bash .claude/scripts/terraform-post-commit-validation.sh
```

## 💡 ヒント

### パフォーマンス最適化
```bash
# Trivy キャッシュを有効化（2回目以降が高速化）
export TRIVY_CACHE_DIR=~/.cache/trivy

# TFLint プラグインキャッシュ
export TFLINT_PLUGIN_DIR=~/.tflint.d/plugins
```

### 詳細ログ
```bash
# 検証スクリプトを直接実行（デバッグ用）
echo '{"tool_name":"Bash","tool_input":{"command":"git commit"}}' | \
bash -x .claude/scripts/terraform-post-commit-validation.sh
```

## 📚 関連ドキュメント

- [Claude Code Hooks 詳細](.claude/docs/hooks-setup.md)
- [Git Hooks 詳細](../.githooks/README.md)
- [TFLint Configuration](../../.tflint.hcl)
- [Validation Script](../scripts/terraform-post-commit-validation.sh)

## ❓ FAQ

**Q: 検証が遅い場合は？**
A: キャッシュを有効化し、変更されたファイルのみを検証するようスクリプトを改良できます。

**Q: Pre-commit にしたい場合は？**
A: `.githooks/pre-commit` として同じスクリプトをコピーしてください。

**Q: 特定の検証だけスキップしたい場合は？**
A: 環境変数で制御できるよう、スクリプトを拡張できます:
```bash
SKIP_TFLINT=1 git commit -m "message"
```

**Q: Windows で動作しますか？**
A: Git Bash または WSL 内であれば動作します。PowerShell 版も作成可能です。

---

**セットアップ完了！🎉**

これで、誰が commit しても Terraform の品質とセキュリティが自動的に検証されます。
