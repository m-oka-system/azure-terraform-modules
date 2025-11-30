# Git Pre-Commit Hooks for Terraform Validation

このディレクトリには、git commit **前**に Terraform の検証を自動実行する hooks が含まれています。

## 🎯 仕組み

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

## 📦 セットアップ

### 前提条件

```bash
# 必要なツールをインストール
brew install terraform tflint trivy

# TFLint プラグイン初期化
tflint --init
```

### Git Hooks の有効化

**方法 A: core.hooksPath を設定（推奨）**

```bash
# プロジェクトルートで実行
git config core.hooksPath .githooks
```

これで `.githooks/pre-commit` が自動的に使用されます。

**確認**:
```bash
git config --get core.hooksPath
# 出力: .githooks
```

**方法 B: セットアップスクリプトを使用**

```bash
./.githooks/setup-hooks.sh
```

これにより `.githooks/pre-commit` が `.git/hooks/` にコピーされます。

## 🧪 動作確認

テスト commit で確認：

```bash
# ダミーファイルを作成
echo "# test" > test.md

# commit を試みる
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

## 🔍 検証内容

### 環境ごとに実行される検証

各環境（`envs/dev/`, `envs/stg/`, `envs/prod/` など）で順次実行：

#### 1. Terraform Validate
- **目的**: Terraform の構文と設定を検証
- **実行**: `terraform validate`
- **チェック内容**:
  - 構文エラー
  - リソース設定の妥当性
  - Provider バージョンの互換性

#### 2. TFLint
- **目的**: ベストプラクティスと Azure 固有のルールをチェック
- **実行**: `tflint --config=<env>/.tflint.hcl`
- **チェック内容**:
  - 命名規則
  - 未使用の変数/出力
  - Azure リソースの推奨設定

#### 3. Trivy Security Scan
- **目的**: セキュリティ脆弱性とミスコンフィギュレーションを検出
- **実行**: `trivy config . --severity CRITICAL,HIGH`
- **チェック内容**:
  - セキュリティベストプラクティス
  - Azure 固有のセキュリティ問題
  - CRITICAL / HIGH レベルの問題のみ

## ⚙️ 設定

### 環境固有の TFLint 設定

各環境で異なるルールを適用できます：

```
envs/
├── dev/.tflint.hcl      # dev 環境（緩め）
├── stg/.tflint.hcl      # stg 環境
└── prod/.tflint.hcl     # prod 環境（厳格）
```

環境固有の設定がない場合は、プロジェクトルートの `.tflint.hcl` を使用します。

### Trivy の重要度フィルタ

デフォルトでは `CRITICAL,HIGH` のみをチェックします。

変更する場合はスクリプトを編集：
```bash
# .claude/scripts/terraform-pre-commit-validation.sh
trivy config . --severity CRITICAL,HIGH,MEDIUM  # MEDIUM を追加
```

## 🚫 検証をスキップする方法

緊急時や意図的にスキップする場合：

```bash
git commit -m "message" --no-verify
```

⚠️ **警告**: これは緊急時のみ使用してください。通常は検証を通過させることが強く推奨されます。

## 🔧 カスタマイズ

### 検証ツールの追加/削除

スクリプトを編集して必要な検証のみを実行：

```bash
# .claude/scripts/terraform-pre-commit-validation.sh

# trivy をスキップする場合はコメントアウト
# if command_exists trivy; then
#   ...
# fi
```

### タイムアウト設定

長時間かかる場合はタイムアウトを設定：

```bash
timeout 300 bash .claude/scripts/terraform-pre-commit-validation.sh
```

## 🐛 トラブルシューティング

### Hook が実行されない

**確認 1**: Hooks ディレクトリの設定
```bash
git config --get core.hooksPath
# 出力がない、または .githooks でない場合
git config core.hooksPath .githooks
```

**確認 2**: ファイルの実行権限
```bash
ls -l .githooks/pre-commit
# -rwxr-xr-x であることを確認

# 権限がない場合
chmod +x .githooks/pre-commit
```

**確認 3**: スクリプトの存在
```bash
ls -l .claude/scripts/terraform-pre-commit-validation.sh
```

### ツールが見つからない

```bash
# インストール確認
terraform version
tflint --version
trivy --version

# PATH 確認
echo $PATH

# 再インストール
brew install terraform tflint trivy
```

### 検証が遅い

**オプション 1**: 高速な検証のみ実行
- terraform validate と tflint のみ
- trivy は CI/CD で実行

**オプション 2**: Pre-push に移動
- Commit は高速に
- Push 前に詳細検証

## 📚 Hook の仕組み

### Pre-Commit Hook
```bash
#!/usr/bin/env bash
# .githooks/pre-commit

# 検証スクリプトを実行
bash .claude/scripts/terraform-pre-commit-validation.sh

# exit code によって commit の可否を決定
# 0: commit 許可
# 2: commit ブロック（検証失敗）
```

### 検証スクリプト
```bash
# .claude/scripts/terraform-pre-commit-validation.sh

# 各環境で検証
for env in dev stg prod; do
  cd envs/$env/
  terraform validate
  tflint
  trivy config .
  cd ../..
done

# すべて成功 → exit 0
# 1つでも失敗 → exit 2
```

## 🔄 無効化と再有効化

### 一時的に無効化
```bash
git config --unset core.hooksPath
```

### 再度有効化
```bash
git config core.hooksPath .githooks
```

### 完全に削除
```bash
# 設定削除
git config --unset core.hooksPath

# ファイル削除（バックアップ）
mv .githooks .githooks.backup
```

## 🤝 チーム開発

### 新メンバーのセットアップ

プロジェクトの README に追加推奨：

```markdown
## 開発環境セットアップ

### 1. ツールのインストール
\`\`\`bash
brew install terraform tflint trivy
tflint --init
\`\`\`

### 2. Git Hooks の有効化
\`\`\`bash
git config core.hooksPath .githooks
\`\`\`

これで commit 前に自動検証が実行されます。
```

### CI/CD との整合性

Pre-commit hook と CI/CD で同じスクリプトを使用：

```yaml
# .github/workflows/terraform.yml
- name: Terraform Validation
  run: |
    echo '{"tool_name":"Bash","tool_input":{"command":"git commit"}}' | \
    bash .claude/scripts/terraform-pre-commit-validation.sh
```

## ✅ ベストプラクティス

### Do ✅
- Pre-commit hook を有効にする
- 検証失敗時は問題を修正してから commit
- チーム全員が同じ hook を使用
- CI/CD でも同じスクリプトを使用

### Don't ❌
- `--no-verify` を常用しない
- 検証をスキップして後で修正しない
- Hook を無効化したまま開発しない
- 問題を放置して commit しない

## 📖 関連ドキュメント

- [Claude Code Hooks](.claude/docs/hooks-setup.md)
- [Validation Script](.claude/scripts/terraform-pre-commit-validation.sh)
- [Setup Complete Guide](.claude/docs/validation-setup-complete.md)
