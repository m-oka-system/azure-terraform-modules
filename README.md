# Azure Terraform Modules

Azure インフラストラクチャを管理するための再利用可能な Terraform モジュールライブラリです。セキュリティ、可用性、スケーラビリティを重視した設計で、多様な Azure サービスに対応したモジュールを提供しています。

## 技術スタック

| ツール               | バージョン | 用途                       |
| -------------------- | ---------- | -------------------------- |
| Terraform            | ~> 1.13.0  | IaC                        |
| TFLint               | >= 0.59.1  | Linter                     |
| Trivy                | 0.67.2     | セキュリティスキャン       |
| terraform-compliance | latest     | BDD コンプライアンステスト |

## ディレクトリ構成

```
azure-terraform-modules/
├── .github/
│   └── workflows/              # CI/CD
├── .githooks/                  # Pre-commit フック
├── docs/                       # ドキュメント
│   └── TF_STYLE_GUIDE.md
├── envs/                       # 環境別設定
│   └── dev/
│       ├── backend.tf
│       ├── locals.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── terraform.tf
│       ├── terraform.tfvars
│       ├── tests/              # Terraform テスト
│       └── variables.tf
├── modules/                    # 再利用可能なモジュール
│   ├── app_service/
│   ├── key_vault/
│   ├── vnet/
│   └── ...                     # その他多数のモジュール
└── tests/
    └── compliance/             # terraform-compliance (BDD)
        ├── Makefile
        └── features/
            ├── data-protection/
            ├── network/
            ├── security/
            └── tagging/
```

各モジュールは以下の 3 ファイル構成に従います:

```
modules/<module_name>/
├── variables.tf          # 入力変数
├── <module_name>.tf      # リソース定義
└── outputs.tf            # 出力値
```

## CI/CD (GitHub Actions)

`main` ブランチへの push / pull request 時に自動実行されます。

```
terraform-validate ─┐
tflint ─────────────┼──→ terraform-compliance
trivy ──────────────┘
```

| ジョブ               | 内容                                   |
| -------------------- | -------------------------------------- |
| terraform-validate   | `terraform fmt -check` / `validate`    |
| tflint               | azurerm ルールセットによる Linting     |
| trivy                | CRITICAL / HIGH のセキュリティスキャン |
| terraform-compliance | BDD コンプライアンステスト             |

## Git Pre-commit Hooks

コミット時に自動でバリデーションを実行します。

```bash
# フックを有効化
git config core.hooksPath .githooks
```

## セットアップ

### 前提条件

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.13.0
- [TFLint](https://github.com/terraform-linters/tflint) >= 0.59.1
- [Trivy](https://github.com/aquasecurity/trivy) >= 0.67.0
- Azure CLI（認証済み）

### 初期セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/m-oka-system/azure-terraform-modules.git
cd azure-terraform-modules

# Pre-commit フックを有効化
git config core.hooksPath .githooks

# dev 環境の初期化
cd envs/dev
terraform init
tflint --init
```

### 基本操作

```bash
cd envs/dev

# フォーマット・バリデーション
terraform fmt -recursive
terraform validate
tflint

# セキュリティスキャン
trivy config . --severity HIGH,CRITICAL

# プラン・適用
terraform plan
terraform apply
```

### テスト

```bash
# Terraform ネイティブテスト
cd envs/dev
terraform test

# コンプライアンステスト
cd tests/compliance
make plan dev       # プラン生成
make test dev       # 全テスト実行
make test-security dev   # セキュリティのみ
```
