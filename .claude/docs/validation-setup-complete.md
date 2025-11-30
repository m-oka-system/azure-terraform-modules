# Terraform Validation Setup - 完了ガイド

## ✅ セットアップ完了

以下の2つの検証システムが有効になっています：

### 1. Claude Code Hook 🤖
- **設定ファイル**: `.claude/settings.json`
- **フック種別**: PreToolUse（コミット前）
- **動作**: Claude Code が `git commit` を実行する前に検証
- **状態**: ✅ 有効

### 2. Git Native Hook 👤
- **設定ファイル**: `.githooks/pre-commit`
- **動作**: ユーザーが手動で `git commit` を実行する前に検証
- **状態**: ✅ 有効（`git config core.hooksPath .githooks`）

## 📊 検証パイプライン

誰が commit しても、以下が**コミット前**に自動実行されます：

```
git commit を実行
    ↓
┌─────────────────────────────────────┐
│  Pre-Commit Validation Pipeline     │
├─────────────────────────────────────┤
│  各環境ごとに順次検証:               │
│                                     │
│  1. terraform validate              │
│     └─ 構文・設定チェック           │
│                                     │
│  2. tflint                          │
│     └─ ベストプラクティス検証       │
│                                     │
│  3. trivy config (CRITICAL,HIGH)    │
│     └─ セキュリティスキャン         │
└─────────────────────────────────────┘
    ↓
  ✅ 成功 → コミット作成
  ❌ 失敗 → コミット中止（修正が必要）
```

## 🔍 検証の仕組み

### 環境ごとの検証
`envs/` 配下の各環境ディレクトリで個別に検証を実行：

```
envs/
├── dev/     → terraform validate, tflint, trivy
├── stg/     → terraform validate, tflint, trivy
└── prod/    → terraform validate, tflint, trivy
```

**重要**: 各環境の root module ディレクトリで実行することで、モジュール解決と変数評価が正確に行われます。

### ブロッキング動作
検証が失敗すると、コミットは作成されません：

```bash
$ git commit -m "Add storage account"

🔍 Pre-commit validation triggered
...
❌ Validation failed - review issues above

💡 Tip: Fix the issues and commit again, or use --no-verify to skip validation

# コミットは作成されていません
$ git log -1
# （前回のコミットが表示される）
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
git commit -m "test: verify pre-commit hook"
```

期待される出力:
```
🔍 Pre-commit validation triggered

═══════════════════════════════════════════════════════
  Terraform Validation Pipeline
  Environments: dev
═══════════════════════════════════════════════════════

━━━ Environment: dev ━━━

  [1/3] Running terraform validate in dev...
  ✓ Terraform validate passed (dev)

  [2/3] Running tflint in dev...
  ✓ tflint passed (dev)

  [3/3] Running trivy config scan in dev (CRITICAL,HIGH only)...
  ✓ trivy scan passed (dev)

═══════════════════════════════════════════════════════
✅ All validations passed successfully

[main abc1234] test: verify pre-commit hook
 1 file changed, 1 insertion(+)
```

### テスト 3: 意図的な検証失敗
```bash
# 不正な Terraform ファイルを作成
cat > envs/dev/test.tf <<EOF
resource "azurerm_storage_account" "test" {
  # location が必須だが省略
  name = "test"
}
EOF

git add envs/dev/test.tf
git commit -m "test: trigger validation failure"

# 期待される動作: コミットがブロックされる
```

## 📁 ファイル構成

```
azure-terraform-modules/
├── .claude/
│   ├── settings.json                         # Claude Code hook 設定（PreToolUse）
│   ├── settings.example.json                 # カスタマイズ例
│   ├── scripts/
│   │   ├── terraform-pre-commit-validation.sh   # メイン検証スクリプト
│   │   └── test-validation-hook.sh              # テストスクリプト
│   └── docs/
│       ├── hooks-setup.md                    # Claude Code hooks 詳細
│       └── validation-setup-complete.md      # このファイル
│
├── .githooks/
│   ├── pre-commit                            # Git native pre-commit hook
│   ├── setup-hooks.sh                        # セットアップスクリプト
│   └── README.md                             # Git hooks 詳細
│
├── .git/
│   └── config                                # core.hooksPath = .githooks
│
├── envs/
│   ├── dev/
│   │   ├── .tflint.hcl                       # dev 固有の TFLint 設定（任意）
│   │   └── *.tf
│   ├── stg/
│   │   └── *.tf
│   └── prod/
│       └── *.tf
│
├── .tflint.hcl                               # プロジェクト共通 TFLint 設定
└── .gitignore                                # 更新済み（キャッシュ除外）
```

