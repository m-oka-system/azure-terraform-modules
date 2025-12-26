# Azure Terraform Coding Skills

このディレクトリには、プロジェクト固有のClaude Codeスキルが含まれています。

## 📦 含まれるスキル

### terraform-code

HashiCorp公式スタイルガイドに準拠したAzure Terraformコード実装スキル。

**機能:**
- Azure MCP + Terraform MCPの並列研究エージェント
- azurerm/azapi両対応
- 自動検証（fmt/validate/style check）
- Azure Well-Architected Framework準拠

**自動トリガー:**
```
"Azure Front DoorをTerraformで作成して"
"VNetとサブネットを実装して"
"App Serviceのterraformコードを書いて"
```

**詳細:** [terraform-code/SKILL.md](terraform-code/SKILL.md)

## 🔧 使用方法

### Claude Codeでの自動認識

Claude Codeがこのリポジトリで起動すると、`.claude/skills/`内のスキルを自動的に読み込みます。

### スキルの確認

```
Claude Code: "利用可能なスキルを表示して"
```

## 🛠️ スキルの更新

### 1. ソースファイルを直接編集

```bash
# スキルのドキュメントを更新
vi .claude/skills/terraform-code/SKILL.md

# スクリプトを更新
vi .claude/skills/terraform-code/scripts/check_style.py

# テンプレートを更新
vi .claude/skills/terraform-code/assets/templates/main.tf
```

### 2. 変更をコミット

```bash
git add .claude/skills/terraform-code/
git commit -m "Update terraform-code skill: ..."
git push
```

### 3. チームメンバーがプル

```bash
git pull
# Claude Codeが自動的に更新されたスキルを読み込む
```

## 📝 新しいスキルの追加

```bash
# スキルディレクトリを作成
mkdir -p .claude/skills/new-skill

# SKILL.mdを作成（必須）
cat > .claude/skills/new-skill/SKILL.md << 'EOF'
---
name: new-skill
description: スキルの説明とトリガー条件
---

# New Skill

スキルの内容...
EOF

# コミット
git add .claude/skills/new-skill/
git commit -m "Add new-skill"
```

## 🔍 スキル構造

```
.claude/skills/terraform-code/
├── SKILL.md              # メインドキュメント（必須）
├── scripts/              # 実行可能スクリプト
│   ├── check_style.py
│   └── validate_terraform.sh
├── references/           # 参照ドキュメント（必要に応じて読み込み）
│   ├── research_workflow.md
│   ├── azure_patterns.md
│   ├── terraform_mcp_usage.md
│   └── style_guide.md
└── assets/               # テンプレートやリソースファイル
    └── templates/
        ├── terraform.tf
        ├── providers.tf
        ├── variables.tf
        ├── locals.tf
        ├── main.tf
        └── outputs.tf
```

## ⚠️ 注意事項

- **`.skill`ファイルはgitignore済み**: ビルド済み`.skill`ファイルはリポジトリに含めません
- **ソース管理のみ**: `.claude/skills/`内のソースファイルのみをバージョン管理
- **自動読み込み**: Claude Codeは`.claude/skills/`内のスキルを自動検出・読み込み

## 📖 詳細情報

- [terraform-code スキルドキュメント](terraform-code/SKILL.md)
- [研究ワークフロー](terraform-code/references/research_workflow.md)
- [Azureパターン集](terraform-code/references/azure_patterns.md)
