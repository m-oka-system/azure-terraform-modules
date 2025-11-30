# Git Hooks for Terraform Validation

このディレクトリには、手動 git commit 時に Terraform 検証を実行する Git hooks が含まれています。

## 🎯 2つの検証方法

### 1. Claude Code による commit
- **自動有効**: `.claude/settings.json` で設定済み
- **対象**: Claude Code が実行する `git commit`

### 2. ユーザーによる手動 commit
- **要セットアップ**: このディレクトリの hooks をインストール
- **対象**: ターミナルや IDE から実行する `git commit`

## 📦 インストール方法

### 方法 A: Git hooks ディレクトリを変更（推奨）

**Git 2.9+ で利用可能な最も簡単な方法**

```bash
# プロジェクトルートで実行
git config core.hooksPath .githooks
```

これにより、`.githooks/` が hooks ディレクトリとして使われます。

**確認**:
```bash
git config --get core.hooksPath
# 出力: .githooks
```

**利点**:
- ✅ 1コマンドで完了
- ✅ 自動更新（git pull で最新版を取得）
- ✅ チーム全体で統一

**欠点**:
- ⚠️ リポジトリごとに設定が必要
- ⚠️ 既存の `.git/hooks/` は無視される

---

### 方法 B: セットアップスクリプトを実行

```bash
# プロジェクトルートで実行
./.githooks/setup-hooks.sh
```

これにより、`.githooks/` から `.git/hooks/` にコピーされます。

**利点**:
- ✅ 従来の Git hooks の動作
- ✅ 他の hooks との併用が可能

**欠点**:
- ⚠️ 更新時に再実行が必要
- ⚠️ チームメンバーごとに実行が必要

---

### 方法 C: 手動コピー

```bash
cp .githooks/post-commit .git/hooks/post-commit
chmod +x .git/hooks/post-commit
```

## 🧪 動作テスト

```bash
# テスト commit を作成
git add .
git commit -m "test: verify hooks"
```

成功すれば以下が表示されます：
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

## 🔧 含まれる Hooks

### post-commit
**実行タイミング**: `git commit` が完了した直後

**処理内容**:
1. Terraform validate
2. TFLint
3. Trivy security scan

**使用スクリプト**: `.claude/scripts/terraform-post-commit-validation.sh`

## ⚙️ カスタマイズ

### 検証をスキップ

一時的にスキップする場合:
```bash
git commit -m "message" --no-verify
```

### Hook を無効化

```bash
# 方法 A を使った場合
git config --unset core.hooksPath

# 方法 B/C を使った場合
rm .git/hooks/post-commit
```

### Pre-commit に変更

より厳格に、commit **前**に検証したい場合:

```bash
# .githooks/pre-commit を作成
cp .githooks/post-commit .githooks/pre-commit

# インストール
git config core.hooksPath .githooks
# または
cp .githooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

## 🤝 チーム開発

### 推奨セットアップ（プロジェクト README に追加）

```markdown
## 開発環境セットアップ

# 依存関係のインストール
brew install terraform tflint trivy

# TFLint 初期化
tflint --init

# Git hooks セットアップ
git config core.hooksPath .githooks
```

### CI/CD との統合

同じ検証スクリプトを CI/CD でも使用できます:

```yaml
# .github/workflows/terraform-validation.yml
name: Terraform Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2

      - name: Setup TFLint
        uses: terraform-linters/setup-tflint@v3

      - name: Setup Trivy
        run: |
          wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
          echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
          sudo apt-get update && sudo apt-get install trivy

      - name: Run Validation
        run: bash .claude/scripts/terraform-post-commit-validation.sh
        env:
          CLAUDE_PROJECT_DIR: ${{ github.workspace }}
```

## 🛠️ トラブルシューティング

### Hooks が実行されない

**確認 1**: hooks ディレクトリの設定
```bash
git config --get core.hooksPath
```

**確認 2**: ファイルの実行権限
```bash
ls -l .githooks/post-commit
ls -l .git/hooks/post-commit
```

**確認 3**: スクリプトの存在
```bash
ls -l .claude/scripts/terraform-post-commit-validation.sh
```

### Permission denied エラー

```bash
chmod +x .githooks/post-commit
chmod +x .git/hooks/post-commit
chmod +x .claude/scripts/terraform-post-commit-validation.sh
```

### 改行コード問題（Windows）

```bash
# Unix 形式に変換
dos2unix .githooks/post-commit
# または
sed -i 's/\r$//' .githooks/post-commit
```

## 📚 関連ドキュメント

- [Claude Code Hooks](.claude/docs/hooks-setup.md)
- [Validation Script](.claude/scripts/terraform-post-commit-validation.sh)
- [Git Hooks Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