## 🎯 検証スキップ方法

### 方法 1: --no-verify フラグ
```bash
# 緊急時のみ使用
git commit -m "emergency fix" --no-verify
```

### 方法 2: Hook の一時的な無効化
```bash
# 無効化
git config --unset core.hooksPath

# コミット
git commit -m "without validation"

# 再度有効化
git config core.hooksPath .githooks
```

⚠️ **警告**: 検証をスキップすると、問題のあるコードが commit 履歴に含まれる可能性があります。緊急時のみ使用してください。

## 🔧 管理コマンド

### Hook の確認
```bash
# 現在の hooks ディレクトリを確認
git config --get core.hooksPath
# 出力: .githooks

# Hook ファイルの確認
ls -lh .githooks/
# 出力: -rwxr-xr-x ... pre-commit

# Claude Code hook の確認
cat .claude/settings.json | jq '.hooks'
```

### Hook の再インストール
```bash
# Git hook 設定を再適用
git config core.hooksPath .githooks

# または setup スクリプトを実行
./.githooks/setup-hooks.sh
```

### Hook のテスト
```bash
# スクリプトを直接実行
./.claude/scripts/test-validation-hook.sh

# または手動で模擬入力を渡す
echo '{"tool_name":"Bash","tool_input":{"command":"git commit"}}' | \
  bash .claude/scripts/terraform-pre-commit-validation.sh
```

### Hook の無効化
```bash
# 一時的に無効化
git config --unset core.hooksPath

# 再度有効化
git config core.hooksPath .githooks
```

### Hook の完全削除
```bash
# Git 設定をクリア
git config --unset core.hooksPath

# Hook ファイルをバックアップ
mv .githooks .githooks.backup

# Claude Code の設定から削除
# .claude/settings.json の hooks.PreToolUse から該当エントリを削除
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

これで commit 前に自動検証が実行されます。
````

## 📊 現在の検証ルール

### Terraform Validate
すべての環境で実行:
- 構文エラー
- リソース設定の妥当性
- Provider バージョンの互換性

### TFLint
環境固有の設定を使用（存在する場合）:
- Azure ベストプラクティス
- 命名規則（snake_case）
- 必須タグ: `Environment`, `ManagedBy`
- 未使用の変数/出力
- ドキュメント完全性

**環境固有のカスタマイズ例**:
```hcl
# envs/dev/.tflint.hcl（緩め）
rule "azurerm_resource_missing_tags" {
  enabled = false
}

# envs/prod/.tflint.hcl（厳格）
rule "azurerm_resource_missing_tags" {
  enabled = true
  tags = ["Environment", "ManagedBy", "Project", "CostCenter", "Owner"]
}
```

### Trivy Security Scan
すべての環境で CRITICAL と HIGH のみ:
- セキュリティ脆弱性
- ミスコンフィギュレーション
- Azure 固有のセキュリティルール

## 🚀 次のステップ

### 新しい環境の追加

`envs/` 配下にディレクトリを作成するだけで、自動的に検証対象になります：

```bash
# QA 環境を追加
mkdir -p envs/qa
cp -r envs/dev/*.tf envs/qa/

# 次回のコミットから自動的に検証される
git add envs/qa/
git commit -m "feat: add QA environment"
# → dev, stg, prod, qa すべてが検証されます
```

### CI/CD 統合

GitHub Actions や Azure Pipelines でも同じスクリプトを使用:

```yaml
# .github/workflows/terraform-validation.yml
name: Terraform Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Setup TFLint
        uses: terraform-linters/setup-tflint@v4

      - name: Setup Trivy
        run: |
          curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
          sh -s -- -b /usr/local/bin

      - name: Terraform Validation
        run: |
          echo '{"tool_name":"Bash","tool_input":{"command":"git commit"}}' | \
          bash .claude/scripts/terraform-pre-commit-validation.sh
```

### カスタマイズ例

#### 追加の検証ツールを導入
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
        "matcher": "Bash",
        "command": "bash .claude/scripts/check-secrets.sh",
        "description": "Check for leaked secrets before git commits"
      }
    ]
  }
}
```

#### 環境変数でスキップ制御
```bash
# スクリプトに追加
if [[ "${SKIP_VALIDATION:-}" == "1" ]]; then
  echo "⚠️ Validation skipped by SKIP_VALIDATION=1"
  exit 0
fi

# 使用例
SKIP_VALIDATION=1 git commit -m "skip validation"
```

## 💡 ヒント

### パフォーマンス最適化
```bash
# Trivy キャッシュを有効化（2回目以降が高速化）
export TRIVY_CACHE_DIR=~/.cache/trivy

# TFLint プラグインキャッシュ
export TFLINT_PLUGIN_DIR=~/.tflint.d/plugins

# ~/.bashrc or ~/.zshrc に追加
echo 'export TRIVY_CACHE_DIR=~/.cache/trivy' >> ~/.zshrc
echo 'export TFLINT_PLUGIN_DIR=~/.tflint.d/plugins' >> ~/.zshrc
```

### 詳細ログ（デバッグ用）
```bash
# 検証スクリプトを直接実行（詳細モード）
echo '{"tool_name":"Bash","tool_input":{"command":"git commit"}}' | \
bash -x .claude/scripts/terraform-pre-commit-validation.sh 2>&1 | tee validation.log
```

### 変更されたファイルのみ検証
スクリプトをカスタマイズして効率化:
```bash
# .claude/scripts/terraform-pre-commit-validation.sh に追加
CHANGED_TF_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.tf$' || true)

if [[ -z "$CHANGED_TF_FILES" ]]; then
  echo "✓ No Terraform files changed, skipping validation"
  exit 0
fi
```

## 📚 関連ドキュメント

- [Claude Code Hooks 詳細](hooks-setup.md)
- [Git Hooks 詳細](../../.githooks/README.md)
- [TFLint Configuration](../../.tflint.hcl)
- [Validation Script](../scripts/terraform-pre-commit-validation.sh)

## ❓ FAQ

**Q: 検証が遅い場合は？**
A: キャッシュを有効化し、変更されたファイルのみを検証するようスクリプトを改良できます。また、trivy を CI/CD に移動して pre-commit では terraform validate と tflint のみ実行する選択肢もあります。

**Q: 特定の検証だけスキップしたい場合は？**
A: 環境変数で制御できるよう、スクリプトを拡張できます:
```bash
SKIP_TFLINT=1 git commit -m "message"
SKIP_TRIVY=1 git commit -m "message"
```

**Q: Windows で動作しますか？**
A: Git Bash または WSL 内であれば動作します。PowerShell 版も作成可能です。

**Q: コミット履歴に検証結果は残りますか？**
A: いいえ、pre-commit hook なので検証失敗時はコミット自体が作成されません。履歴は常にクリーンに保たれます。

**Q: チーム全員が hook を有効にしているか確認する方法は？**
A: CI/CD でも同じスクリプトを実行することで、hook を回避したコミットも検証できます。

**Q: 新しい環境を追加したときの挙動は？**
A: `envs/` 配下に新しいディレクトリを作成すると、次回のコミットから自動的に検証対象になります。環境固有の `.tflint.hcl` を配置することで、カスタマイズも可能です。

---

**セットアップ完了！🎉**

これで、誰が commit しても、**コミット前**に Terraform の品質とセキュリティが自動的に検証されます。問題のあるコードは commit 履歴に含まれず、常にクリーンな状態が保たれます。
